# Auditoría de seguridad y fiabilidad de la encuesta

Fecha: 20 de octubre de 2026. Objetivo: integridad de votos, fraude y comportamiento ante aproximadamente 10.000 votos.

**Dictamen: la deduplicación funciona en las pruebas, pero todavía no daría por preparada la encuesta para una campaña con picos fuertes.** Hay rutas antiguas que evitan las protecciones del ranking, una dependencia importante de la latencia de PostgreSQL y una identidad que el servidor no vincula criptográficamente al dispositivo atestado.

## Alcance y evidencia

- Backend de encuesta: `guachinches-modernos-v3-encuesta`, commit `8ac957b`, rama `feat/encuesta-antivoto`.
- Comparación con `guachinches-modernos-v3-release`, commit `7567843`: los módulos de encuesta, integridad, restricciones y límites revisados coinciden. Release añade, entre otras cosas, gzip y keep-alive de 65 s. Las pruebas levantan solamente los controladores de encuesta; no arrancan el resto de la API ni sus tareas.
- Flutter: commit `94e0495`, rama `feature/rediseno-ios27`, con cambios locales de Pods ya presentes al empezar.
- Lecturas públicas de producción: el contrato v3 está disponible. La edición vigente es la **3**, abierta hasta `2027-03-20T23:59:59Z`, `integrityPolicy=attested`, `voteScope=business`, versión mínima 4.6.0. Su esquema devuelve `rate_limits=null` y `results_visibility=live`. No se verificó el SHA exacto desplegado ni las variables privadas del servidor.
- Todas las escrituras, ataques y cargas se hicieron contra PostgreSQL nuevo en `127.0.0.1:55449/gm_survey_audit` y API local. **Cero votos de prueba en producción.**
- App Check se sustituyó por el verificador falso incluido en el proyecto. Las pruebas no certifican App Attest, Play Integrity, los tokens de debug registrados, las cuotas reales ni la resistencia de un teléfono físico a instrumentación.

Evidencias reproducibles:

- [Resultados de seguridad y carga](./results.json).
- [Ráfaga de 600 peticiones](./burst-results.json).
- [Verificación de suites y dispositivos](./verification.json).
- [Lecturas públicas de la edición activa](./live-readonly.json).
- [Inventario de dependencias vulnerables](./dependency-audit.json).
- [Banco de pruebas local](./run-audit.cjs).
- [Prueba nativa Flutter](../../integration_test/survey_local_audit_test.dart).

## Resultados de las pruebas

| Prueba | Resultado |
|---|---|
| Suites backend 044–047 | 145/145 |
| Migraciones, transacciones y carreras en PostgreSQL real | 13/13 |
| Identidad, errores y reintentos de Flutter | 48/48 |
| iPhone 16e, simulador iOS 26.2 | 1/1 |
| Pixel 3a, emulador Android API 31 | 1/1 |
| 50 solicitudes simultáneas, misma identidad y negocio | Un 201, 49 respuestas 409; un voto persistido |
| Reutilizar un token consumido | 403 `app_check_replayed` |
| Sin token / DTO incorrecto / opción con texto SQL / JSON >16 KB | 403 / 400 / 422 / 413; sin votos |
| Verificador no disponible y recuperación | 503 con `Retry-After: 30`, sin voto; nuevo intento 201 |
| 100 lecturas simultáneas de ranking con caché vacía | 100 respuestas 200, una carga de datos |
| 10.000 votos aceptados | 10.000 filas de votos, 10.000 dispositivos y 10.000 resultados; cero duplicados y cero votos huérfanos |

En ambos simuladores se ejecutaron el acceso nativo a Keychain/SSAID y el repositorio HTTP real contra localhost: veinte lecturas concurrentes devolvieron la misma identidad, una nueva instancia recuperó esa identidad, el primer envío dio 201, el segundo 409 y `my-votes` reflejó el voto. **No se probó reinstalación, restablecimiento de fábrica ni el recorrido visual completo de la app.**

La compilación iOS necesitó `FLUTTER_SWIFT_PACKAGE_MANAGER=false` para esa ejecución por un conflicto entre plugins CocoaPods y Swift Package Manager. No se cambió la configuración global de Flutter. Android mostró un aviso de versión de NDK, pero compiló y pasó.

## Hallazgos priorizados

### A1 — Alta: las rutas antiguas de resultados evitan caché, límites y visibilidad

**Confirmado localmente por HTTP.**

`GET /surveys/results/:id/:question` llega a `SurveyService.countVotes()` y agrega `SurveyResults` directamente. No consulta `results_visibility`, no usa la caché v3 y no limita peticiones. El endpoint `/count` también consulta directamente la base de datos. Los candidatos y esquemas tienen otras lecturas sin esos controles.

En la prueba, v3 respondió `hidden:true`; la ruta antigua respondió 200 y mostró los 12 votos del negocio. Al bajar el límite de lectura a uno, v3 devolvió `200,429,429`, mientras la ruta antigua respondió `200,200,200`.

Consecuencias: ocultar el ranking no lo hace confidencial; un lector automatizado puede forzar agregaciones repetidas y competir con la escritura de votos por las conexiones de PostgreSQL. No se ejecutó una denegación de servicio contra producción. La edición actual tiene ranking visible, por lo que hoy el impacto de confidencialidad es condicional a cambiarla a `after_close`.

**Corrección:** retirar o autenticar las rutas administrativas y hacer que todas las lecturas públicas deleguen en la misma política de edición, caché y límites. Adaptar el dashboard, que sigue consumiendo las rutas antiguas.

Código: [servicio antiguo](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/survey/surveyService.ts:309), [controlador](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/survey/surveyController.ts:112).

### A2 — Alta: la cola de trabajo puede superar el tiempo de espera del cliente

**Confirmado mediante latencia de base de datos inyectada.**

La configuración del backend no especifica un pool; Sequelize instalado utiliza **cinco conexiones** y hasta **60 segundos** para adquirirlas. La app espera **20 segundos** por petición. Un voto de una categoría produjo **11 operaciones SQL** en el ensayo. No se encontró un límite global de votos en vuelo ni un plazo de negocio que cancele el trabajo antes de agotar la espera de la app.

Con 20 ms añadidos a cada consulta y 600 peticiones simultáneas: **15 respuestas 201 y 585 timeouts de cliente**. Los **600 votos terminaron persistidos** al drenar la cola, en unos 29,87 s. No hubo pérdida demostrada; sí una discrepancia importante entre lo que el usuario ve y lo que queda guardado.

El resultado no prueba que la base de datos de producción tenga esa latencia. Sí prueba el comportamiento del código cuando esa condición ocurre. Los cinco sockets de prueba se compartían entre lecturas y escrituras, como sucede con el proveedor de datos actual.

**Corrección:** medir latencia real, reducir viajes a PostgreSQL, dimensionar conexiones junto con `max_connections` y réplicas, limitar trabajo en vuelo, responder pronto con 503/429 y establecer plazos de consultas/locks coherentes con el cliente. El incremento de pool por sí solo puede trasladar la saturación a PostgreSQL.

Código: [proveedor de datos](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-release/src/db/database.providers.ts:41), [transacción](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/store/sequelizeSurveyStore.ts:135), [timeout de la app](/Users/alejandrocruz/StudioProjects/GuachinchesFlutter/lib/data/HttpRemoteRepository.dart:956).

### A3 — Alta, condicionada a conseguir tokens auténticos: el hash del dispositivo lo elige el cliente

**Ausencia de vínculo confirmada por revisión y prueba con verificador falso; no se demostró una evasión real de App Attest/Play Integrity.**

La API comprueba firma, aplicación, frescura y consumo del token, pero calcula la identidad a partir del `localIdHash` recibido en el cuerpo. No hay prueba que vincule ese hash al dispositivo que obtuvo el token. Con diez tokens frescos aceptados por el verificador y diez hashes elegidos por el cliente se contabilizaron diez votos al mismo negocio.

La restricción UNIQUE garantiza un voto por **identidad declarada y negocio**, no por persona física. El HMAC del servidor protege el almacenamiento, pero no autentica el origen del hash. El pinning dificulta interceptar el cliente normal; no constituye una garantía del servidor contra un cliente instrumentado que ya consiga tokens válidos.

Este riesgo ya estaba documentado en el diseño previo. La auditoría lo confirma, sin presentarlo como un descubrimiento nuevo. También siguen existiendo múltiples teléfonos, perfiles Android y restablecimientos de fábrica.

**Corrección estratégica:** registrar una clave vinculada al atestado y exigir prueba firmada sobre un desafío y el cuerpo del voto; diseñar la solución específica por plataforma. Si se mantiene el modelo actual, aceptar expresamente su alcance, retirar tokens debug de producción, vigilar identidades nuevas y aplicar revisión de patrones de fraude.

Código: [derivación de identidad](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/surveyV3.service.ts:103), [verificador](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/appCheck/firebaseAppCheck.verifier.ts:77).

Firebase describe App Check como protección contra abuso, sin garantizar eliminarlo: [documentación oficial](https://firebase.google.com/docs/app-check).

### A4 — Alta operativa: los límites actuales pueden excluir a votantes legítimos

**Valores por defecto confirmados y rechazo reproducido. Configuración efectiva de producción parcialmente desconocida.**

Por proceso y por red `/24` IPv4 o `/64` IPv6:

- 120 peticiones de voto/minuto.
- 300 identidades nuevas/hora.
- 600 lecturas/minuto para edición actual y `my-votes`.
- Cinco envíos/minuto por identidad.

Se enviaron 301 identidades nuevas desde la misma red, distribuidas en cuatro minutos de reloj simulado: 300 aceptadas y la siguiente rechazada con 429. Una wifi de gala o un operador con CGNAT puede agrupar a muchos participantes legítimos.

Además, los contadores viven en memoria: reiniciar los reinicia y varias réplicas multiplican el cupo agregado. No sustituyen la garantía de la base de datos. `rate_limits=null` en la edición 3 significa que no hay override por edición; las variables de entorno podrían modificar los valores anteriores y no se inspeccionaron.

**Corrección:** definir el pico esperado y la concentración de usuarios por red; ajustar los cupos con esa información y usar límites compartidos para las reglas que deban ser globales. No subirlos sin un límite adicional de capacidad del servidor.

Código: [configuración](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/surveyIntegrity.config.ts:119), [limitador](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/util.ts:11).

### A5 — Alta hasta verificar capacidad externa: cuota y dependencia de App Check

La documentación oficial indica una cuota base de **10.000 llamadas diarias de Play Integrity** en el nivel estándar. No equivale automáticamente a 10.000 votos: influyen el porcentaje Android, las obtenciones de tokens, aperturas, refrescos y reintentos. El consumo de tokens para protección contra repetición añade un viaje de red al backend. [Cuotas](https://firebase.google.com/docs/app-check), [consumo y latencia](https://firebase.google.com/docs/app-check/custom-resource-backend).

La prueba simulada de indisponibilidad mostró que la API falla cerrada con 503 y se recupera. No se validaron cuota contratada, p95 real de Firebase, credenciales, permisos ni comportamiento de una llamada remota que queda colgada. El código de la encuesta no impone un timeout propio ni un máximo de verificaciones en vuelo.

**Acción previa a campaña:** medir consumo por recorrido Android e iOS, confirmar margen diario y límites por segundo en el proyecto real, solicitar ampliación si procede, establecer plazos y alertas de 503/cuota. No desactivar la verificación como respuesta a un pico.

### A6 — Media: un fallo después de COMMIT puede mostrar que el voto falló

**Confirmado por inyección de fallo.**

Después de guardar la transacción, `vote()` ejecuta `votedMap()` para construir la respuesta. Si esa lectura falla, el cliente recibe 500 aunque el voto ya existe. Se reprodujo **500 → un voto guardado → 409 al reintentar**.

El presenter recupera el éxito tras un 409 cuando antes recibió `SurveyNetworkException(maybeDelivered:true)`. Un error HTTP 500 no activa esa marca, por lo que esa misma recuperación no cubre el caso anterior. Esta conclusión de UI procede de revisión de código; la inyección se probó en backend.

**Corrección:** recibo persistente e idempotencia por intento; evitar que una lectura auxiliar convierta un voto confirmado en un error genérico. Reconciliar `my-votes` cuando el resultado del envío sea incierto.

Código: [lectura posterior al commit](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/surveyV3.service.ts:155), [recuperación del presenter](/Users/alejandrocruz/StudioProjects/GuachinchesFlutter/lib/ui/pages/survey_in_app/survey_vote_presenter.dart:195).

### A7 — Media: el cierre se comprueba antes de verificar y guardar

**Confirmado localmente.**

Se configuró el cierre a 100 ms y una verificación que tardaba 300 ms: la API aceptó el voto y su fecha de almacenamiento quedó después del cierre. La edición se lee antes de esperar App Check y la transacción no vuelve a validar la ventana.

Si la regla editorial es aceptar solicitudes recibidas antes del cierre, debe definirse y auditarse ese instante. Si exige que no se acepten votos una vez cerrado, hay que revalidar dentro de la operación atómica con la hora de PostgreSQL y coordinar cambios de edición. Aclarar también la retirada de candidatos mientras hay envíos en vuelo.

Código: [orden de comprobaciones](/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta/src/surveyIntegrity/surveyV3.service.ts:99).

### A8 — Alta como deuda de seguridad: dependencias con avisos conocidos

`npm audit --omit=dev` sobre el lockfile de release devolvió **47 paquetes señalados: cinco críticos, 23 altos, 15 moderados y cuatro bajos**. Son entradas del inventario, incluidas dependencias transitivas; **no son 47 vulnerabilidades explotadas en la encuesta**.

Versiones relevantes: Nest 8.4.1, Express 4.17.3, body-parser 1.19.2, Sequelize 6.17.0, Multer 1.4.5-lts.1 y proxy-addr 2.0.7. El inventario adjunto conserva avisos y rutas. Priorizar parsers, carga de archivos y middleware que comparten proceso con los votos.

Se revisaron condiciones de dos avisos críticos para evitar falsos positivos:

- El aviso de `proxy-addr` requiere determinadas subredes IPv6 mal configuradas. La configuración por defecto inspeccionada no utiliza esas formas; no se demostró suplantación de IP en el despliegue. [Aviso del mantenedor](https://github.com/jshttp/proxy-addr/security/advisories/GHSA-jqcg-44mw-7w3h).
- La inyección mediante `replacements` de Sequelize requiere una combinación específica de `where` y sustituciones. Las consultas directas revisadas de encuesta no prueban esa explotación; actualizar sigue siendo necesario. [Aviso del mantenedor](https://github.com/sequelize/sequelize/security/advisories/GHSA-wrh9-cjv3-2hpw).

**Corrección:** actualización dirigida con pruebas de contratos y carga. No ejecutar `npm audit fix --force` indiscriminadamente: varias soluciones propuestas implican saltos mayores de framework.

## Capacidad: qué significa esperar 10.000 votos

| Distribución de 10.000 envíos | Media de envíos/segundo |
|---|---:|
| Durante 24 horas | 0,12 |
| Durante una hora | 2,78 |
| Durante diez minutos | 16,67 |
| Durante un minuto | 166,67 |

Son envíos de papeleta, no necesariamente filas por categoría. La prueba de carga usó una selección por envío. Varias categorías incrementan el trabajo transaccional. Las lecturas de candidatos, navegación general y demás consumidores también suman tráfico.

Prueba HTTP local, PostgreSQL real, pool de cinco, verificador falso con 25 ms de espera, identidades/redes sintéticas repartidas y dos lecturas adicionales para el 20 % de los usuarios:

| Concurrencia | Votos | Errores | Votos/s del escenario | p95 del POST |
|---|---:|---:|---:|---:|
| 10 | 2.000 | 0 | 280,5 | 32,2 ms |
| 50 | 3.000 | 0 | 858,6 | 74,8 ms |
| 200 | 5.000 | 0 | 764,7 | 257,8 ms |

Con 20 ms adicionales por operación SQL, 300 envíos y concurrencia 100: **14,14 segundos totales, unos 21,2 votos/s y p95 de 4.749,9 ms**. Con ráfaga de 600: el 97,5 % de los clientes agotó su timeout, aunque los votos persistieron.

Estos valores son un ensayo de sensibilidad local. API, generador y PostgreSQL estaban en el mismo Mac; se compilaban los clientes durante parte de las pruebas. No incluyen hardware de producción, balanceador, tráfico de otros endpoints ni atestación real. El RSS registrado también incluye el generador dentro del proceso de auditoría. No usar estas cifras como capacidad certificada de producción.

## Orden propuesto antes de impulsar la votación

1. Cerrar el acceso alternativo a resultados y limitar/cachear las lecturas públicas antiguas y candidatos.
2. Resolver la respuesta posterior al commit y establecer idempotencia/reconciliación.
3. Aplicar admisión de carga y plazos coherentes entre app, API y PostgreSQL; repetir el ensayo con latencia e infraestructura equivalentes a producción.
4. Confirmar cuotas y configuración real de App Check, separación de debug y release, límites por red y número de réplicas.
5. Actualizar las dependencias expuestas y ejecutar regresión completa.
6. Decidir si el modelo de identidad actual satisface la importancia del concurso; documentar la política de cierre y de fraude.

Criterios propuestos para una validación de lanzamiento: cero votos duplicados, recuento consistente entre almacenamiento y ranking, ningún error ambiguo posterior al commit, p95 de envío inferior a dos segundos y rechazos de capacidad rápidos y recuperables. La infraestructura debe demostrarlo con el pico acordado, además de fallos controlados de proveedor y base de datos.

Pendiente de comprobación en entorno equivalente a producción: réplicas, recursos, autoscaling, conexiones y latencia de PostgreSQL, red de confianza del proxy/NodePort, backups y restauración, alertas, cuotas y tokens debug. Esta auditoría no certifica esos controles.

## Reproducción

El auditor rechaza cualquier base que no sea `127.0.0.1:55449/gm_survey_audit`. Las pruebas de integración existentes **borran tablas**: deben ejecutarse exclusivamente en una base desechable, como la creada para esta auditoría.

1. Crear un clúster PostgreSQL nuevo en una carpeta temporal, ligado solo a `127.0.0.1`, puerto 55449, y una base llamada `gm_survey_audit`.
2. En el backend `guachinches-modernos-v3-encuesta`, ejecutar sus fixtures y pruebas:

   ```sh
   SURVEY_IT_DATABASE_URL=postgres://USUARIO@127.0.0.1:55449/gm_survey_audit \
     node node_modules/jest/bin/jest.js --config test/jest-integration.json --runInBand
   ```

3. Desde el repo Flutter, ejecutar:

   ```sh
   AUDIT_BACKEND=/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-encuesta \
   AUDIT_DATABASE_URL=postgres://USUARIO@127.0.0.1:55449/gm_survey_audit \
     node docs/security-audit-2026-10-20/run-audit.cjs
   ```

   `--burst` ejecuta únicamente la ráfaga de 600 en el puerto 3830 y guarda `burst-results.json`. `--serve` mantiene el servidor local en 3829 para las pruebas nativas; no inicia Firebase ni el módulo general de la API.

4. Con `--serve` activo:

   ```sh
   FLUTTER_SWIFT_PACKAGE_MANAGER=false flutter test \
     integration_test/survey_local_audit_test.dart -d ID_SIMULADOR_IOS --no-pub
   flutter test integration_test/survey_local_audit_test.dart \
     -d emulator-5554 --no-pub
   ```

No se han aplicado correcciones funcionales ni desplegado cambios. Los archivos añadidos contienen el informe, las evidencias y las pruebas.

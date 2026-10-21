# Correcciones de encuesta — 20 octubre 2026

Decisión: voto sin registro, App Check y mitigaciones. No se promete una identidad por móvil ni por persona. La atestación nativa avanzada queda fuera de esta entrega.

## Cambios implementados

API: `/Users/alejandrocruz/WebstormProjects/guachinches-modernos-v3-release`.

1. Los dos rankings legacy delegan en el servicio protegido de resultados: visibilidad, caché y presupuesto de lectura comunes. Los resultados ocultos no salen por esas rutas. El contador total cuenta papeletas, no suma categorías.
2. Las cuotas de votos por red, identidad y nuevas identidades se consumen mediante UPSERT atómico en PostgreSQL, compartido por réplicas. La IP de las cuotas IPv4 es exacta; IPv6 usa /64 y se normalizan direcciones IPv4 mapeadas. Se mantiene App Check y su protección frente a reutilización. Esto no vincula `localIdHash` a hardware.
3. Defaults: 600 intentos de voto/IP/minuto, 5/identidad/minuto, 12.000 nuevas identidades/IP/hora y 3.600 lecturas/IP/minuto. Un prelimitador local limita solicitudes antes de atestación; las cuotas persistentes se consumen después de validar identidad/opciones. El aumento de nuevas identidades evita bloquear redes compartidas con 10.000 participantes, pero amplía también el presupuesto de un atacante con atestaciones válidas. La política requiere vigilancia.
4. Máximo de 20 votos en procesamiento por proceso (`SURVEY_MAX_CONCURRENT_VOTES`); el exceso recibe 503 y Retry-After 3. No garantiza capacidad de Firebase, BD ni todas las lecturas. Los clientes deben reintentar con espera y variación aleatoria, sin duplicar papeletas.
5. El recibo completo de votos se lee dentro de la transacción. Si esa lectura falla, también se deshacen los votos y nuevas identidades. Flutter considera un 5xx entrega incierta y solo reconcilia un posterior 409 como éxito cuando cubre toda la papeleta.
6. El informe manual `scripts/survey-watch-new-identities.ts` alinea las altas y votos por hora, valida parámetros y limita cada consulta a 15 s. No es vigilancia automática ni bloqueo automático. Muestra un seudónimo de red /24 IPv4 o /64 IPv6, no una IP exacta. Los candidatos son contexto de todos los votos del cubo en esa hora, no solo de identidades nuevas. El informe puede ejecutar hasta 501 consultas; 15 s no limita su duración total.

## Validación y revisión

- 157 pruebas backend: rutas, integridad, ranking y fiabilidad.
- 17 pruebas con PostgreSQL real aislado: carreras, cuotas entre instancias, expiración, rollback y vigilancia temporal.
- 50 pruebas Flutter, incluidas recuperación de 500 seguida de conflicto completo y parcial.
- Compilación `tsc -p tsconfig.build.json --noEmit --incremental false`: correcta. La compilación general que incluye scripts tiene un error previo en `scripts/037-caso-real.ts:56`; no se ha modificado ese archivo.
- Revisor independiente: revisión estática completada, sin defectos nuevos bloqueantes. Recomendó verificar configuración efectiva, ampliar pruebas combinadas de cuotas y medir dependencias reales.
- La primera ejecución conjunta tuvo seis timeouts HTTP; la suite afectada y la ejecución conjunta posterior pasaron sin cambiar timeouts. Se conserva esa incidencia como limitación del entorno de prueba.
- Carga final: 10.000/10.000 votos en 15,41 s con 20 clientes concurrentes; p95 HTTP 33,1 ms. Ráfaga de 600 votos con 200 clientes y 20 ms añadidos por consulta: 600 aceptados tras 1.746 rechazos temporales 503, completados en 40,44 s; máximo HTTP 1.430,5 ms. Total persistido 10.600, sin duplicados. Se midió tiempo HTTP por intento, no espera total del usuario.
- Carga sintética: ver `hardening-load-results.json` y `run-hardening-load.cjs`. Firebase está simulado; no acredita cuotas reales de Apple/Google. La primera ráfaga agotó diez reintentos en algunos clientes; la comprobación final permite hasta 60 reintentos respetando Retry-After.
- Las pruebas nativas iOS/Android de la auditoría anterior permanecen en `INFORME.md`; no se presentan como una validación nativa nueva de esta corrección del presenter.

## Despliegue pendiente

1. Aplicar primero `migrations/20261020120000-survey-shared-quotas.js` con el procedimiento habitual de migraciones. Necesaria antes de arrancar el backend corregido; sin tabla no se aceptarán votos.
2. Verificar el mismo `SURVEY_ID_PEPPER` en todas las réplicas; no rotarlo durante la edición. Confirmar App Check en modo enforce y proveedores reales.
3. Inspeccionar `SurveySchemas.rate_limits` para la edición activa y las variables `SURVEY_*`: las excepciones por edición prevalecen sobre el entorno; los defaults nuevos NO reemplazan valores existentes. Lecturas y admisión siguen siendo locales a cada proceso.
4. Comprobar el proxy de confianza, timeouts/pool de PostgreSQL y capacidad de Firebase; ejecutar carga en un entorno autorizado equivalente a producción. 10.000 votos totales no son 10.000 conexiones simultáneas.
5. Publicar la actualización Flutter para disponer de recuperación mejorada. Las respuestas 503 no son éxito: deben permitir reintentar sin perder la selección.
6. Ejecutar el informe manual con credenciales de lectura, por ejemplo `npx ts-node --transpile-only scripts/survey-watch-new-identities.ts --hours=24 --min=20 --edition=3 --limit=50`. Revisar concentraciones con contexto; no anular votos por compartir red.

No se ha desplegado, modificado la encuesta de producción ni activado una tarea periódica. Cambios aplicados al backend release y Flutter; no ha sido necesaria una modificación de dashboard/web para cerrar estas rutas de API.

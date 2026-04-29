---
name: guachinches-coordination
description: Coordinación cross-repo para el proyecto Guachinches / Donde Comer Canarias. Este es el repo MOBILE (Flutter + flutter_bloc + http + dotenv). Cualquier tarea no trivial debe consultar el repo de coordinación (.claude/coordination/) antes de empezar y, al detectar impacto en backend (NestJS+PostgreSQL) o dashboard (React SPA), generar archivos de migration en migration-backend/ o migration-dashboard/. Nunca editar código de los otros dos repos directamente.
---

# guachinches-coordination — repo MOBILE (Flutter)

Este repo es la app **Flutter** del ecosistema. Convive con:
- backend: NestJS + PostgreSQL (`guachinches-modernos-v3`)
- dashboard: React SPA (Create React App, `guachinches-react`)

La coordinación entre los 3 repos vive en `.claude/coordination/` (symlink a `guachinches-coordination`).

## Lectura obligatoria al iniciar tarea no trivial

Antes de tocar código, lee:

1. `.claude/coordination/architecture/mobile-SKILL.md` — arquitectura real de este repo (Cubit + Presenter+View, RemoteRepository/HttpRemoteRepository, dotenv ENDPOINT_V1/V2).
2. `.claude/coordination/shared/conventions.md` — naming, idioma, voz editorial, versionado de migrations.
3. `.claude/coordination/shared/endpoints.md` — listado canónico de endpoints HTTP por recurso (V1 vs V2, DTOs, divergencias dashboard ↔ backend). **Si vas a llamar a un endpoint, verifica que está aquí; si no está, hay que añadirlo (vía migration-backend).**
4. `.claude/coordination/shared/types.md` — modelos JSON compartidos (Restaurant, Review, Cupones, Visit, …) + discrepancias de naming.
5. `.claude/coordination/shared/database.md` — esquema PostgreSQL real (tablas, columnas, FKs). Útil cuando un campo no aparece en mobile y necesitas saber si existe en BD.
6. `.claude/coordination/migration-mobile/` — migrations pendientes que afectan a este repo. Si hay alguna `[ ] Pendiente` que toque tu zona, aplícala primero.

## Reglas de detección de impacto

### → Impacto en BACKEND (NestJS + PostgreSQL)

Cualquiera de estos cambios dispara migration:
- Necesitas un endpoint nuevo o un campo nuevo en la respuesta de uno existente.
- Cambias la forma del payload que envías a un endpoint (POST/PUT/PATCH).
- Cambias un modelo en `lib/data/model/` para reflejar un campo que el backend no devuelve aún.
- Necesitas un filtro, query param o agregación nueva en una ruta existente.
- Subida/borrado de assets (foto, video) que requiere lógica nueva en el servidor.

**Acción:**
1. Notifica explícitamente: `⚠️ Esta tarea requiere cambios en BACKEND.`
2. Crea `.claude/coordination/migration-backend/NNN-titulo-corto.md` (NNN = siguiente correlativo en la carpeta, empezando 001).
3. Usa `migration-backend/PLANTILLA.md` como base.
4. En "Prompt sugerido para Claude Code" escribe un prompt **autónomo** (que un agente abierto sobre el repo backend pueda ejecutar sin contexto adicional): nombre del controller a tocar, ruta exacta, DTO esperado con campos y tipos, ejemplo de payload, SQL/migration de Sequelize si hay cambio de esquema.
5. Actualiza también `shared/types.md` con el nuevo endpoint o el cambio de contrato (en la misma migration o en la nota "Cuando se aplique, añadir a shared/types.md: …").

### → Impacto en DASHBOARD (React SPA)

Dispara migration si:
- El cambio expone un dato/acción de moderación que el panel admin debería gestionar (ej. nuevo recurso CRUD, nueva categoría editable).
- Modificas un endpoint que el dashboard ya consume (ver `shared/types.md`).
- Añades un flujo de aprobación/reporte que requiere UI de revisión.

**Acción:**
1. `⚠️ Esta tarea requiere cambios en DASHBOARD.`
2. Crea `.claude/coordination/migration-dashboard/NNN-titulo.md`.
3. Prompt autónomo: ruta a tocar (recordar que es **React Router v5 con `src/pages/` y `src/helpers/routes.js`**, no Next.js), página/componente nuevo, llamadas API a añadir en `src/Data/Petitions/ApiRequest.js`, integración con Redux si aplica.

## Cierre de tarea

Antes de dar la tarea por terminada:
1. Lista las migrations creadas en este turno (paths en `migration-backend/` y/o `migration-dashboard/`).
2. Recuerda al usuario:
   - Commit en este repo Flutter: solo cambios en `lib/`, `pubspec.yaml`, etc.
   - Commit + push en repo coordination con las nuevas migrations (mensaje sugerido: `add: migration <repo>/<NNN-titulo>`).
3. Si añadiste un endpoint a `shared/types.md`, mencionarlo en el commit de coordination.

## Anti-patrones específicos de este repo

- ❌ **No uses `Navigator.push` directo.** Siempre vía `GlobalMethods.pushPage` / `pushPageWithFocus` / `pushAndReplacement` (`lib/globalMethods.dart`).
- ❌ **No hardcodees URLs del backend.** Usa `dotenv.env['ENDPOINT_V1']` o `ENDPOINT_V2`. Si encuentras una URL hardcoded en `HttpRemoteRepository.dart` (existen en `uploadVideo`/`deleteVideo`), no la repliques — déjala como deuda señalada.
- ❌ **No introduzcas libs nuevas** sin verificar que no exista equivalente ya en `pubspec.yaml`. Stack vigente: `flutter_bloc 8.1.3`, `http 0.13.4`, `flutter_dotenv 5.0.2`, `sqflite`, `geolocator 13.0.0`, `cached_network_image`, `flutter_svg`.
- ❌ **No asumas cambios en la API sin verificar `shared/types.md`.** Si el endpoint no está documentado allí, búscalo en `HttpRemoteRepository.dart` antes de inventarlo.
- ❌ **No mezcles V1 y V2** sin razón. Norma actual: usuarios/login/municipios viejos = V1 (puerto 480); todo lo demás = V2 (puerto 459).
- ❌ **No edites código fuera de este repo.** Cambios en backend o dashboard van por **migration**, no por edición directa. El symlink `.claude/coordination/` apunta al repo central — solo escribir ahí archivos de coordinación, nunca código de los otros repos.
- ❌ **No mezcles patrones.** Pantallas complejas van con **Presenter+View interface + Cubit**; pantallas simples solo Cubit. No introducir un tercer patrón.
- ❌ **No uses `print()` en producción** (ya hay deuda señalada en `HttpRemoteRepository.dart`).

## Recordatorio
SOLO puedes editar archivos en este repo Flutter y en `.claude/coordination/` (vía symlink). Cualquier otro cambio se documenta como migration.

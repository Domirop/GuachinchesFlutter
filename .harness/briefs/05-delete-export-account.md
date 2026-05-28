Cumplir con **App Store Guideline 5.1.1(v)**: dar al usuario controles para (1) eliminar su cuenta con grace period de 30 días y (2) exportar todos sus datos en JSON descargable.

CONTEXTO ACTUAL (verificado):

- `lib/ui/pages/settings/settings_screen.dart:199-207` ya tiene UI de "Eliminar cuenta" con modal de confirmación + llamada a `_presenter.deleteAccount()`.
- `lib/ui/pages/settings/settings_presenter.dart:47-58` ya implementa `deleteAccount()` que llama a `_remoteRepository.deleteUser(userId)` y borra secure storage.
- `lib/data/HttpRemoteRepository.dart:463-472` ya implementa `deleteUser(String id)` con DELETE a `${ENDPOINT_V1}user/{id}` — **HARD DELETE actual, sin grace period**.
- No existe ningún endpoint de export ni en `RemoteRepository` ni en `HttpRemoteRepository`.
- No existe sección "Mis datos" ni similar en Settings.

OBJETIVO doble: (A) convertir el delete en soft-delete con grace 30d con UI de "cancelar borrado pendiente"; (B) añadir botón "Descargar mis datos" que pida JSON al backend y lo guarde / comparta.

CONTRATO FUNCIONAL:

1. **Cross-repo: doc de migración backend** (el harness no puede tocar `.claude/coordination/**` por hook; pedir al usuario que confirme y escribirlo a mano tras "sí"):
   - Path: `.claude/coordination/migration-backend/018-account-delete-export.md`
   - Contenido a especificar:
     * Endpoint `POST /v1/user/{id}/request-deletion` → marca `users.deletion_requested_at = NOW()`. Devuelve `{deletionScheduledAt: ISO8601}` con `NOW() + 30 days`.
     * Endpoint `POST /v1/user/{id}/cancel-deletion` → setea `deletion_requested_at = NULL`. Devuelve 200 vacío.
     * Endpoint `GET /v1/user/{id}/export` → devuelve `{user, votes, visitas, lists, comments, blockedUsers}` con todos los datos del usuario en JSON. Content-Type `application/json`. Body grande aceptable.
     * Job cron diario que purga usuarios con `deletion_requested_at < NOW() - 30 days` (hard delete real).
     * Login flow: si `deletion_requested_at IS NOT NULL` al login, el endpoint `/auth/login` devuelve `{user, deletionPending: true, deletionScheduledAt: ISO8601}` en lugar de bloquear el login (así puede cancelar).

2. **Modificar `lib/data/RemoteRepository.dart`** (abstract):
   ```dart
   Future<DateTime> requestAccountDeletion(String userId);
   Future<void> cancelAccountDeletion(String userId);
   Future<Map<String, dynamic>> exportUserData(String userId);
   ```
   Mantener `deleteUser(String id)` para compat (lo usan tests / flujos viejos), pero marcar con `@Deprecated('Use requestAccountDeletion for App Store compliance')`.

3. **Modificar `lib/data/HttpRemoteRepository.dart`**: implementar los 3 nuevos con timeouts 15s. `exportUserData` devuelve `json.decode(response.body)` tal cual (Map raw). Sin caché (es de la lista NO-cache del sprint #4).

4. **Crear `lib/data/cubit/account/account_cubit.dart`** + `account_state.dart`:
   - States: `AccountIdle`, `AccountDeletionScheduled(DateTime scheduledAt)`, `AccountExporting`, `AccountExportReady(File jsonFile)`, `AccountError(String message)`.
   - Métodos: `requestDeletion()`, `cancelDeletion()`, `exportData()`.
   - `exportData()` llama al endpoint, escribe el JSON a un fichero temporal vía `path_provider` (**ya en pubspec**) en `(await getTemporaryDirectory()).path/mis-datos-dcc-{userId}-{timestamp}.json`, y emite `AccountExportReady(file)`.

5. **Pantalla nueva `lib/ui/pages/profile/account_management_screen.dart`**:
   - AppBar "Mi cuenta" con back.
   - Dos secciones (cards estilo `_SettingsCard` existente):
     * **"Descargar mis datos"** — texto explicativo + botón. Al pulsar: muestra loader, al recibir `AccountExportReady`, llama `Share.shareXFiles([XFile(file.path)], subject: 'Mis datos de Dónde Comer Canarias')` con `share_plus` (**verificar si está en pubspec; si NO está, fallback: copiar el path al clipboard y mostrar snackbar "Guardado en {path}"; NO añadir paquete**).
     * **"Eliminar mi cuenta"** — texto explicativo (30 días grace, durante ese tiempo el login restaura), botón rojo "Solicitar eliminación".
       - Si el estado es `AccountDeletionScheduled`, mostrar banner amarillo "Tu cuenta se eliminará el {DD/MM/YYYY}. Inicia sesión antes para cancelar." + botón "Cancelar eliminación".
   - **Anchors `Semantics(identifier:)`**:
     * `account-export-button`
     * `account-export-loader`
     * `account-delete-request-button`
     * `account-delete-cancel-button`
     * `account-delete-scheduled-banner`

6. **Wiring en Settings**:
   - En `settings_screen.dart`, donde está la fila "Eliminar cuenta" (línea ~199), cambiar la acción: en lugar del modal hard-delete actual, navegar a `AccountManagementScreen()` vía `Navigator.push`.
   - **Eliminar** la llamada directa a `_presenter.deleteAccount()` (queda el método para tests, pero ya no se invoca desde UI).
   - Añadir una fila ANTES "Mis datos" que también navegue a `AccountManagementScreen()` (mismo destino, dos puntos de entrada).
   - Anchor en la fila: `settings-account-management-row`.

7. **Login flow — manejar deletion pending**:
   - En `lib/ui/pages/login/login_screen.dart` (o presenter equivalente), tras login exitoso, si la respuesta del backend incluye `deletionPending: true`, mostrar diálogo modal NO-dismissable:
     * Título: "Tu cuenta está pendiente de eliminación"
     * Body: "Programada para el {fecha}. ¿Quieres cancelarla y seguir usando la app?"
     * Botones: "Salir" (logOut) | "Cancelar eliminación" (llama `cancelAccountDeletion`, luego cierra modal y procede al home).
   - **Si el endpoint /auth/login todavía no devuelve `deletionPending`** (depende del backend doc del paso 1), envolver en try/catch y omitir si el campo no viene — defensivo pero sin tragar errores reales.

ANCHORS (todos en `kebab-case`, identifier no label):
- `account-export-button`, `account-export-loader`
- `account-delete-request-button`, `account-delete-cancel-button`
- `account-delete-scheduled-banner`
- `settings-account-management-row`

TESTS OBLIGATORIOS:

- `test/cubit/account_cubit_test.dart`:
  * `requestDeletion` → emite `AccountDeletionScheduled` con el datetime del mock.
  * `cancelDeletion` → emite `AccountIdle`.
  * `exportData` → emite `AccountExporting` → `AccountExportReady(file)` con el path esperado.
  * Errores HTTP → emiten `AccountError`.
  * Usar `MockRemoteRepository` (patrón existente con mockito o un fake clase a mano si no hay mockito en dev_dependencies — **verificar antes**; si no hay mocking lib, escribir fake a mano implementando la interfaz).

- `test/widget/account_management_screen_test.dart`:
  * Render con state `AccountIdle` → muestra ambos botones, no banner.
  * Render con state `AccountDeletionScheduled` → muestra banner con fecha formateada + botón cancelar.
  * Tap en `account-export-button` → llama `cubit.exportData()`.
  * Tap en `account-delete-request-button` → muestra confirm modal, confirmar → llama `cubit.requestDeletion()`.
  * Mock cubit con `BlocProvider.value(value: MockAccountCubit())`.

PROHIBIDO:
- Modificar `pubspec.yaml` (usar paquetes ya presentes; `share_plus` solo si ya está, sino fallback).
- Tocar ios/ o android/.
- Hacer hard-delete desde UI (siempre soft-delete con grace).
- Tragar excepciones de red silenciosamente.
- Duplicar componentes existentes — reusar `_SettingsCard`, `_SettingsRow` de `settings_screen.dart` si encajan (si son private, hacer wrapper o extraer a `lib/ui/components/settings_card.dart`).
- Borrar el método `deleteUser` del repo (lo usan migraciones / tests viejos; solo deprecarlo).

OUT OF SCOPE:
- Encriptar el JSON exportado (no es requisito de la guideline).
- Backend implementation (eso va en `migration-backend/018-…md` para el otro repo).
- Email de confirmación al solicitar borrado (lo manda el backend; cliente no se entera).
- Re-login automático tras cancelar deletion (el modal vuelve al home tras cancelar, suficiente).

ENTREGA: diff que pase `flutter analyze` y los nuevos tests verdes. `flutter test test/cubit/account_cubit_test.dart test/widget/account_management_screen_test.dart` debe pasar. Resto de tests existentes siguen verdes. Aviso explícito en el resumen del generator: "Falta crear `.claude/coordination/migration-backend/018-account-delete-export.md` — el hook bloquea writes a esa ruta; pedir al usuario que confirme y escribirlo después."

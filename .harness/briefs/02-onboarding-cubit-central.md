Centralizar los 6 flags de onboarding dispersos en `flutter_secure_storage` bajo un `OnboardingCubit` único, sin romper el flujo actual ni perder usuarios ya onboarded.

CONTEXTO ACTUAL (verificado):

Flags en secure_storage (claves crudas, sin schema):
- `onBoardingFinished` (string 'true'/'false') — gate principal del splash
- `onb_name` (string) — nombre del usuario capturado en onboarding
- `prefIslandId` (uuid) — isla preferida elegida en step island
- `prefTastes` (string CSV) — gustos elegidos en step tastes
- `prefLocationAsked` (string 'true') — flag de "ya pedimos permiso de location"
- `surveyOnboarding2026Shown` (string 'true') — flag de "ya mostramos survey post-onboarding"

Sitios donde se escriben/leen (ANTES del refactor):
- `lib/ui/pages/onboarding_flow/onboarding_flow_screen.dart:54,56,59,69,909` — escrituras durante el flujo nuevo
- `lib/ui/pages/onBoarding/on_boarding.dart:20` — escritura legacy (pantalla VIEJA, ver más abajo)
- `lib/ui/pages/splash_screen/splash_screen_presenter.dart:86,88` — lectura del gate y default-set a 'false' si no existe
- `lib/ui/pages/profile/profile_v2.dart:94-99` — borrado de los 6 flags en `_resetOnboarding`

CONTRATO FUNCIONAL:

1. Crear `lib/data/cubit/onboarding/onboarding_cubit.dart` y `onboarding_state.dart`:
   - Modelo `OnboardingData` (no usar paquete equatable; `==` y `hashCode` manuales como en el resto del repo) con campos:
     * `bool finished`
     * `String? name`
     * `String? islandId`
     * `List<String> tastes` (parseado/serializado a CSV en secure_storage)
     * `bool locationAsked`
     * `bool surveyShown`
   - Estados: `OnboardingInitial`, `OnboardingLoaded(OnboardingData data)`. Sin estado de error (no es crítico; si lee mal, asume defaults).
   - API pública del cubit:
     * `Future<void> hydrate()` — lee los 6 flags y emite `OnboardingLoaded`. Llamar una vez al arranque (en `main.dart` antes del runApp, o en el primer build del splash).
     * `Future<void> setName(String name)`
     * `Future<void> setIsland(String islandId)`
     * `Future<void> setTastes(List<String> tastes)`
     * `Future<void> markLocationAsked()`
     * `Future<void> markSurveyShown()`
     * `Future<void> markFinished()` — pone `onBoardingFinished=true`
     * `Future<void> reset()` — borra los 6 flags
     * Getter conveniente `bool get isFinished => state is OnboardingLoaded && (state as OnboardingLoaded).data.finished`
   - Inyectar `FlutterSecureStorage` por constructor para facilitar test (default `const FlutterSecureStorage()`).
   - **Importante**: las claves en secure_storage deben seguir siendo EXACTAMENTE las mismas para no obligar a re-onboardear a usuarios existentes. Define constantes privadas en el cubit:
     ```dart
     static const _kFinished = 'onBoardingFinished';
     static const _kName = 'onb_name';
     static const _kIslandId = 'prefIslandId';
     static const _kTastes = 'prefTastes';
     static const _kLocationAsked = 'prefLocationAsked';
     static const _kSurveyShown = 'surveyOnboarding2026Shown';
     ```

2. Registrar `OnboardingCubit` en el `MultiBlocProvider` de `lib/main.dart` al mismo nivel que los demás. Llamar `..hydrate()` en el create para que arranque hidratado.

3. Migrar todas las escrituras directas a través del cubit:
   - `lib/ui/pages/onboarding_flow/onboarding_flow_screen.dart:54` → `context.read<OnboardingCubit>().markFinished()`
   - `lib/ui/pages/onboarding_flow/onboarding_flow_screen.dart:56` → `setName(_name)`
   - `lib/ui/pages/onboarding_flow/onboarding_flow_screen.dart:59` → `setIsland(_island!.id)`
   - `lib/ui/pages/onboarding_flow/onboarding_flow_screen.dart:69` → `setTastes(_tastes)`
   - `lib/ui/pages/onboarding_flow/onboarding_flow_screen.dart:909` → `markLocationAsked()`
   - `lib/ui/pages/onBoarding/on_boarding.dart:20` → `markFinished()` (mantener la pantalla vieja por ahora — solo cambiar la escritura)

4. Migrar lecturas:
   - `lib/ui/pages/splash_screen/splash_screen_presenter.dart:86-88` → leer del cubit (`context.read<OnboardingCubit>().isFinished`). Eliminar el default-set a 'false' del legacy (el cubit ya hidrata con default `finished: false`).

5. Refactor de `lib/ui/pages/profile/profile_v2.dart:_resetOnboarding`:
   - Reemplazar los 6 `_storage.delete(...)` por `context.read<OnboardingCubit>().reset()`.
   - **Añadir diálogo de confirmación robusto ANTES** de llamar `reset()`:
     * Título: '¿Resetear onboarding?'
     * Cuerpo: 'Se borrarán tu nombre, isla preferida y preferencias. Volverás a ver la pantalla de bienvenida al reiniciar la app. Tu cuenta y favoritos no se ven afectados.'
     * Botones: 'Cancelar' (cierra) / 'Resetear' (rojo de peligro, dispara reset).
   - Usar AppColors / context.brand para respetar dark mode.

6. (Opcional, pero recomendado) Añadir un `OnboardingMigrator` que verifique al arrancar que las claves viejas no tienen formato corrupto. No es crítico — saltar si añade complejidad.

ANCHORS de a11y para tests (kebab-case en inglés):
- `'profile-reset-onboarding-button'` (en profile_v2, ya puede existir o crear)
- `'reset-onboarding-confirm-dialog'`
- `'reset-onboarding-confirm-cta'`
- `'reset-onboarding-cancel-cta'`

TESTS OBLIGATORIOS:

- `test/cubit/onboarding_cubit_test.dart`:
  * Mock de `FlutterSecureStorage` (usar un fake in-memory simple, no añadir paquetes).
  * `hydrate()` con storage vacío → `OnboardingLoaded` con todos los defaults (finished=false, name=null, etc.).
  * `hydrate()` con todos los flags presentes → `OnboardingLoaded` con valores correctos.
  * `setName('Ale')` → escribe en storage Y emite nuevo state.
  * `setTastes(['carne','pescado'])` → escribe 'carne,pescado' Y emite state con lista de 2 elementos.
  * `markFinished()` → finished=true en state y en storage.
  * `reset()` → todos los flags borrados, state vuelve a defaults.
  * Backwards-compat: si en storage hay solo `onBoardingFinished='true'` y nada más → `hydrate()` devuelve finished=true, name=null (no crashea).

- `test/ui/pages/profile/reset_onboarding_dialog_test.dart`:
  * Tap en 'profile-reset-onboarding-button' muestra el diálogo.
  * Tap en 'reset-onboarding-cancel-cta' cierra sin llamar al cubit.
  * Tap en 'reset-onboarding-confirm-cta' llama `cubit.reset()` (mock del cubit) y cierra.

PROHIBIDO:
- Modificar `pubspec.yaml`.
- Tocar ios/ o android/.
- Cambiar las claves de secure_storage (`onBoardingFinished`, `onb_name`, etc.) — usuarios existentes deben mantener su onboarding.
- Borrar `lib/ui/pages/onBoarding/on_boarding.dart` (pantalla vieja, puede que se referencie desde algún sitio que no veo en grep — solo cambiar la escritura interna).
- Usar `Semantics(label:)` como anchor técnico, solo `identifier`.
- Añadir paquete `equatable` ni paquete de fake storage — fake inline en el test.

OUT OF SCOPE (para futuros sprints):
- Mover el estado a backend (cross-device sync).
- Reescribir el flujo de onboarding o añadir nuevos steps.
- Eliminar la pantalla `lib/ui/pages/onBoarding/on_boarding.dart` antigua (requiere validar que no se referencia).

ENTREGA: diff que pase `flutter analyze` y `flutter test` sin warnings, con cobertura del cubit y el diálogo en los nuevos test files. Comprobar a mano leyendo el código que no quedan referencias a `_storage.write(key: 'onBoardingFinished'...)` ni equivalentes fuera del cubit (excepto el legacy `on_boarding.dart` que ya migra al cubit en su escritura).

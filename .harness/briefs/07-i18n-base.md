Implementar la **base de internacionalización (i18n)** con `flutter_localizations` + `intl` + ARB files. Soportar **es_ES** (idioma principal, ya es el actual) y **en_US** (fallback en inglés). Migrar strings de pantallas core; el resto queda como TODO marcado.

CONTEXTO ACTUAL (verificado):

- `pubspec.yaml` NO tiene `flutter_localizations` ni `intl`.
- NO existe `lib/l10n/`.
- Toda la app está hardcoded en español. Aproximadamente 200+ strings en `lib/ui/pages/`.
- El idioma del usuario en la memoria de Claude (`CLAUDE.md`): "Idioma de trabajo: español". O sea, **es_ES sigue siendo el default**; en_US es solo para iPad/iPhone configurados en inglés.

CONTRATO FUNCIONAL:

1. **pubspec.yaml** (excepción justificada): añadir
   ```yaml
   dependencies:
     flutter_localizations:
       sdk: flutter
     intl: ^0.18.1   # versión compatible con Flutter 3.35

   flutter:
     generate: true
   ```

2. **Crear `l10n.yaml`** en la raíz:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_es.arb
   output-localization-file: app_localizations.dart
   output-class: AppL10n
   nullable-getter: false
   ```

3. **Crear `lib/l10n/app_es.arb`** con las claves de las pantallas core. Estructura:
   ```json
   {
     "@@locale": "es",

     "homeGreetingMorning": "Buenos días",
     "homeGreetingAfternoon": "Buenas tardes",
     "homeGreetingEvening": "Buenas noches",
     "homeNearbySectionTitle": "Cerca de ti",
     "homeTopRestaurantsTitle": "Mejor valorados",
     "homeSeeAll": "Ver todos",

     "tabExplora": "Explora",
     "tabListas": "Listas",
     "tabMapa": "Mapa",
     "tabVisitas": "Visitas",
     "tabPerfil": "Perfil",

     "loginWithGoogle": "Continuar con Google",
     "loginWithApple": "Continuar con Apple",
     "loginPrivacyNotice": "Al continuar aceptas nuestras condiciones",

     "settingsTitle": "Ajustes",
     "settingsLogOut": "Cerrar sesión",
     "settingsDeleteAccount": "Eliminar cuenta",
     "settingsMyData": "Mis datos",

     "profileVisitsCount": "{count, plural, =0{Sin visitas} =1{1 visita} other{{count} visitas}}",
     "@profileVisitsCount": {
       "placeholders": { "count": { "type": "int" } }
     },

     "mapRestaurantsNearby": "{count} restaurantes cerca",
     "@mapRestaurantsNearby": {
       "placeholders": { "count": { "type": "int" } }
     },

     "listsScreenTitle": "Listas",
     "listsEmpty": "Aún no hay listas",

     "visitsScreenTitle": "Mis visitas",
     "visitsEmpty": "Aún no has registrado visitas",

     "commonRetry": "Reintentar",
     "commonCancel": "Cancelar",
     "commonConfirm": "Confirmar",
     "commonLoading": "Cargando…",
     "commonError": "Algo salió mal",

     "openStatusOpen": "Abierto",
     "openStatusClosed": "Cerrado"
   }
   ```

4. **Crear `lib/l10n/app_en.arb`** con las mismas claves traducidas a inglés (traducciones razonables; "Buenos días" → "Good morning", etc.). Sin metadatos `@@locale` y `placeholders` redundantes (solo `"@@locale": "en"` y las strings).

5. **Modificar `lib/main.dart`**:
   ```dart
   import 'package:flutter_localizations/flutter_localizations.dart';
   import 'package:guachinches/l10n/app_localizations.dart';
   ```
   En el `MaterialApp`:
   ```dart
   MaterialApp(
     // ...
     localizationsDelegates: AppL10n.localizationsDelegates,
     supportedLocales: AppL10n.supportedLocales,
     // sin locale: hardcoded → usa el del device, fallback es_ES por orden en supportedLocales
   )
   ```

6. **Migrar strings en pantallas core** (NO todas; solo estas). Patrón: `Text('Buenos días')` → `Text(AppL10n.of(context).homeGreetingMorning)`. Donde aplique plural: `AppL10n.of(context).profileVisitsCount(count)`.

   Lista de pantallas a migrar:
   * `lib/ui/pages/new_home/new_home_screen.dart` — saludo, títulos de sección, "Ver todos"
   * `lib/ui/pages/new_home/new_home_tab_scaffold.dart` — labels de los 5 tabs
   * `lib/ui/pages/login/login_screen.dart` — botones y aviso de privacidad
   * `lib/ui/pages/settings/settings_screen.dart` — título, "Cerrar sesión", "Eliminar cuenta"
   * `lib/ui/pages/listas/listas_screen.dart` — título y empty state
   * `lib/ui/pages/map/map_search.dart` — "X restaurantes cerca"
   * `lib/ui/pages/mis_visitas/...` o pantalla de Visitas — título y empty state
   * `lib/ui/components/open_status_badge.dart` — "Abierto" / "Cerrado"
   * Botones comunes (`commonRetry`, `commonCancel`, `commonConfirm`) donde aparezcan en esas pantallas

7. **Strings NO migradas**: dejar un TODO con prefijo estable para grep posterior:
   ```dart
   // TODO(i18n): migrate to AppL10n
   Text('Algún texto sin clave aún')
   ```
   Esto aplica a pantallas fuera del core (advanced search, restaurant detail, surveys, onboarding deeper, etc.). NO migrarlas en este sprint.

8. **Verificar que el código generado existe tras `flutter pub get`**:
   El generador de Flutter crea `lib/l10n/app_localizations.dart` automáticamente al hacer `flutter pub get`. Si el harness no puede ejecutar `flutter pub get`, el evaluator validará por inspección del pubspec + .arb files + diff de imports.

TESTS OBLIGATORIOS:

- `test/l10n/i18n_smoke_test.dart`:
  * Pre-condición: `WidgetsFlutterBinding.ensureInitialized()`.
  * Test 1: build de un `MaterialApp` con `supportedLocales: [Locale('es')]` y `home: Builder(builder: (ctx) => Text(AppL10n.of(ctx).homeGreetingMorning))` → encuentra "Buenos días".
  * Test 2: idem con `[Locale('en')]` → encuentra "Good morning".
  * Test 3: plural `profileVisitsCount(0)` → "Sin visitas" (es) / "No visits" (en).
  * Test 4: plural `profileVisitsCount(5)` → "5 visitas" / "5 visits".
  * **Importante**: estos tests requieren `localizationsDelegates: AppL10n.localizationsDelegates`. Si fallan por delegate missing, añadir `GlobalMaterialLocalizations.delegate` y compañía explícitamente — la suite generada las expone via `AppL10n.localizationsDelegates`.

- NO tests por pantalla migrada (es mecánico; los widget tests existentes deben seguir verdes con el wrapper de `MaterialApp` que añadan en setUp).

PROHIBIDO:
- Migrar TODAS las strings de un golpe. Solo las 9-10 pantallas core listadas.
- Forzar el locale en `MaterialApp(locale: ...)`. Dejar que el device decida.
- Cambiar el copy actual de las pantallas core a algo distinto — usar EXACTAMENTE las strings actuales como valor del `app_es.arb`.
- Romper widget tests existentes — si alguno explota por falta de delegates, añadir `MaterialApp.localizationsDelegates` en el setUp del test (mínimo cambio).
- Añadir gettext, easy_localization, ni cualquier otra alternativa a flutter_localizations.

OUT OF SCOPE:
- Traducir TODA la app (queda como TODO marcado en strings no-core).
- Otros idiomas (no añadir fr, de, etc. — solo es y en por ahora).
- RTL languages.
- Pluralización en idiomas con reglas complejas (ar, pl, ru).
- Selector de idioma en Settings (la app sigue el device).

ENTREGA: `flutter pub get` ejecutable (genera `app_localizations.dart`), `flutter analyze` limpio, `flutter test test/l10n/i18n_smoke_test.dart` verde. Resto de tests existentes verdes (con setUp ajustado donde haga falta por delegates). En el resumen del generator: número de strings migradas vs número de TODO(i18n) restantes.

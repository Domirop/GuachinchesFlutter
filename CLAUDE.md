# GuachinchesFlutter — CLAUDE.md

App móvil de **"Dónde Comer Canarias"** (DCC). El sub-tag "Guachinches" es solo interno; no es branding público.

## Stack

- **Flutter** 3.35.7 · **Dart** 3.9.2
- **Estado**: `flutter_bloc` 8.1.3 (patrón Cubit)
- **HTTP**: `http` 0.13.4 (REST contra backend NestJS externo)
- **Config**: `flutter_dotenv` (`env_files/debug.env` / `env_files/release.env`)
- **Auth**: `google_sign_in` 6.1.x · `sign_in_with_apple` 6.1.x · `flutter_secure_storage`
- **Firebase**: `firebase_core` 2.17 · `firebase_analytics` 10.5
- **Ads**: `google_mobile_ads`
- **Otros**: `app_links` 3.0 (instalado pero handler comentado), `geolocator` 13.0, `flutter_svg`, `flutter_dotenv`
- **Font**: 'SF Pro Display' transversal
- **Theme**: dual (light + dark). Paleta canónica en [lib/config/app_colors.dart](lib/config/app_colors.dart). Legacy `GlobalMethods.bgColor/blueColor` solo para pantallas viejas.

## App identity

| | iOS | Android |
|---|---|---|
| Bundle id / applicationId | `com.jonay.guachinches` | `com.jonay.guachinches` |
| Manifest | [ios/Runner/Info.plist](ios/Runner/Info.plist) | [android/app/build.gradle](android/app/build.gradle) |

## Routing & deeplinks

- **Routing**: clásico — `Navigator.push` + `MaterialPageRoute`. **No** hay `go_router`, `auto_route`, ni similar.
- **Tabs**: 5 slots `EXPLORA · LISTAS · MAPA · VISITAS · PERFIL` montados con `IndexedStack` en [lib/ui/pages/new_home/new_home_tab_scaffold.dart](lib/ui/pages/new_home/new_home_tab_scaffold.dart).
- **Deeplinks**: `app_links` está en `pubspec.yaml` pero `_initDeepLinks()` en [lib/main.dart](lib/main.dart) está **comentado**. Universal links **no** están operativos.
- **Schemes registrados** (informativo, no para navegación de tests):
  - iOS `CFBundleURLSchemes`: solo `com.googleusercontent.apps.138481024291-...` (Google Sign-In).
  - Android `intent-filter`: App Link `https://encuesta.guachinchesmodernos.com/encuesta` (encuestas web).
- **Regla para tests**: como no hay deeplinks operativos, todo flujo no-primer-pantalla debe navegarse vía taps sobre `Semantics(identifier:)`.

## Harness multi-agente — ÚNICO sistema de tests/verificación

Este repo se verifica **exclusivamente** a través del harness Planner → Generator → Evaluator (zero-shared-context, coordinación por filesystem). El código vive en `/Users/alejandrocruz/WebstormProjects/guachinches-coordination/harness/`; este repo solo tiene el wrapper:

```bash
./scripts/harness-launcher.sh bugfix <slug> "<descripción o ruta a fichero>"
./scripts/harness-launcher.sh capture <slug> "<descripción>"
SKIP_PREFLIGHT=1 ./scripts/harness-launcher.sh bugfix smoke "smoke-test"
```

Outputs en `~/GuachinchesHarness/runs/<id>/` (vault global compartido entre worktrees).

### Reglas duras (NO negociables)

1. **Selectores estables** = `Semantics(identifier: '<screen>-<componente>-<rol>')`, kebab-case inglés. Nunca `Semantics(label:)` como anchor técnico (es para screen reader y mete ruido a11y). Nunca taps por texto o coordenadas — frágil.
2. **Anchors existentes hoy**: solo los 5 tabs (`tab-explora`, `tab-listas`, `tab-mapa`, `tab-visitas`, `tab-perfil`) en `new_home_tab_scaffold.dart`. El resto debe añadirlo el Generator en la misma iteración que escribe el test que los usa.
3. **Patrol > Maestro** para integración. Patrol es Flutter-native; usa `patrolTest(...)` bajo `integration_test/`. Maestro solo si Patrol no puede expresar el flujo (permisos del sistema, cross-app). `patrol` **no** está aún en `pubspec.yaml` — el Generator lo añade a `dev_dependencies` cuando el contrato lo pida.
4. **`flutter_test`** para lógica de widgets, cubits y presenters. Tests bajo `test/`. Es la opción más barata y determinista; preferirla siempre que la lógica sea testeable en aislamiento.
5. **`code-review`** es el default: la mayoría de cambios (color, copy, refactor, nuevos widgets, llamadas API) se verifican leyendo el diff.
6. **`visual`** (screenshot vía `mcp__xcodebuildmcp__*`) **solo** para cambios visibles en la pantalla de arranque (home con chip de tiempo + hero "BUENAS NOCHES" + bottom navbar). Nunca para flujos que requieren un tap.
7. **Esperas**: si un test necesita esperar, usar APIs de espera explícitas (`patrolTester.pumpAndSettle()`, `extendedWaitUntil`). **Prohibido `sleep(...)`**.
8. **Fragmentación de flows**: un test = una intención. Si necesitas login + búsqueda + filtro, son tres tests (o tres `group()`s con setup compartido).

### Antipatrones (rechazo automático del Evaluator)

- Tocar `pubspec.yaml`, `ios/Podfile`, o `android/` sin que el contrato lo exija.
- Catch silenciosos que tragan errores.
- Strings hardcodeadas que deberían venir de locale o config.
- Duplicar componentes existentes (`SectionHeader`, `OpenStatusBadge`, `CategoryPillChip`, `NearbyRestaurantCard`, etc.) en vez de reusar.
- `Semantics(label: ...)` como anchor técnico.
- Modificar `.claude/`, `scripts/`, `.mcp.json` desde el Generator.

### Preflight (iOS por defecto)

`preflight.sh` del profile mobile:
1. Boota simulador (`iPhone 15 Pro` por defecto, override con `IOS_SIMULATOR`).
2. Lanza `flutter run -d <udid> --no-pub` en background, escribe pid en `<run_dir>/.flutter.pid` y log en `<run_dir>/flutter-run.log`.

`SKIP_PREFLIGHT=1` asume que ya tienes simulador y `flutter run` corriendo. Útil para iteración rápida.

### Reload entre iteraciones

`reload-or-rebuild.sh` compara `git status` antes/después del Generator. Si solo cambian `.dart`, hace hot reload (touch a `lib/main.dart`). Si cambian `pubspec.yaml`, `ios/Podfile*`, `android/build.gradle`, `ios/Runner/Info.plist`, rebuild completo (mata el pid, vuelve a llamar a `preflight::flutter_run`).

## Key files (referencia)

- [lib/main.dart](lib/main.dart) — arranque, providers, theme cubit hydrate
- [lib/ui/pages/new_home/new_home_tab_scaffold.dart](lib/ui/pages/new_home/new_home_tab_scaffold.dart) — bottom-nav, 5 tabs con `Semantics(identifier:)`
- [lib/ui/pages/new_home/new_home_screen.dart](lib/ui/pages/new_home/new_home_screen.dart) — tab 0 (Explora), home con hero + chips + secciones
- [lib/ui/pages/listas/listas_screen.dart](lib/ui/pages/listas/listas_screen.dart) — tab 1 (Listas)
- [lib/ui/pages/map/map_search.dart](lib/ui/pages/map/map_search.dart) — tab 2 (Mapa)
- [lib/ui/pages/login/login_screen.dart](lib/ui/pages/login/login_screen.dart) — login Google + Apple (botón Apple va blanco, no negro)
- [lib/config/app_colors.dart](lib/config/app_colors.dart) — paleta Atlántico (oficial)
- [lib/globalMethods.dart](lib/globalMethods.dart) — helpers legacy

## Preferencias del usuario

- Idioma de trabajo: **español**.
- Git: NO añadir `Co-Authored-By` a commits.
- Mockups y código nuevo usan AppColors, no GlobalMethods.

## TODOs pendientes (no fijados aún)

- Si el contrato pide algo en pantallas profundas y `app_links` se quiere reactivar, descomentar `_initDeepLinks()` en [lib/main.dart](lib/main.dart) y registrar scheme `dcc://` en Info.plist + AndroidManifest. Mientras tanto, navegación por taps.

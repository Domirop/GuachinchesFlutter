# Harness multi-agente — Planner → Dev → Tester

> Sistema de verificación automática para los repos de **Dónde Comer Canarias / Guachinches**.
> En vez de pedirle a una IA "haz este cambio y reza", el harness ejecuta una
> **cadena de 3 agentes especializados sin contexto compartido** que se coordinan
> por ficheros, e itera hasta que el cambio cumple un contrato medible.

---

## 1. Qué es (en una frase)

Le das **una intención** (un bug a arreglar o una feature a capturar) y el harness
arranca tres agentes en cadena:

1. **Planner** (Opus) — convierte tu petición en un **contrato** con criterios de
   aceptación *medibles* (no "que se vea bien", sino "el widget `home-hero` renderiza
   la foto, verificable por code-review").
2. **Generator / Dev** (Sonnet) — implementa el cambio en el repo. **Nunca commitea**
   (solo hace `git add`); deja el árbol staged para que tú revises.
3. **Evaluator / Tester** (Opus) — verifica el diff contra el contrato. Si falla,
   devuelve *findings* concretos y el Generator vuelve a intentarlo. Loop hasta
   `MAX_ITERS` (default 5) o hasta "passed".

Coordinación **zero-shared-context**: cada agente arranca limpio y solo lee/escribe
ficheros en el vault (`~/GuachinchesHarness/runs/<run-id>/`). Esto evita que el
contexto se contamine y que un agente "se convenza a sí mismo" de que algo funciona.

Inspirado en el paper de Anthropic *"Build Agents That Run for Hours Without Losing the Plot"*.

---

## 2. Por qué nos sirve

- **El tester es independiente del dev.** No comparten memoria → no hay sesgo de
  "yo lo escribí, yo lo apruebo".
- **Criterios medibles, no opiniones.** Cada criterio tiene un `measurable_by`:
  `code-review` (leer diff), `visual` (screenshot del simulador), `manual`, o `curl`
  (para la API). Nada de "parece que va".
- **Itera solo.** Si el Evaluator rechaza, el Generator corrige sin que tú toques nada.
- **Multi-stack.** El mismo orquestador sirve 3 (pronto 4) repos vía *profiles*:

  | Profile | Stack | Repo | Cómo verifica visual |
  |---|---|---|---|
  | `mobile` | Flutter | GuachinchesFlutter | iOS Simulator (xcodebuildmcp) |
  | `dashboard` | Next.js + React + MUI | admin-guachinches-v2 | chrome-devtools MCP |
  | `api` | NestJS + Sequelize | guachinches-modernos-v3 | curl + jq |
  | `web` *(próximo)* | Next.js | donde-comer-canarias-web | — |

- **Seguro por diseño.** El Generator no puede commitear, ni tocar `pubspec.yaml`,
  `ios/Podfile`, `android/`, `.claude/`, `scripts/` o `.mcp.json` salvo que el
  contrato lo exija explícitamente.

---

## 3. Cómo se usa

Desde la raíz del repo correspondiente:

```bash
# Arreglar un bug:
./scripts/harness-launcher.sh bugfix <slug> "<descripción o ruta a un brief .md>"

# Capturar/implementar una feature nueva:
./scripts/harness-launcher.sh capture <slug> "<descripción o ruta a un brief .md>"

# Iteración rápida (ya tienes simulador + `flutter run` corriendo):
SKIP_PREFLIGHT=1 ./scripts/harness-launcher.sh bugfix <slug> ".harness/briefs/NN-mi-brief.md"
```

- `<slug>` = identificador corto en kebab-case (ej. `visitas-skeleton-timing`).
- El tercer argumento puede ser **texto suelto** o la **ruta a un fichero `.md`**
  con el brief detallado (recomendado para tareas no triviales — ver `.harness/briefs/`).
- Salidas: `~/GuachinchesHarness/runs/<run-id>/` (vault compartido).
- Resultado: imprime `passed after N iter(s)` o `failed`, y las sesiones de cada
  agente por si quieres continuar manualmente con `claude --resume <id>`.

### Variables útiles

| Var | Default | Para qué |
|---|---|---|
| `MAX_ITERS` | `5` | Cuántas rondas dev↔tester antes de rendirse |
| `SKIP_PREFLIGHT` | — | No arranca simulador/servidor (lo tienes tú ya) |
| `IOS_SIMULATOR` | `iPhone 15 Pro` | Qué simulador bootea (solo mobile) |
| `HARNESS_QUIET` | — | Silencia notificaciones |

---

## 4. Anatomía de un contrato (lo que produce el Planner)

Cada criterio de aceptación tiene **exactamente 5 campos**:

```json
{
  "id": "ac-1",
  "platform": "ios",                       // ios | web | api | backend | cross
  "criterion": "El tab Visitas muestra las visitas del usuario o un estado claro de 'inicia sesión', nunca un skeleton infinito",
  "measurable_by": "code-review",          // code-review | visual | manual | curl
  "target": "VisitasScreen escucha UserCubit + re-resuelve userId al hacerse visible el tab vía MenuCubit"
}
```

Reglas duras del harness (no negociables):

- **Selectores estables** para tests = `Semantics(identifier: '<screen>-<componente>-<rol>')`,
  kebab-case inglés. Nunca taps por texto ni coordenadas.
- **Patrol > Maestro** para integración; `flutter_test` para lógica de widgets/cubits;
  `code-review` es el default para la mayoría de cambios.
- **`visual`** (screenshot) solo para cambios visibles en la pantalla de arranque.
- Prohibido `sleep(...)` en tests — usar esperas explícitas (`pumpAndSettle`, `extendedWaitUntil`).
- Un test = una intención.

---

## 5. PROMPT DE ONBOARDING (entrégaselo tal cual a otra persona)

> Copia/pega esto en una conversación nueva de Claude Code, dentro del repo objetivo.

```
Vas a usar nuestro harness multi-agente Planner → Dev → Tester para verificar
cambios en este repo. NO implementes el cambio tú directamente: tu trabajo es
preparar un buen brief y lanzar el harness, que arranca tres agentes en cadena
(Planner en Opus → Generator/Dev en Sonnet → Evaluator/Tester en Opus), sin
contexto compartido, coordinados por ficheros, iterando hasta cumplir un
contrato medible.

CÓMO LANZARLO (desde la raíz del repo):

  ./scripts/harness-launcher.sh <bugfix|capture> <slug> "<texto o ruta a brief.md>"

  - bugfix  = arreglar algo que está roto.
  - capture = implementar/capturar una feature nueva.
  - <slug>  = kebab-case corto, ej. "login-apple-button-blanco".
  - Para tareas no triviales, escribe primero un brief en .harness/briefs/NN-slug.md
    y pasa su RUTA como tercer argumento (mejor que texto suelto).
  - Iteración rápida si ya tienes simulador + `flutter run` vivos:
      SKIP_PREFLIGHT=1 ./scripts/harness-launcher.sh ...

QUÉ DEBE LLEVAR UN BUEN BRIEF:
  1. Contexto: qué pantalla/componente, qué ficheros clave (rutas exactas).
  2. Síntoma/objetivo concreto y observable.
  3. Causa raíz si la conoces.
  4. Criterios de aceptación MEDIBLES (cómo se sabe que está bien): por
     code-review (leer el diff), visual (screenshot de la pantalla de arranque),
     manual, o curl (API).
  5. Restricciones: qué NO tocar (pubspec.yaml, ios/, android/, .claude/...
     salvo que sea imprescindible).

REGLAS DURAS (el Evaluator rechaza si se incumplen):
  - Selectores de test estables: Semantics(identifier: '<screen>-<componente>-<rol>')
    en kebab-case inglés. Nunca taps por texto/coordenadas, nunca Semantics(label:)
    como anchor técnico.
  - Patrol > Maestro para integración; flutter_test para lógica de widgets/cubits;
    code-review es el default.
  - Prohibido sleep(...) en tests → esperas explícitas (pumpAndSettle, extendedWaitUntil).
  - Un test = una intención.
  - El Generator nunca commitea (solo git add); revisa tú el diff y commitea al final.

RESULTADO:
  - Imprime "passed after N iter(s)" o "failed".
  - Artefactos en ~/GuachinchesHarness/runs/<run-id>/.
  - Si quieres seguir una sesión a mano: claude --resume <session-id> (los imprime al final).

Empieza preguntándome QUÉ cambio quiero verificar; redacta el brief conmigo;
y cuando lo aprobemos, lánzalo con el harness.
```

---

## 6. Notas

- El código del harness vive en `guachinches-coordination/harness/`; cada repo
  consumidor solo tiene el wrapper `scripts/harness-launcher.sh` (instalado por
  `bootstrap.sh`).
- Modelos por defecto: Planner/Evaluator = Opus, Generator = Sonnet (override con
  `PLANNER_MODEL` / `GENERATOR_MODEL` / `EVALUATOR_MODEL`).
- Para reinstalar el wrapper en un repo:
  `coordination/harness/core/bootstrap.sh --repo <mobile|dashboard|api>`.
```

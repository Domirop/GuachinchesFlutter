Reemplazar el placeholder de la tab 'Visitas' por una pantalla real conectada al backend.

CONTEXTO:
- Tab 4 de las 5 del scaffold principal. Actualmente en lib/ui/pages/mis_visitas/mis_visitas.dart hay un widget de 54 líneas que solo dice 'Sin visitas' sin lógica.
- El scaffold lib/ui/pages/new_home/new_home_tab_scaffold.dart referencia un _PlaceholderTab para esta posición — sustituir por la pantalla real montada con Semantics(identifier: 'tab-visitas') ya existente.
- Backend NestJS expone GET /visits/user/{userId} (verificar contrato en .claude/coordination/ si existe, si no usar fallback inline mock + TODO documentado).
- userId actual está en UserCubit (lib/data/cubit/user/user_cubit.dart) y en flutter_secure_storage bajo clave 'userId'.

CONTRATO FUNCIONAL:
1. VisitsCubit nuevo en lib/data/cubit/visits/ con estados: VisitsInitial, VisitsLoading, VisitsLoaded(List<Visit>), VisitsEmpty, VisitsError(String). Usar equatable.
2. Modelo Visit en lib/data/model/visit.dart con: id, restaurantId, restaurantName, restaurantPhotoUrl, visitedAt (DateTime), rating (int? 1-5 nullable), note (String? nullable). fromJson + toJson.
3. Método en RemoteRepository + HttpRemoteRepository: Future<List<Visit>> getUserVisits(String userId) con timeout 15s y manejo de error.
4. Pantalla nueva lib/ui/pages/visitas/visitas_screen.dart:
   - AppBar con título 'Mis visitas' usando AppColors / context.brand (respeta dark mode).
   - Lista vertical de VisitCard (componente nuevo lib/ui/components/cards/visit_card.dart): foto del restaurante (CachedNetworkImage con placeholder), nombre, rating en estrellas si existe, 'visitado hace X días/meses', nota truncada si existe.
   - Tap en card → push a RestaurantDetail existente.
   - Pull-to-refresh con RefreshIndicator que llama VisitsCubit.refresh().
   - Empty state: ilustración/icono + 'Aún no has visitado ningún restaurante' + CTA 'Explorar' que vuelve a tab Explora.
   - Error state: mensaje + botón 'Reintentar'.
   - Loading: 3-5 shimmer cards (NO añadir paquetes nuevos; si shimmer no está en pubspec usar AnimatedOpacity con Container gris).
5. Registrar VisitsCubit en el MultiBlocProvider de lib/main.dart al mismo nivel que los demás.
6. Reemplazar referencia a _PlaceholderTab de Visitas en new_home_tab_scaffold.dart por VisitasScreen. Mantener Semantics(identifier: 'tab-visitas') existente.

ANCHORS de a11y para tests (kebab-case en inglés):
- 'visitas-screen-root'
- 'visitas-list'
- 'visitas-card-{id}' (uno por item)
- 'visitas-empty-cta'
- 'visitas-retry-button'
- 'visitas-refresh-indicator'

TESTS OBLIGATORIOS:
- test/cubit/visits_cubit_test.dart: estados loading→loaded, loading→empty, loading→error, refresh. Mock del repository.
- test/ui/pages/visitas/visitas_screen_test.dart: empty state visible si VisitsEmpty, lista renderiza N cards si VisitsLoaded.
- test/ui/components/cards/visit_card_test.dart: renderiza con y sin rating, con y sin nota, formato 'hace X días' correcto.

PROHIBIDO:
- Modificar pubspec.yaml.
- Tocar ios/ o android/.
- Usar Semantics(label:) como anchor técnico — solo identifier.
- Duplicar OpenStatusBadge, SectionHeader u otros componentes existentes.

ENTREGA: diff que pase flutter analyze y flutter test sin warnings, con cobertura del cubit y la pantalla en los nuevos test files.

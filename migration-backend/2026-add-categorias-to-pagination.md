# Backend migration · Incluir `categoriasRestaurantes` en `/restaurant/pagination`

**Solicitado por**: app mobile (Flutter)
**Fecha**: 2026-05-09
**Repo afectado**: backend (NestJS + PostgreSQL)
**Endpoint**: `GET /restaurant/pagination?from=N&island=...`

## Contexto

La home del mobile carga el pool de restaurantes via `restaurant/pagination`. La sección "HOY EN..." muestra cards alineadas con un banner contextual por hora ("Desayunos", "Terrazas con atardecer", "Cenas"…). El filtro temático que cuadra el copy con la lista vive en `lib/utils/contextual_pool.dart` (mobile) y se apoya en dos campos del modelo `Restaurant`:

- `restaurantTypeId` ✅ **viene** en el response actual
- `categoriasRestaurantes` ❌ **no viene** — el array se devuelve siempre vacío

Verificado en runtime con un pool de 269 restaurantes (Tenerife): 0 / 112 abiertos llevan `categoriasRestaurantes` poblado, mientras que los `restaurantTypeId` sí están todos presentes.

## Impacto en mobile

Sin las categorías, el slot horario "Terrazas con atardecer" (17-19h) no puede filtrar por `Terraza` (`ebbc3752-04e1-4b41-8a92-5c129849cc0b`) ni `Con vistas` (`de73bfc5-641f-4796-960b-ae75583b8d24`). Como workaround temporal mobile filtra por type (`Lounge Tenerife`, `Cofradia`, `Bodegones`) lo cual es una aproximación pobre — un guachinche tradicional con buena terraza queda fuera, por ejemplo.

Otras secciones del producto (filtros avanzados, badges en cards de listas curadas, recomendaciones de "perfecto para mascotas / sin gluten / con zona infantil") tampoco se pueden hacer hasta tener categorías en el pool.

## Cambio solicitado

Incluir el array `categoriasRestaurantes` con sus relaciones `categorias` en el response del endpoint paginado, igual que ya se hace en `GET /restaurant/:id`.

### Response actual (resumido)

```json
{
  "restaurants": [
    {
      "id": "...",
      "nombre": "...",
      "restaurantTypeId": "459517f7-1417-4829-bc4d-fdae09753371",
      "horarios": "...",
      "horariosJson": { ... },
      "fotos": [ ... ],
      "menus": [ ... ]
      // ❌ falta categoriasRestaurantes
    }
  ]
}
```

### Response esperado

```json
{
  "restaurants": [
    {
      "id": "...",
      "nombre": "...",
      "restaurantTypeId": "459517f7-1417-4829-bc4d-fdae09753371",
      "categoriasRestaurantes": [
        {
          "id": "...",
          "categorias_restauranteId": "...",
          "categoriaId": "ebbc3752-04e1-4b41-8a92-5c129849cc0b",
          "categorias": {
            "id": "ebbc3752-04e1-4b41-8a92-5c129849cc0b",
            "nombre": "Terraza"
          }
        }
      ],
      "horarios": "...",
      "horariosJson": { ... }
    }
  ]
}
```

## Sugerencia de implementación (NestJS / TypeORM)

En el servicio que resuelve `restaurant/pagination`, añadir el join con la relación `categoriasRestaurantes` y dentro su `categorias`:

```ts
// restaurant.service.ts
this.repo.find({
  relations: {
    categoriasRestaurantes: {
      categorias: true,
    },
    // ...resto de relaciones que ya cargas (fotos, menus, etc.)
  },
  // ...filtros existentes
});
```

Si el modelo expone otro nombre de relación, mantener la misma forma de respuesta (`categoriasRestaurantes` array con `categorias` anidado) para no romper el parser actual de mobile (`lib/data/model/CategoryRestaurant.dart`).

## Coste / riesgo

- N+1 queries: usar `leftJoinAndSelect` o `relations` carga eager — verificar que el response no se infla demasiado para listados de 200+ restaurantes.
- Tamaño del payload: añade ~5-10 categorías por restaurante. Si preocupa, devolver solo los `categoriaId`s (sin el objeto `categorias` completo) y cachear el catálogo de categorías en mobile.

## Cuando esté en producción

En mobile revertir `contextualFilterFor(17-19)` para volver a usar el filtro por categoría:

```dart
if (hour >= 17 && hour <= 19) {
  return const ContextualFilter(
    categoryIds: { CategoryIds.terraza, CategoryIds.conVistas },
  );
}
```

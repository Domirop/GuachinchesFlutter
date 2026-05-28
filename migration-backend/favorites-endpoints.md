# Backend Contract — Favorites Endpoints

**Sprint**: #5 — Modo offline real  
**Fecha**: 2026-05-24  
**Estado**: Pendiente de implementación en NestJS

## Resumen

El cubit `FavoritesCubit` (mobile) implementa una capa local-first con sincronización diferida.  
Los siguientes endpoints REST son requeridos para el flujo de sync online.

---

## GET `/user/:id/favorites`

Devuelve la lista de restaurantes marcados como favoritos por el usuario.

### Path params

| Param | Tipo   | Descripción      |
|-------|--------|------------------|
| id    | string | UUID del usuario |

### Response 200

```json
[
  { "restaurantId": "uuid-del-restaurante" },
  { "restaurantId": "otro-uuid" }
]
```

### Errores

| Status | Descripción              |
|--------|--------------------------|
| 404    | Usuario no encontrado    |
| 500    | Error interno del servidor|

---

## POST `/user/:id/favorites/:restaurantId`

Añade un restaurante a los favoritos del usuario. **Debe ser idempotente** (si ya existe, devuelve 200/201 sin error).

### Path params

| Param        | Tipo   | Descripción              |
|--------------|--------|--------------------------|
| id           | string | UUID del usuario         |
| restaurantId | string | UUID del restaurante     |

### Response

| Status | Descripción                          |
|--------|--------------------------------------|
| 201    | Favorito creado                      |
| 200    | Favorito ya existía (idempotente OK) |
| 404    | Usuario o restaurante no encontrado  |

### Body

Sin body requerido. El servidor infiere la relación por los path params.

---

## DELETE `/user/:id/favorites/:restaurantId`

Elimina un restaurante de los favoritos. **Debe ser idempotente** (si no existe, devuelve 200/204 sin error).

### Path params

| Param        | Tipo   | Descripción              |
|--------------|--------|--------------------------|
| id           | string | UUID del usuario         |
| restaurantId | string | UUID del restaurante     |

### Response

| Status | Descripción                                |
|--------|--------------------------------------------|
| 204    | Favorito eliminado                         |
| 200    | OK (alternativa aceptada)                  |
| 404    | Usuario o restaurante no encontrado        |

---

## Notas de comportamiento para sync diferido

- El cliente móvil puede enviar `POST` o `DELETE` varios segundos/minutos después de la acción del usuario (cuando vuelve la conexión).
- Por eso **idempotencia es crítica**: si el usuario añade el mismo favorito dos veces offline y ambas peticiones llegan al backend, solo debe registrarse una vez.
- El backend NO necesita conocer `ts` ni `sync_pending` — son campos internos del cliente.
- No se requiere resolución de conflictos sofisticada: **last-write-wins** en local es suficiente para este sprint.

/// Nombre legible del tipo de local — capa PURA (sin Flutter).
///
/// `Restaurant.type` guarda el **UUID** de `restaurantTypeId`, no un nombre. Al
/// pintarlo tal cual, la ficha del negocio mostraba un UUID crudo encima del
/// título ("CE25663D-4916-…" en vez de "TASCA"). Aquí lo traducimos.
///
/// Regla de oro: **nunca devolver un UUID**. Si el valor no se reconoce y tiene
/// pinta de UUID, devolvemos cadena vacía y quien llama simplemente no pinta
/// nada — mejor un hueco que un identificador técnico en la cara del usuario.
library;

import 'package:guachinches/utils/contextual_pool.dart';

/// UUID de tipo → nombre en SINGULAR (la ficha describe UN negocio, así que
/// "Tasca" lee mejor que "Tascas").
const Map<String, String> kRestaurantTypeNames = {
  RestaurantTypeIds.tascas: 'Tasca',
  RestaurantTypeIds.bodegones: 'Bodegón',
  RestaurantTypeIds.cofradia: 'Cofradía',
  RestaurantTypeIds.loungeTenerife: 'Lounge',
  RestaurantTypeIds.guachinchesModernos: 'Guachinche moderno',
  RestaurantTypeIds.guachinchesTradicionales: 'Guachinche tradicional',
  RestaurantTypeIds.restaurantes: 'Restaurante',
  RestaurantTypeIds.barCafeteria: 'Bar/Cafetería',
  // Los dos siguientes no están en RestaurantTypeIds (no se usan como filtro
  // contextual), pero el backend puede devolverlos.
  '9a39e037-b118-4547-afbb-1e43f67db43a': 'Experiencia',
  '16fa5c15-8210-4c0f-a63b-f6e3303238cd': 'Mercado',
};

final RegExp _uuidRe = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Traduce el valor de `Restaurant.type` a algo mostrable.
///
/// - UUID conocido → su nombre ('Tasca').
/// - UUID desconocido → `''` (no pintamos identificadores técnicos).
/// - `'vacio'` / vacío → `''`.
/// - Cualquier otra cosa (el backend ya mandó un nombre) → tal cual.
String restaurantTypeLabel(String? type,
    {Map<String, String> names = kRestaurantTypeNames}) {
  final t = type?.trim() ?? '';
  if (t.isEmpty || t.toLowerCase() == 'vacio') return '';

  final known = names[t.toLowerCase()];
  if (known != null) return known;

  if (_uuidRe.hasMatch(t)) return '';
  return t;
}

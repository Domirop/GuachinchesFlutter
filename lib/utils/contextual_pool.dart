/// Filtros contextuales que alinean la lista de "HOY EN..." con el copy
/// del HourAwareBanner. Si el banner dice "Terrazas con atardecer", el
/// pool solo debe traer locales con la categoría Terraza / Con vistas.
///
/// Las constantes son IDs de Postgres del backend de Guachinches; si el
/// backend reasigna IDs hay que actualizarlas aquí.
class RestaurantTypeIds {
  static const tascas = 'ce25663d-4916-43e9-9918-c2a07b32347f';
  static const bodegones = '7bfec60c-b55f-4d7e-9f48-1769a70dc597';
  static const cofradia = '111ed407-296c-4b36-a29c-ecf656dddb55';
  static const loungeTenerife = '20fab1aa-23b1-4318-942a-7bbafd6be8d6';
  static const guachinchesModernos = '82054a45-6db3-4931-bb17-4aba588445e4';
  static const guachinchesTradicionales =
      '8ea45515-8a14-4638-9560-80a6446c129f';
  static const restaurantes = '459517f7-1417-4829-bc4d-fdae09753371';
  static const barCafeteria = '954e8bbd-ac85-45d3-acf2-353b3c853225';
}

class CategoryIds {
  static const zonaInfantil = 'bafaae21-3839-42ca-b5bf-32467d69c8f6';
  static const permiteMascotas = '4e14825a-eeeb-46c6-a098-0a49e0bef851';
  static const sinGluten = '0571cc02-2c8e-4c5e-982d-ecfd703e9899';
  static const accesoPmr = '9126ff4f-eef8-4c19-a21c-68f3995f6bf0';
  static const carneCabra = '4e5ab5e0-fd6f-43b4-898c-27398c53a51b';
  static const cochinoNegro = 'f5702f43-609c-4644-98d0-ce2dde8b0b87';
  static const animales = 'd748d060-c6b3-41ee-93fa-24b60da49913';
  static const datafono = '45632dcb-76a2-4e8b-9375-a840f342669c';
  static const terraza = 'ebbc3752-04e1-4b41-8a92-5c129849cc0b';
  static const conV = '11a5f3a4-3ce3-48bb-9749-03eac640e23e';
  static const papasPinasCostillas = 'ad6e2ada-0259-4578-b67e-970846c93f74';
  static const pescadoMarisco = 'fb5341c4-33d1-4e5c-b759-f25494459b5d';
  static const puchero = 'c0d8085a-5a17-482c-b7cc-c4b27b09229c';
  static const cosechaPropia = '980c2236-4e60-48c0-bc39-83117dcfad8e';
  static const conVistas = 'de73bfc5-641f-4796-960b-ae75583b8d24';
}

/// Filtro temático asociado a un slot horario.
class ContextualFilter {
  /// Cualquiera de estos types vale (OR entre sí).
  final Set<String> typeIds;

  /// Al menos una de estas categorías debe estar presente (OR entre sí).
  final Set<String> categoryIds;

  const ContextualFilter({
    this.typeIds = const {},
    this.categoryIds = const {},
  });

  bool get isEmpty => typeIds.isEmpty && categoryIds.isEmpty;
}

/// Devuelve el filtro temático que cuadra con el copy del HourAwareBanner.
///
/// Mapeo:
///   7-11  Desayunos             → Bar/Cafetería
///   13    Menú · cierra en 1h   → Restaurantes / Tascas / Bodegones / Guachinches
///   14-16 Sobremesa             → ídem
///   17-19 Terrazas con atardecer → categorías Terraza / Con vistas
///   20+   Cenas                 → Restaurantes / Tascas / Bodegones / Modernos / Lounge
///   resto Madrugada             → sin filtro extra
ContextualFilter contextualFilterFor(int hour) {
  if (hour >= 7 && hour <= 11) {
    return const ContextualFilter(
      typeIds: {RestaurantTypeIds.barCafeteria},
    );
  }
  if (hour == 13 || (hour >= 14 && hour <= 16)) {
    return const ContextualFilter(
      typeIds: {
        RestaurantTypeIds.restaurantes,
        RestaurantTypeIds.tascas,
        RestaurantTypeIds.bodegones,
        RestaurantTypeIds.guachinchesTradicionales,
        RestaurantTypeIds.guachinchesModernos,
      },
    );
  }
  if (hour >= 17 && hour <= 19) {
    // Idealmente filtraríamos por categoría Terraza / Con vistas, pero
    // el endpoint /restaurant/pagination no devuelve `categoriasRestaurantes`
    // (ver migration-backend/2026-add-categorias-to-pagination.md). Como
    // workaround usamos los types más asociados con terraza/vistas.
    return const ContextualFilter(
      typeIds: {
        RestaurantTypeIds.loungeTenerife,
        RestaurantTypeIds.cofradia,
        RestaurantTypeIds.bodegones,
      },
    );
  }
  if (hour >= 20) {
    return const ContextualFilter(
      typeIds: {
        RestaurantTypeIds.restaurantes,
        RestaurantTypeIds.tascas,
        RestaurantTypeIds.bodegones,
        RestaurantTypeIds.guachinchesModernos,
        RestaurantTypeIds.loungeTenerife,
        RestaurantTypeIds.cofradia,
      },
    );
  }
  return const ContextualFilter();
}

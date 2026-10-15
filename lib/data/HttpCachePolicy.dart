class HttpCachePolicy {
  static const Duration listTtl = Duration(hours: 1);
  static const Duration detailTtl = Duration(minutes: 30);
  static const Duration referenceTtl = Duration(hours: 6);
  static const Duration referenceRevalidateAfter = Duration(minutes: 30);

  /// Un acierto de caché más joven que esto se sirve sin revalidar en
  /// segundo plano. Antes se revalidaba en CADA acierto: un arranque con la
  /// caché llena volvía a pedir y reescribir todas las páginas de
  /// restaurantes (radio y SQLite despiertos sin necesidad).
  static const Duration listRevalidateAfter = Duration(minutes: 5);
  static const Duration referenceRevalidateAfter = Duration(minutes: 30);
}

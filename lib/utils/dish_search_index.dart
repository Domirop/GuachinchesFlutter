import 'package:guachinches/data/model/Visit.dart';

/// Normalizes a string for dish search: lowercase, strips common diacritics,
/// trims whitespace, and collapses consecutive spaces into one.
String _normalize(String s) {
  const accentMap = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  var result = s.toLowerCase().trim();
  for (final entry in accentMap.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Builds a reverse index: normalized dish token → set of restaurantIds.
///
/// Tokens of length < 3 after normalization are discarded.
Map<String, Set<String>> buildDishIndex(List<Visit> visits) {
  final index = <String, Set<String>>{};
  for (final visit in visits) {
    final rid = visit.restaurantId;
    if (rid.isEmpty) continue;
    for (final dish in visit.dishes) {
      final normalized = _normalize(dish.name);
      for (final token in normalized.split(' ')) {
        if (token.length < 3) continue;
        index.putIfAbsent(token, () => {}).add(rid);
      }
    }
  }
  return index;
}

/// Returns the restaurantIds that match [query] against the [index].
///
/// - Returns {} if query.trim().length < 3.
/// - Splits the query into normalized tokens (length ≥ 3).
/// - Returns the intersection of each token's set.
/// - Falls back to union only when the query has ≥ 2 tokens and the
///   intersection is empty.
Set<String> matchRestaurantIds(
  Map<String, Set<String>> index,
  String query,
) {
  if (query.trim().length < 3) return {};

  final tokens = _normalize(query)
      .split(' ')
      .where((t) => t.length >= 3)
      .toList();

  if (tokens.isEmpty) return {};

  Set<String>? intersection;
  for (final token in tokens) {
    final ids = index[token] ?? const {};
    intersection =
        intersection == null ? Set.of(ids) : intersection.intersection(ids);
  }
  final result = intersection ?? {};

  if (result.isEmpty && tokens.length >= 2) {
    final union = <String>{};
    for (final token in tokens) {
      union.addAll(index[token] ?? const {});
    }
    return union;
  }

  return result;
}

/// For each restaurantId in [dishMatchIds], finds the name of the first dish
/// (across all matching visits) whose normalized name contains any token from
/// the normalized [query]. Visits without an embedded restaurant are skipped.
Map<String, String> buildDishFirstMatchNames(
  List<Visit> visits,
  Set<String> dishMatchIds,
  String query,
) {
  final tokens = _normalize(query)
      .split(' ')
      .where((t) => t.length >= 3)
      .toSet();
  if (tokens.isEmpty) return {};

  final result = <String, String>{};
  for (final visit in visits) {
    final rid = visit.restaurantId;
    if (!dishMatchIds.contains(rid)) continue;
    if (result.containsKey(rid)) continue;
    for (final dish in visit.dishes) {
      final norm = _normalize(dish.name);
      if (tokens.any((t) => norm.contains(t))) {
        result[rid] = dish.name;
        break;
      }
    }
  }
  return result;
}

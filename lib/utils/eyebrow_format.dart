/// Joins eyebrow segments with the canonical separator ' · ' (U+00B7, single
/// space on each side). Trims each part and skips empty segments.
String eyebrowJoin(List<String> parts) {
  return parts
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join(' · ');
}

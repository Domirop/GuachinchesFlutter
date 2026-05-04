class NewHomeFiltersState {
  final String islandId;
  final String islandKey;   // 'TF', 'GC', etc.
  final String islandLabel; // 'Tenerife', etc.
  final String? zoneKey;
  final String? zoneLabel;
  final String? municipalityId;
  final String? municipalityLabel;
  final String? categoryId;
  final String? categoryLabel;

  const NewHomeFiltersState({
    required this.islandId,
    required this.islandKey,
    required this.islandLabel,
    this.zoneKey,
    this.zoneLabel,
    this.municipalityId,
    this.municipalityLabel,
    this.categoryId,
    this.categoryLabel,
  });

  NewHomeFiltersState copyWith({
    String? islandId,
    String? islandKey,
    String? islandLabel,
    String? zoneKey,
    String? zoneLabel,
    bool clearZone = false,
    String? municipalityId,
    String? municipalityLabel,
    bool clearMunicipality = false,
    String? categoryId,
    String? categoryLabel,
    bool clearCategory = false,
  }) {
    return NewHomeFiltersState(
      islandId: islandId ?? this.islandId,
      islandKey: islandKey ?? this.islandKey,
      islandLabel: islandLabel ?? this.islandLabel,
      zoneKey: clearZone ? null : (zoneKey ?? this.zoneKey),
      zoneLabel: clearZone ? null : (zoneLabel ?? this.zoneLabel),
      municipalityId: clearMunicipality ? null : (municipalityId ?? this.municipalityId),
      municipalityLabel: clearMunicipality ? null : (municipalityLabel ?? this.municipalityLabel),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryLabel: clearCategory ? null : (categoryLabel ?? this.categoryLabel),
    );
  }

  /// Tenerife por defecto
  static const initial = NewHomeFiltersState(
    islandId: '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d',
    islandKey: 'TF',
    islandLabel: 'Tenerife',
  );
}

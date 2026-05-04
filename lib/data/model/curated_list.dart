import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

/// Recopilatorio editorial: "Los mejores X de Y".
class CuratedList {
  final String id;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? heroAsset;
  final String? heroEmoji;
  final int count;
  final String location;
  final Color accent;
  final String? islandId;
  final int position;
  final bool enabled;

  const CuratedList({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.heroAsset,
    this.heroEmoji,
    required this.count,
    required this.location,
    required this.accent,
    this.islandId,
    this.position = 0,
    this.enabled = true,
  });

  factory CuratedList.fromJson(Map<String, dynamic> json) {
    return CuratedList(
      id: json['id'] as String,
      eyebrow: (json['eyebrow'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      heroAsset: json['heroAsset'] as String?,
      heroEmoji: json['heroEmoji'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
      location: (json['location'] ?? '') as String,
      accent: _parseHexColor(json['accent'] as String?) ?? AppColors.atlantico,
      islandId: json['islandId'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class CuratedListItem {
  final String restaurantId;
  final int position;
  final String? note;
  final CuratedListItemRestaurant? restaurant;

  const CuratedListItem({
    required this.restaurantId,
    required this.position,
    this.note,
    this.restaurant,
  });

  factory CuratedListItem.fromJson(Map<String, dynamic> json) {
    final r = json['restaurant'];
    return CuratedListItem(
      restaurantId: json['restaurantId'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      restaurant: r is Map<String, dynamic>
          ? CuratedListItemRestaurant.fromJson(r)
          : null,
    );
  }
}

class CuratedListItemRestaurant {
  final String id;
  final String nombre;
  final String? mainFoto;
  final String? municipio;

  const CuratedListItemRestaurant({
    required this.id,
    required this.nombre,
    this.mainFoto,
    this.municipio,
  });

  factory CuratedListItemRestaurant.fromJson(Map<String, dynamic> json) {
    String? municipio;
    final m = json['municipio'] ?? json['municipios'];
    if (m is String) {
      municipio = m;
    } else if (m is Map && m['Nombre'] is String) {
      municipio = m['Nombre'] as String;
    } else if (m is Map && m['nombre'] is String) {
      municipio = m['nombre'] as String;
    }
    return CuratedListItemRestaurant(
      id: json['id'] as String,
      nombre: (json['nombre'] ?? '') as String,
      mainFoto: json['mainFoto'] as String?,
      municipio: municipio,
    );
  }
}

class CuratedListDetail extends CuratedList {
  final List<CuratedListItem> items;

  const CuratedListDetail({
    required super.id,
    required super.eyebrow,
    required super.title,
    required super.subtitle,
    super.heroAsset,
    super.heroEmoji,
    required super.count,
    required super.location,
    required super.accent,
    super.islandId,
    super.position,
    super.enabled,
    required this.items,
  });

  factory CuratedListDetail.fromJson(Map<String, dynamic> json) {
    final base = CuratedList.fromJson(json);
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(CuratedListItem.fromJson)
            .toList()
        : <CuratedListItem>[];
    return CuratedListDetail(
      id: base.id,
      eyebrow: base.eyebrow,
      title: base.title,
      subtitle: base.subtitle,
      heroAsset: base.heroAsset,
      heroEmoji: base.heroEmoji,
      count: base.count,
      location: base.location,
      accent: base.accent,
      islandId: base.islandId,
      position: base.position,
      enabled: base.enabled,
      items: items,
    );
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var v = hex.replaceFirst('#', '').trim();
  if (v.length == 6) v = 'FF$v';
  final parsed = int.tryParse(v, radix: 16);
  return parsed == null ? null : Color(parsed);
}

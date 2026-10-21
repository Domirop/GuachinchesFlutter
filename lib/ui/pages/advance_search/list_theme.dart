import 'package:flutter/material.dart';
import 'package:guachinches/utils/contextual_pool.dart';

/// Temas de las listas de resultados (Sistema §08 «Listas temáticas»): cada
/// tipo y cada franja horaria cambia solo la banda, la tinta del antetítulo,
/// el glifo y los textos. El azul Atlántico sigue siendo el único color de
/// acción.
enum ListThemeKind {
  bar,
  tradicional,
  moderno,
  tasca,
  bodegon,
  cofradia,
  restaurante,
  lounge,
  experiencia,
  mercado,
  desayuno,
  almuerzo,
  golden,
  cena,
  madrugada,
  categoria,
  buscar,
}

/// Glifo de cada tema (lo pinta [ListThemeGlyph]).
enum ListGlyph {
  restaurante,
  bar,
  moderno,
  tradicional,
  tasca,
  bodegon,
  cofradia,
  mercado,
  lounge,
  experiencia,
  sol,
  luna,
  buscar,
}

class ListTheme {
  final ListThemeKind kind;
  final ListGlyph glyph;

  /// Banda de cabecera (día / noche).
  final Color bandDay;
  final Color bandNight;

  /// Tinta del antetítulo (día / noche). AA sobre su banda.
  final Color inkDay;
  final Color inkNight;

  /// Tinte de la loseta «Explorar por tipo» y del hueco sin foto.
  final Color tintDay;
  final Color tintNight;

  /// Título de cabecera y subtítulo.
  final String title;
  final String subtitle;

  /// Línea del estado vacío.
  final String emptyLine;

  /// «Ninguna cafetería» / «Ningún guachinche» / «Nada».
  final String none;

  /// Concordancia de «abierta/abierto» para el vacío.
  final bool feminine;

  /// Sustantivo plural para «15 cafeterías más…» y la carga.
  final String noun;

  /// Título de la sección de resultados («Guachinches», «Cafeterías
  /// abiertas»…).
  final String sectionTitle;

  const ListTheme({
    required this.kind,
    required this.glyph,
    required this.bandDay,
    required this.bandNight,
    required this.inkDay,
    required this.inkNight,
    required this.tintDay,
    required this.tintNight,
    required this.title,
    required this.subtitle,
    required this.emptyLine,
    required this.none,
    required this.noun,
    required this.sectionTitle,
    this.feminine = false,
  });

  Color band(bool dark) => dark ? bandNight : bandDay;
  Color ink(bool dark) => dark ? inkNight : inkDay;
  Color tint(bool dark) => dark ? tintNight : tintDay;

  bool get isContext =>
      kind == ListThemeKind.desayuno ||
      kind == ListThemeKind.almuerzo ||
      kind == ListThemeKind.golden ||
      kind == ListThemeKind.cena ||
      kind == ListThemeKind.madrugada;

  bool get isType => !isContext &&
      kind != ListThemeKind.buscar &&
      kind != ListThemeKind.categoria;

  ListTheme copyWith({String? title, String? subtitle, String? sectionTitle}) =>
      ListTheme(
        kind: kind,
        glyph: glyph,
        bandDay: bandDay,
        bandNight: bandNight,
        inkDay: inkDay,
        inkNight: inkNight,
        tintDay: tintDay,
        tintNight: tintNight,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        emptyLine: emptyLine,
        none: none,
        noun: noun,
        sectionTitle: sectionTitle ?? this.sectionTitle,
        feminine: feminine,
      );
}

/// Tokens del Sistema §08 (banda, tinta, textos) y tintes de las losetas.
const kListThemes = <ListThemeKind, ListTheme>{
  ListThemeKind.bar: ListTheme(
    kind: ListThemeKind.bar,
    glyph: ListGlyph.bar,
    bandDay: Color(0xFFF3E6D6),
    bandNight: Color(0xFF231A14),
    inkDay: Color(0xFF8A5A3A),
    inkNight: Color(0xFFD9A25E),
    tintDay: Color(0xFFF3E6D6),
    tintNight: Color(0x33D9A25E),
    title: 'Bar/Cafetería',
    subtitle: 'Cortado, barraquito y algo para picar.',
    emptyLine: 'Quita uno y seguimos.',
    none: 'Ninguna cafetería',
    feminine: true,
    noun: 'cafeterías',
    sectionTitle: 'Cafeterías',
  ),
  ListThemeKind.tradicional: ListTheme(
    kind: ListThemeKind.tradicional,
    glyph: ListGlyph.tradicional,
    bandDay: Color(0xFFF3DCDF),
    bandNight: Color(0xFF25141A),
    inkDay: Color(0xFF7A1E2C),
    inkNight: Color(0xFFE6A3AE),
    tintDay: Color(0xFFF3DCDF),
    tintNight: Color(0x33E6A3AE),
    title: 'Guachinches tradicionales',
    subtitle: 'Vino de la casa y mantel de cuadros.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ningún guachinche',
    noun: 'guachinches',
    sectionTitle: 'Guachinches',
  ),
  ListThemeKind.moderno: ListTheme(
    kind: ListThemeKind.moderno,
    glyph: ListGlyph.moderno,
    bandDay: Color(0xFFF1E7D2),
    bandNight: Color(0xFF241D12),
    inkDay: Color(0xFF7A5A20),
    inkNight: Color(0xFFE2C48A),
    tintDay: Color(0xFFF1E7D2),
    tintNight: Color(0x33E2C48A),
    title: 'Guachinches modernos',
    subtitle: 'Lo de siempre, con otra vuelta.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ningún guachinche moderno',
    noun: 'guachinches',
    sectionTitle: 'Guachinches modernos',
  ),
  ListThemeKind.tasca: ListTheme(
    kind: ListThemeKind.tasca,
    glyph: ListGlyph.tasca,
    bandDay: Color(0xFFF5E1D8),
    bandNight: Color(0xFF2A1914),
    inkDay: Color(0xFFA04A2A),
    inkNight: Color(0xFFF0A88C),
    tintDay: Color(0xFFF5E1D8),
    tintNight: Color(0x33F0A88C),
    title: 'Tascas',
    subtitle: 'Para ir picando.',
    emptyLine: 'Quita uno y seguimos.',
    none: 'Ninguna tasca',
    feminine: true,
    noun: 'tascas',
    sectionTitle: 'Tascas',
  ),
  ListThemeKind.bodegon: ListTheme(
    kind: ListThemeKind.bodegon,
    glyph: ListGlyph.bodegon,
    bandDay: Color(0xFFEFE3D6),
    bandNight: Color(0xFF221A14),
    inkDay: Color(0xFF6B4A2E),
    inkNight: Color(0xFFD2B08E),
    tintDay: Color(0xFFEFE3D6),
    tintNight: Color(0x33D2B08E),
    title: 'Bodegones',
    subtitle: 'Vino de barrica y mesa larga.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ningún bodegón',
    noun: 'bodegones',
    sectionTitle: 'Bodegones',
  ),
  ListThemeKind.cofradia: ListTheme(
    kind: ListThemeKind.cofradia,
    glyph: ListGlyph.cofradia,
    bandDay: Color(0xFFDDEFF1),
    bandNight: Color(0xFF0E1F25),
    inkDay: Color(0xFFA8432F),
    inkNight: Color(0xFFF2A08F),
    tintDay: Color(0xFFDDEFF1),
    tintNight: Color(0x380B6F7A),
    title: 'Cofradías',
    subtitle: 'Pescado del día, del barco al plato.',
    emptyLine: 'El mar no se acaba: prueba otro.',
    none: 'Ninguna cofradía',
    feminine: true,
    noun: 'cofradías',
    sectionTitle: 'Dónde comer pescado',
  ),
  ListThemeKind.restaurante: ListTheme(
    kind: ListThemeKind.restaurante,
    glyph: ListGlyph.restaurante,
    bandDay: Color(0xFFEDE6DC),
    bandNight: Color(0xFF1E1B18),
    inkDay: Color(0xFF5A5248),
    inkNight: Color(0xFFC9C2B6),
    tintDay: Color(0xFFEDE6DC),
    tintNight: Color(0x29C9C2B6),
    title: 'Restaurantes',
    subtitle: 'Mantel, carta y sobremesa.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ningún restaurante',
    noun: 'restaurantes',
    sectionTitle: 'Restaurantes',
  ),
  ListThemeKind.lounge: ListTheme(
    kind: ListThemeKind.lounge,
    glyph: ListGlyph.lounge,
    bandDay: Color(0xFFE6E4F3),
    bandNight: Color(0xFF1A1830),
    inkDay: Color(0xFF4B4796),
    inkNight: Color(0xFFB9B6EE),
    tintDay: Color(0xFFE6E4F3),
    tintNight: Color(0x33B9B6EE),
    title: 'Lounge',
    subtitle: 'Copas, música y buen rato.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ningún lounge',
    noun: 'lounges',
    sectionTitle: 'Lounges',
  ),
  ListThemeKind.experiencia: ListTheme(
    kind: ListThemeKind.experiencia,
    glyph: ListGlyph.experiencia,
    bandDay: Color(0xFFF6E7D3),
    bandNight: Color(0xFF261C10),
    inkDay: Color(0xFF8A4F0C),
    inkNight: Color(0xFFE8B46A),
    tintDay: Color(0xFFF6E7D3),
    tintNight: Color(0x33E8B46A),
    title: 'Experiencias',
    subtitle: 'Algo distinto que contar.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ninguna experiencia',
    feminine: true,
    noun: 'experiencias',
    sectionTitle: 'Experiencias',
  ),
  ListThemeKind.mercado: ListTheme(
    kind: ListThemeKind.mercado,
    glyph: ListGlyph.mercado,
    bandDay: Color(0xFFE5ECDA),
    bandNight: Color(0xFF182014),
    inkDay: Color(0xFF4E6B24),
    inkNight: Color(0xFFB7CC92),
    tintDay: Color(0xFFE5ECDA),
    tintNight: Color(0x33B7CC92),
    title: 'Mercados',
    subtitle: 'Puestos, producto y algo para picar.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ningún mercado',
    noun: 'mercados',
    sectionTitle: 'Mercados',
  ),
  ListThemeKind.desayuno: ListTheme(
    kind: ListThemeKind.desayuno,
    glyph: ListGlyph.bar,
    bandDay: Color(0xFFF3E6D6),
    bandNight: Color(0xFF231A14),
    inkDay: Color(0xFF8A5A3A),
    inkNight: Color(0xFFD9A25E),
    tintDay: Color(0xFFF3E6D6),
    tintNight: Color(0x33D9A25E),
    title: 'Para desayunar',
    subtitle: 'Barraquito, bocadillo y a currar.',
    emptyLine: 'El café se toma igual de bien sin columpios. Prueba a quitar '
        'el filtro.',
    none: 'Ninguna cafetería',
    feminine: true,
    noun: 'cafeterías',
    sectionTitle: 'Cafeterías abiertas',
  ),
  ListThemeKind.almuerzo: ListTheme(
    kind: ListThemeKind.almuerzo,
    glyph: ListGlyph.restaurante,
    bandDay: Color(0xFFEDE6DC),
    bandNight: Color(0xFF1E1B18),
    inkDay: Color(0xFF5A5248),
    inkNight: Color(0xFFC9C2B6),
    tintDay: Color(0xFFEDE6DC),
    tintNight: Color(0x29C9C2B6),
    title: 'Para almorzar',
    subtitle: 'Restaurantes, tascas, bodegones y guachinches.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Nada',
    noun: 'sitios',
    sectionTitle: 'Sitios para almorzar',
  ),
  ListThemeKind.golden: ListTheme(
    kind: ListThemeKind.golden,
    glyph: ListGlyph.sol,
    bandDay: Color(0xFFF8E3D6),
    bandNight: Color(0xFF2A1A14),
    inkDay: Color(0xFFA23E1C),
    inkNight: Color(0xFFF2B48A),
    tintDay: Color(0xFFF8E3D6),
    tintNight: Color(0x33F2B48A),
    title: 'Terrazas al atardecer',
    subtitle: 'Con vistas y algo fresquito.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Ninguna terraza',
    feminine: true,
    noun: 'terrazas',
    sectionTitle: 'Terrazas abiertas',
  ),
  ListThemeKind.cena: ListTheme(
    kind: ListThemeKind.cena,
    glyph: ListGlyph.luna,
    bandDay: Color(0xFFE2E8F3),
    bandNight: Color(0xFF141A2C),
    inkDay: Color(0xFF2F4F8A),
    inkNight: Color(0xFFA9B8E8),
    tintDay: Color(0xFFE2E8F3),
    tintNight: Color(0x33A9B8E8),
    title: 'Para cenar',
    subtitle: 'Mesa para esta noche.',
    emptyLine: 'Prueba a quitar alguno.',
    none: 'Nada',
    noun: 'sitios',
    sectionTitle: 'Sitios para cenar',
  ),
  ListThemeKind.madrugada: ListTheme(
    kind: ListThemeKind.madrugada,
    glyph: ListGlyph.luna,
    bandDay: Color(0xFFE4E2EE),
    bandNight: Color(0xFF1E1830),
    inkDay: Color(0xFF3F3A6E),
    inkNight: Color(0xFFC9A0F0),
    tintDay: Color(0xFFE4E2EE),
    tintNight: Color(0x33C9A0F0),
    title: 'Abiertos de madrugada',
    subtitle: 'Lo que queda abierto a estas horas.',
    emptyLine: 'A estas horas no encontramos nada abierto.',
    none: 'Nada',
    noun: 'sitios',
    sectionTitle: 'Abiertos ahora',
  ),
  ListThemeKind.categoria: ListTheme(
    kind: ListThemeKind.categoria,
    glyph: ListGlyph.buscar,
    bandDay: Color(0xFFEFE4CD),
    bandNight: Color(0xFF0F1C25),
    inkDay: Color(0xFF7A5A20),
    inkNight: Color(0xFFC9A96B),
    tintDay: Color(0xFFEFE4CD),
    tintNight: Color(0x33C9A96B),
    title: 'Buscar',
    subtitle: 'Nombre, zona o plato.',
    emptyLine: 'Prueba con otra búsqueda o quita filtros.',
    none: 'Ningún sitio',
    noun: 'sitios',
    sectionTitle: 'Resultados',
  ),
  ListThemeKind.buscar: ListTheme(
    kind: ListThemeKind.buscar,
    glyph: ListGlyph.buscar,
    bandDay: Color(0xFFF8F4EC),
    bandNight: Color(0xFF0A141B),
    inkDay: Color(0xFF6E6253),
    inkNight: Color(0xA3F3EEE4),
    tintDay: Color(0xFFEFE4CD),
    tintNight: Color(0x14C8E1F5),
    title: 'Buscar',
    subtitle: 'Nombre, zona o plato.',
    emptyLine: 'Prueba con otra búsqueda o quita filtros.',
    none: 'Ningún sitio',
    noun: 'sitios',
    sectionTitle: 'Resultados',
  ),
};

/// Tema de un tipo de local por id (o, si el id no es de los conocidos, por
/// el nombre). `null` si no se reconoce.
ListThemeKind? listThemeForType(String id, String name) {
  switch (id) {
    case RestaurantTypeIds.barCafeteria:
      return ListThemeKind.bar;
    case RestaurantTypeIds.guachinchesTradicionales:
      return ListThemeKind.tradicional;
    case RestaurantTypeIds.guachinchesModernos:
      return ListThemeKind.moderno;
    case RestaurantTypeIds.tascas:
      return ListThemeKind.tasca;
    case RestaurantTypeIds.bodegones:
      return ListThemeKind.bodegon;
    case RestaurantTypeIds.cofradia:
      return ListThemeKind.cofradia;
    case RestaurantTypeIds.restaurantes:
      return ListThemeKind.restaurante;
    case RestaurantTypeIds.loungeTenerife:
      return ListThemeKind.lounge;
  }
  final n = name.toLowerCase();
  if (n.contains('cafeter') || n.startsWith('bar')) return ListThemeKind.bar;
  if (n.contains('tradicional')) return ListThemeKind.tradicional;
  if (n.contains('moderno')) return ListThemeKind.moderno;
  if (n.contains('tasca')) return ListThemeKind.tasca;
  if (n.contains('bodeg')) return ListThemeKind.bodegon;
  if (n.contains('cofrad')) return ListThemeKind.cofradia;
  if (n.contains('restaurante')) return ListThemeKind.restaurante;
  if (n.contains('lounge')) return ListThemeKind.lounge;
  if (n.contains('experien')) return ListThemeKind.experiencia;
  if (n.contains('mercado')) return ListThemeKind.mercado;
  return null;
}

/// Franja horaria de la lista abierta desde «Hoy» (mismas horas que
/// `contextualFilterFor`).
ListThemeKind contextThemeForHour(int hour) {
  if (hour >= 7 && hour <= 11) return ListThemeKind.desayuno;
  if (hour >= 12 && hour <= 16) return ListThemeKind.almuerzo;
  if (hour >= 17 && hour <= 19) return ListThemeKind.golden;
  if (hour >= 20) return ListThemeKind.cena;
  return ListThemeKind.madrugada;
}

/// Antetítulo de cabecera de la franja («Bar/Cafetería · de 7:00 a 11:00»).
String contextEyebrow(ListThemeKind k) {
  switch (k) {
    case ListThemeKind.desayuno:
      return 'Bar/Cafetería · de 7:00 a 11:00';
    case ListThemeKind.almuerzo:
      return 'Hora del almuerzo · de 12:00 a 16:00';
    case ListThemeKind.golden:
      return 'Terraza y vistas · de 17:00 a 19:00';
    case ListThemeKind.cena:
      return 'Hora de la cena · de 20:00 a 23:00';
    case ListThemeKind.madrugada:
      return 'De madrugada · de 0:00 a 6:00';
    default:
      return '';
  }
}

/// Subtítulo del desayuno según el día: entre semana «a currar»; sábado y
/// domingo, sin prisa.
String breakfastSubtitle(DateTime now) {
  if (now.weekday == DateTime.saturday) {
    return 'Barraquito, bocadillo y sin prisa, que es sábado.';
  }
  if (now.weekday == DateTime.sunday) {
    return 'Barraquito, bocadillo y sin prisa, que es domingo.';
  }
  return 'Barraquito, bocadillo y a currar.';
}

/// Tinte de loseta «Explorar por tipo» (día) — también vale de fondo de
/// las tarjetas sin foto.
Color listTint(ListThemeKind k, bool dark) =>
    (kListThemes[k] ?? kListThemes[ListThemeKind.buscar]!).tint(dark);

/// Cabeceras animadas (tableros MotionCuarta y MotionDesayuno).
enum HeaderSceneKind { mesaBrindis, barraquito }

/// Qué escena lleva la cabecera de cada tema: la mesa con brindis en
/// «Guachinches tradicionales» y el barraquito en «Para desayunar» (franja
/// 7–11 desde «Hoy») y en «Bar/Cafetería». El resto, banda quieta.
HeaderSceneKind? headerSceneFor(ListThemeKind kind) {
  switch (kind) {
    case ListThemeKind.tradicional:
      return HeaderSceneKind.mesaBrindis;
    case ListThemeKind.desayuno:
    case ListThemeKind.bar:
      return HeaderSceneKind.barraquito;
    default:
      return null;
  }
}

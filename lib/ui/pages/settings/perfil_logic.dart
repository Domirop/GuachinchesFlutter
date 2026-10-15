/// Lógica pura de la pestaña Perfil (tablero TabPerfil) y de Mi cuenta
/// (tablero PerfilMiCuenta). Sin Flutter: se prueba con `flutter_test`.
library;

/// Con qué se inició sesión (se guarda en el móvil al entrar).
enum PerfilProvider { google, apple, email }

/// `'google'` / `'apple'` / `'email'` → proveedor; cualquier otra cosa → null
/// (sesiones de antes de guardar el proveedor: la línea no se pinta).
PerfilProvider? perfilProviderFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'google':
      return PerfilProvider.google;
    case 'apple':
      return PerfilProvider.apple;
    case 'email':
      return PerfilProvider.email;
  }
  return null;
}

/// «Has entrado con Google» (tarjeta de identidad).
String perfilProviderLine(PerfilProvider p) => switch (p) {
      PerfilProvider.google => 'Has entrado con Google',
      PerfilProvider.apple => 'Has entrado con Apple',
      PerfilProvider.email => 'Has entrado con email',
    };

/// Nombre a mostrar: el del backend y, si viene vacío, el guardado en el
/// móvil. Solo el nombre de pila (los apellidos ya no llegan, backend 042).
String perfilDisplayName(String backendName, String? cachedName) {
  final b = backendName.trim();
  if (b.isNotEmpty) return b;
  return cachedName?.trim() ?? '';
}

/// Inicial del avatar: del nombre y, si no hay, del email. Vacío si no hay
/// ninguno (el avatar pinta entonces el icono de persona).
String perfilInitial(String name, String? email) {
  for (final s in [name, email ?? '']) {
    final t = s.trim();
    // Primer carácter: los nombres no empiezan por grafemas compuestos.
    if (t.isNotEmpty) return t.substring(0, 1).toUpperCase();
  }
  return '';
}

/// Nota de una reseña (`"4"`, `"4.0"`) → 1..5, o null si no es válida.
int? perfilStars(String raw) {
  final v = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (v == null || v <= 0) return null;
  return v.round().clamp(1, 5);
}

/// Media de las notas válidas, o null si no hay ninguna.
double? perfilAverage(Iterable<String> ratings) {
  var sum = 0.0;
  var n = 0;
  for (final r in ratings) {
    final v = double.tryParse(r.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) continue;
    sum += v.clamp(1, 5);
    n++;
  }
  return n == 0 ? null : sum / n;
}

/// `4.5` → «4,5».
String perfilFormatAvg(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Subtítulo de «Mis reseñas»: «4 reseñas · media 4,5».
String perfilReviewsSummary(int count, double? avg) {
  if (count <= 0) return 'Aún no has escrito ninguna';
  final n = count == 1 ? '1 reseña' : '$count reseñas';
  return avg == null ? n : '$n · media ${perfilFormatAvg(avg)}';
}

/// Subtítulo de «Guardados»: «5 sitios en este móvil».
String perfilSavedSummary(int count) {
  if (count <= 0) return 'Aún no has guardado ningún sitio';
  return count == 1 ? '1 sitio en este móvil' : '$count sitios en este móvil';
}

/// «Dónde Comer Canarias 4.6.0» con la versión instalada (`package_info_plus`,
/// sin el número de compilación). Si no se ha podido leer, sin versión.
String perfilVersionLabel(String? version) {
  final v = (version ?? '').split('+').first.trim();
  return v.isEmpty ? 'Dónde Comer Canarias' : 'Dónde Comer Canarias $v';
}

// ── Eliminación de cuenta ───────────────────────────────────────────────────

/// Plazo que da el backend para arrepentirse (migration-backend/018).
const Duration kPerfilDeletionGrace = Duration(days: 30);

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// «13/11/2026».
String perfilDateShort(DateTime d) {
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

/// «13 de noviembre» o, con [withYear], «13 de noviembre de 2026».
String perfilDateLong(DateTime d, {bool withYear = false}) {
  final l = d.toLocal();
  final s = '${l.day} de ${_months[l.month - 1]}';
  return withYear ? '$s de ${l.year}' : s;
}

/// Día en que se pidió la eliminación (fecha programada − 30 días).
DateTime perfilDeletionRequestedAt(DateTime scheduledAt) =>
    scheduledAt.subtract(kPerfilDeletionGrace);

/// La eliminación sigue pendiente (fecha en el futuro).
bool perfilDeletionActive(DateTime? scheduledAt, DateTime now) =>
    scheduledAt != null && scheduledAt.isAfter(now);

/// Días naturales que faltan (0 si ya pasó).
int perfilDaysLeft(DateTime scheduledAt, DateTime now) {
  final a = DateTime(now.year, now.month, now.day);
  final l = scheduledAt.toLocal();
  final b = DateTime(l.year, l.month, l.day);
  final d = b.difference(a).inDays;
  return d < 0 ? 0 : d;
}

/// «Quedan 30 días.» / «Queda 1 día.» / «Se elimina hoy.»
String perfilDaysLeftText(int days) {
  if (days <= 0) return 'Se elimina hoy.';
  return days == 1 ? 'Queda 1 día.' : 'Quedan $days días.';
}

// ── Copy de las hojas ───────────────────────────────────────────────────────

/// Texto de la hoja «¿Cerrar sesión?» (Apple solo se ofrece en iOS).
String perfilLogoutText({required bool apple}) =>
    'Tus reseñas siguen en tu cuenta y tus guardados se quedan en este móvil. '
    'Para volver, entra con ${apple ? 'Apple, Google o tu email' : 'Google o tu email'}.';

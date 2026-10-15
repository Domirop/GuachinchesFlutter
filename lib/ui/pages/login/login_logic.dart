import 'dart:async';
import 'dart:io' show SocketException;

import 'package:guachinches/ui/pages/settings/perfil_logic.dart'
    show perfilDateLong;
import 'package:http/http.dart' show ClientException;

/// Lógica pura del acceso único (tablero AltLogin, variante A «Arena y
/// logo», más los estados del tablero Login): copy, validación, errores por
/// proveedor y lectura de la respuesta del backend. Sin Flutter.

// ── Tipos ───────────────────────────────────────────────────────────────────

/// Cómo se entra. Email solo para cuentas creadas antes de mayo de 2026;
/// las cuentas nuevas se crean con Apple o Google.
enum LoginMethod { apple, google, email }

/// Por qué falló un intento. `cancelled` no es un error (no se avisa).
enum LoginFailure { cancelled, credentials, network, unknown }

/// Paso visible del acceso.
enum LoginStep { main, email, recover }

/// Qué estaba haciendo el usuario cuando se le pidió entrar (pinta el chip
/// de contexto encima del título).
enum LoginReasonKind { profile, onboarding, save, review, report, quiz }

class LoginReason {
  final LoginReasonKind kind;

  /// Sitio implicado (solo «guardar»).
  final String? placeName;

  const LoginReason._(this.kind, [this.placeName]);

  /// Desde el Perfil o «Ya tengo cuenta»: sin chip.
  static const profile = LoginReason._(LoginReasonKind.profile);
  static const onboarding = LoginReason._(LoginReasonKind.onboarding);
  static const review = LoginReason._(LoginReasonKind.review);
  static const report = LoginReason._(LoginReasonKind.report);
  static const quiz = LoginReason._(LoginReasonKind.quiz);

  /// «Para guardar Casa Ángela».
  factory LoginReason.save(String placeName) =>
      LoginReason._(LoginReasonKind.save, placeName);
}

/// Glifo del chip de contexto (el widget lo traduce a SVG).
enum LoginChipIcon { heart, pencil, flag, medal }

/// Sesión abierta tras entrar.
class LoginSession {
  final String userId;
  final LoginMethod method;
  final String? email;

  /// La cuenta tiene una eliminación programada (se pregunta si conservarla).
  final bool deletionPending;

  /// Fecha de la eliminación, si el backend la manda.
  final DateTime? deletionAt;

  const LoginSession({
    required this.userId,
    required this.method,
    this.email,
    this.deletionPending = false,
    this.deletionAt,
  });
}

/// Resultado de un intento: sesión o motivo del fallo.
class LoginOutcome {
  final LoginSession? session;
  final LoginFailure? failure;

  const LoginOutcome.success(LoginSession this.session) : failure = null;
  const LoginOutcome.failed(LoginFailure this.failure) : session = null;
  static const cancelled = LoginOutcome.failed(LoginFailure.cancelled);

  bool get ok => session != null;
}

// ── Copy ────────────────────────────────────────────────────────────────────

const String kLoginTitle = 'Entra o crea tu cuenta';
const String kLoginSubtitle = 'Guarda sitios, haz listas y escribe reseñas. '
    'Si aún no tienes cuenta, se crea sola.';
const String kLoginEmailEntry = 'Entrar con email y contraseña';
const String kLoginEmailNote =
    'Para cuentas creadas con email antes de mayo de 2026.';
const String kLoginEmailTitle = 'Entrar con email';
const String kLoginRecoverTitle = 'Recuperar la cuenta';
const String kLoginForgot = '¿Has olvidado la contraseña?';
const String kLoginSubmit = 'Iniciar sesión';
const String kLoginKeepAccount = 'Conservar mi cuenta';
const String kLoginSignOut = 'Cerrar sesión';
const String kLoginSupport = 'Escribir a soporte';
const String kLoginSupportSubject = 'Recuperar mi cuenta';

/// Chip de contexto; null = sin chip (Perfil, onboarding).
({LoginChipIcon icon, String text})? loginReasonChip(LoginReason? reason) {
  switch (reason?.kind) {
    case LoginReasonKind.save:
      final name = reason!.placeName?.trim() ?? '';
      return (
        icon: LoginChipIcon.heart,
        text: name.isEmpty ? 'Para guardar este sitio' : 'Para guardar $name',
      );
    case LoginReasonKind.review:
      return (icon: LoginChipIcon.pencil, text: 'Para escribir tu reseña');
    case LoginReasonKind.report:
      return (icon: LoginChipIcon.flag, text: 'Para reportar la reseña');
    case LoginReasonKind.quiz:
      return (icon: LoginChipIcon.medal, text: 'Para jugar al quiz');
    case LoginReasonKind.profile:
    case LoginReasonKind.onboarding:
    case null:
      return null;
  }
}

String loginProviderName(LoginMethod m) => switch (m) {
      LoginMethod.apple => 'Apple',
      LoginMethod.google => 'Google',
      LoginMethod.email => 'email',
    };

/// Botones de proveedor: «Continuar con Apple» / «Conectando con Apple…».
String loginProviderLabel(LoginMethod m, {bool loading = false}) =>
    loading ? loginLoadingLabel(m) : 'Continuar con ${loginProviderName(m)}';

/// Texto mientras se entra.
String loginLoadingLabel(LoginMethod m) => switch (m) {
      LoginMethod.email => 'Entrando…',
      _ => 'Conectando con ${loginProviderName(m)}…',
    };

/// Aviso de error (título, texto). Email y proveedores tienen copy propio:
/// un fallo de Google o Apple nunca dice «email o contraseña».
(String, String)? loginErrorCopy(LoginMethod method, LoginFailure failure) {
  if (failure == LoginFailure.cancelled) return null;
  if (method == LoginMethod.email) {
    return switch (failure) {
      LoginFailure.credentials => (
          'No hemos podido entrar',
          'El email o la contraseña no coinciden. Revísalos o recupera la '
              'contraseña.',
        ),
      LoginFailure.network => (
          'No hemos podido entrar',
          'Parece que no hay conexión. Revísala e inténtalo otra vez.',
        ),
      _ => (
          'No hemos podido entrar',
          'Algo ha fallado por nuestra parte. Inténtalo otra vez en un '
              'momento.',
        ),
    };
  }
  final title = 'No hemos podido conectar con ${loginProviderName(method)}';
  return switch (failure) {
    LoginFailure.network => (
        title,
        'Parece que no hay conexión. Revísala e inténtalo otra vez.',
      ),
    _ => (
        title,
        'Puede que hayas cancelado o que falle la conexión. Inténtalo otra '
            'vez.',
      ),
  };
}

/// Pie del paso email: las cuentas nuevas se crean con Apple / Google.
String loginNoAccountLead({required bool appleAvailable}) => appleAvailable
    ? '¿Aún no tienes cuenta? Créala con Apple o Google: '
    : '¿Aún no tienes cuenta? Créala con Google: ';

/// «Recuperar la cuenta»: el backend enlaza por email verificado, así que
/// entrar con Google/Apple con el mismo email recupera la cuenta.
/// Devuelve (antes, en negrita, después).
(String, String, String) loginRecoverLead({required bool appleAvailable}) => (
      'Entra con ',
      appleAvailable
          ? 'Google o Apple usando el mismo email'
          : 'Google usando el mismo email',
      ' de tu cuenta y la recuperas con todo lo que tenías guardado. Sin '
          'contraseñas.',
    );

/// Tarjeta «¿Tu cuenta usa otro email?» (negrita, resto).
(String, String) loginRecoverSupport({required bool appleAvailable}) => (
      '¿Tu cuenta usa otro email?',
      appleAvailable
          ? 'O usas «Ocultar mi email» de Apple. Escríbenos y la recuperamos '
              'a mano.'
          : 'Escríbenos y la recuperamos a mano.',
    );

/// Aviso de eliminación pendiente (título, texto).
(String, String) loginDeletionCopy(DateTime? at, DateTime now) {
  const text = 'Pediste eliminarla. Si la conservas, todo sigue como estaba: '
      'guardados, listas y reseñas.';
  if (at != null && at.isAfter(now)) {
    return ('Tu cuenta se eliminará el ${perfilDateLong(at)}', text);
  }
  return ('Tu cuenta está pendiente de eliminación', text);
}

// ── Validación ──────────────────────────────────────────────────────────────

final _emailRe = RegExp(r"^[\w.!#$%&'*+\-/=?^`{|}~]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$");

bool loginEmailLooksValid(String email) => _emailRe.hasMatch(email.trim());

/// «Iniciar sesión» se habilita con un email con forma de email y una
/// contraseña no vacía.
bool loginCanSubmit(String email, String password) =>
    loginEmailLooksValid(email) && password.isNotEmpty;

// ── Respuesta del backend ───────────────────────────────────────────────────

/// `deletionPending: true` o una `deletionScheduledAt` en el futuro.
bool loginDeletionPending(Map<String, dynamic> response, DateTime now) {
  if (response['deletionPending'] == true) return true;
  final at = loginDeletionAt(response);
  return at != null && at.isAfter(now);
}

DateTime? loginDeletionAt(Map<String, dynamic> response) {
  final raw = response['deletionScheduledAt'];
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

/// Clasifica una excepción del login con email. `loginUser` lanza `Error()`
/// cuando el backend responde 400 (credenciales).
LoginFailure loginClassifyEmailError(Object e) {
  if (_isNetwork(e)) return LoginFailure.network;
  if (e.runtimeType == Error) return LoginFailure.credentials;
  return LoginFailure.unknown;
}

/// Clasifica una excepción de Google / Apple (código de plataforma si lo hay).
LoginFailure loginClassifyProviderError(Object e, {String? platformCode}) {
  final code = platformCode?.toLowerCase() ?? '';
  if (code.contains('cancel')) return LoginFailure.cancelled;
  if (code.contains('network') || _isNetwork(e)) return LoginFailure.network;
  return LoginFailure.unknown;
}

bool _isNetwork(Object e) =>
    e is SocketException || e is TimeoutException || e is ClientException;

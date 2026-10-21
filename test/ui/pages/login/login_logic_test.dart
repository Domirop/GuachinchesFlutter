import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:http/http.dart' show ClientException;

void main() {
  group('validación del email', () {
    test('acepta emails con forma de email', () {
      expect(loginEmailLooksValid('ana@ejemplo.com'), isTrue);
      expect(loginEmailLooksValid('  ana.p+dcc@mail.ejemplo.es  '), isTrue);
    });

    test('rechaza lo que no es un email', () {
      expect(loginEmailLooksValid(''), isFalse);
      expect(loginEmailLooksValid('ana'), isFalse);
      expect(loginEmailLooksValid('ana@'), isFalse);
      expect(loginEmailLooksValid('ana@ejemplo'), isFalse);
      expect(loginEmailLooksValid('ana ejemplo@mail.com'), isFalse);
    });

    test('«Iniciar sesión» solo con email válido y contraseña', () {
      expect(loginCanSubmit('ana@ejemplo.com', 'x'), isTrue);
      expect(loginCanSubmit('ana@ejemplo.com', ''), isFalse);
      expect(loginCanSubmit('ana', 'secreta'), isFalse);
    });
  });

  group('copy de error por proveedor', () {
    test('email: credenciales, red y otro', () {
      final (t, b) =
          loginErrorCopy(LoginMethod.email, LoginFailure.credentials)!;
      expect(t, 'No hemos podido entrar');
      expect(b, contains('El email o la contraseña no coinciden'));
      expect(loginErrorCopy(LoginMethod.email, LoginFailure.network)!.$2,
          contains('conexión'));
      expect(loginErrorCopy(LoginMethod.email, LoginFailure.unknown)!.$1,
          'No hemos podido entrar');
    });

    test('Google y Apple nunca hablan de email o contraseña', () {
      for (final m in [LoginMethod.google, LoginMethod.apple]) {
        for (final f in [
          LoginFailure.credentials,
          LoginFailure.network,
          LoginFailure.unknown,
        ]) {
          final (t, b) = loginErrorCopy(m, f)!;
          expect(t, 'No hemos podido conectar con ${loginProviderName(m)}');
          expect('$t $b'.toLowerCase(), isNot(contains('contraseña')));
          expect('$t $b'.toLowerCase(), isNot(contains('incorrect')));
        }
      }
      expect(loginErrorCopy(LoginMethod.google, LoginFailure.unknown)!.$2,
          'Puede que hayas cancelado o que falle la conexión. Inténtalo otra vez.');
    });

    test('cancelar no es un error', () {
      for (final m in LoginMethod.values) {
        expect(loginErrorCopy(m, LoginFailure.cancelled), isNull);
      }
    });

    test('textos de carga', () {
      expect(loginLoadingLabel(LoginMethod.email), 'Entrando…');
      expect(loginLoadingLabel(LoginMethod.google), 'Conectando con Google…');
      expect(loginLoadingLabel(LoginMethod.apple), 'Conectando con Apple…');
      expect(loginProviderLabel(LoginMethod.apple), 'Continuar con Apple');
      expect(loginProviderLabel(LoginMethod.google, loading: true),
          'Conectando con Google…');
    });
  });

  group('motivo → chip', () {
    test('sin chip desde el Perfil, el onboarding o sin motivo', () {
      expect(loginReasonChip(null), isNull);
      expect(loginReasonChip(LoginReason.profile), isNull);
      expect(loginReasonChip(LoginReason.onboarding), isNull);
    });

    test('guardar lleva el nombre del sitio', () {
      final chip = loginReasonChip(LoginReason.save('Casa Ángela'))!;
      expect(chip.text, 'Para guardar Casa Ángela');
      expect(chip.icon, LoginChipIcon.heart);
      expect(loginReasonChip(LoginReason.save('  '))!.text,
          'Para guardar este sitio');
    });

    test('reseña, reporte y quiz', () {
      expect(loginReasonChip(LoginReason.review)!.text,
          'Para escribir tu reseña');
      expect(loginReasonChip(LoginReason.report)!.text,
          'Para reportar la reseña');
      expect(loginReasonChip(LoginReason.quiz)!.text, 'Para jugar al quiz');
    });
  });

  group('recuperar la cuenta', () {
    test('con Apple (iOS) y sin Apple (Android)', () {
      expect(loginRecoverLead(appleAvailable: true).$2,
          'Google o Apple usando el mismo email');
      expect(loginRecoverLead(appleAvailable: false).$2,
          'Google usando el mismo email');
      expect(loginRecoverSupport(appleAvailable: true).$2,
          contains('Ocultar mi email'));
      expect(loginRecoverSupport(appleAvailable: false).$2,
          isNot(contains('Apple')));
      expect(loginNoAccountLead(appleAvailable: false),
          isNot(contains('Apple')));
    });
  });

  group('eliminación pendiente', () {
    final now = DateTime(2026, 10, 14, 12);

    test('con fecha en el futuro la nombra', () {
      final at = DateTime(2026, 11, 13, 12);
      expect(loginDeletionCopy(at, now).$1,
          'Tu cuenta se eliminará el 13 de noviembre');
      expect(loginDeletionCopy(at, now).$2, startsWith('Pediste eliminarla.'));
    });

    test('sin fecha (o pasada) no se inventa', () {
      expect(loginDeletionCopy(null, now).$1,
          'Tu cuenta está pendiente de eliminación');
      expect(loginDeletionCopy(DateTime(2026, 1, 1), now).$1,
          'Tu cuenta está pendiente de eliminación');
    });

    test('lectura de la respuesta del backend', () {
      expect(loginDeletionPending({'deletionPending': true}, now), isTrue);
      expect(
          loginDeletionPending(
              {'deletionScheduledAt': '2026-11-13T10:00:00.000Z'}, now),
          isTrue);
      expect(
          loginDeletionPending(
              {'deletionScheduledAt': '2025-11-13T10:00:00.000Z'}, now),
          isFalse);
      expect(loginDeletionPending({'id': 'u1'}, now), isFalse);
      expect(loginDeletionAt({'deletionScheduledAt': 'x'}), isNull);
      expect(loginDeletionAt({'deletionScheduledAt': '2026-11-13T10:00:00Z'}),
          DateTime.utc(2026, 11, 13, 10));
    });
  });

  group('clasificación de errores', () {
    test('email: 400 → credenciales; red → red; resto → desconocido', () {
      expect(loginClassifyEmailError(Error()), LoginFailure.credentials);
      expect(loginClassifyEmailError(const SocketException('offline')),
          LoginFailure.network);
      expect(loginClassifyEmailError(TimeoutException('lento')),
          LoginFailure.network);
      expect(loginClassifyEmailError(ClientException('x')),
          LoginFailure.network);
      expect(loginClassifyEmailError(const FormatException('html')),
          LoginFailure.unknown);
    });

    test('proveedores: cancelar, red y otros', () {
      expect(
          loginClassifyProviderError(Exception(),
              platformCode: 'sign_in_canceled'),
          LoginFailure.cancelled);
      expect(
          loginClassifyProviderError(Exception(),
              platformCode: 'network_error'),
          LoginFailure.network);
      expect(loginClassifyProviderError(const SocketException('x')),
          LoginFailure.network);
      expect(
          loginClassifyProviderError(Exception(),
              platformCode: 'sign_in_failed'),
          LoginFailure.unknown);
    });
  });
}

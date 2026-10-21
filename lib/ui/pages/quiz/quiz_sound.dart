import 'package:audioplayers/audioplayers.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/services/app_storage.dart';

/// Sonidos del juego. Inyectable para tests ([QuizGameScreen.audio]).
abstract class QuizAudio {
  /// Acierto.
  Future<void> correct();

  /// Fallo o tiempo agotado.
  Future<void> fail();

  /// Pito herreño de bienvenida: solo la PRIMERA vez que se abre el juego en
  /// este dispositivo (bandera local). Ya no hay intro forzada.
  Future<void> introIfFirstTime();

  void dispose();
}

/// Bandera local «ya sonó el pito».
abstract class QuizFlagStore {
  Future<bool> isSet(String key);
  Future<void> set(String key);
}

class SecureQuizFlagStore implements QuizFlagStore {
  const SecureQuizFlagStore();

  @override
  Future<bool> isSet(String key) async =>
      (await AppStorage.instance.read(key: key)) == '1';

  @override
  Future<void> set(String key) =>
      AppStorage.instance.write(key: key, value: '1');
}

/// Implementación real con `audioplayers`. Tolerante a fallos: si el audio no
/// puede sonar (permisos, formato), se registra y el juego sigue.
class QuizSound implements QuizAudio {
  static const introFlag = 'quiz_intro_played_v1';

  final QuizFlagStore flags;
  QuizSound({this.flags = const SecureQuizFlagStore()});

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer? _intro;

  @override
  Future<void> correct() => _play('audio/quiz-correct.mp3');

  @override
  Future<void> fail() => _play('audio/quiz-fail.mp3');

  @override
  Future<void> introIfFirstTime() async {
    try {
      if (await flags.isSet(introFlag)) return;
      await flags.set(introFlag);
      final p = _intro = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.play(AssetSource('audio/pito-herreno-intro.mp3'));
    } catch (e) {
      AppLogger.warn('quiz-sound', 'intro no disponible: $e');
    }
  }

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (e) {
      AppLogger.warn('quiz-sound', '$asset no disponible: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _intro?.dispose();
  }
}

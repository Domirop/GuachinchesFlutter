import 'package:audioplayers/audioplayers.dart';

/// Sonidos del juego (acierto / fallo). Tolerante a fallos: si el audio no
/// puede sonar (permisos, formato), no rompe el juego.
class QuizSound {
  final AudioPlayer _player = AudioPlayer();

  Future<void> correct() => _play('audio/quiz-correct.mp3');
  Future<void> fail() => _play('audio/quiz-fail.mp3');

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {/* silencio si no se puede reproducir */}
  }

  void dispose() => _player.dispose();
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Glifos propios del juego (rejilla 24, trazo 2, `currentColor`), copiados de
/// `tools/gen_quiz.py`. Candidatos a subir a `GmIcons` si otra pantalla los
/// necesita.
class QuizGlyphs {
  QuizGlyphs._();

  static const Map<String, String> paths = {
    // Categorías
    'brujula':
        '<circle cx="12" cy="12" r="8.5"/><path d="M15.2 8.8l-1.9 4.5-4.5 1.9 1.9-4.5z"/>',
    'timple':
        '<path d="M12 2.8v8.4M10.2 3.6h3.6M10.4 6h3.2"/><path d="M12 11.2c-3 0-4.8 1.7-4.8 4.5S9.2 21.2 12 21.2s4.8-2.7 4.8-5.5-1.8-4.5-4.8-4.5z"/><circle cx="12" cy="15.6" r="1.5"/>',
    'torre':
        '<path d="M6.5 21V9.5h11V21z"/><path d="M6.5 9.5V4.5h2.3v2h2.1v-2h2.2v2h2.1v-2h2.3v5"/><path d="M10.4 21v-3.6a1.6 1.6 0 013.2 0V21"/>',
    'pluma':
        '<path d="M19.8 4.2C12.6 4.6 8.2 9 7.4 16.6L5.2 20"/><path d="M19.8 4.2c-.4 6.4-4.6 10.6-11.2 11.4"/><path d="M12.4 11.6l-3.8.5"/>',
    'drago':
        '<path d="M12 21.2v-7.4M12 13.8l-3.6-3.2M12 13.8l3.6-3.2"/><path d="M3.4 10.4C4.6 6.6 8 4.4 12 4.4s7.4 2.2 8.6 6c-2.2-1.1-4.4-.6-5.2.4-1.2-1.5-5.6-1.5-6.8 0-.8-1-3-1.5-5.2-.4z"/>',
    'antifaz':
        '<path d="M2.8 8.8c3-1.6 6.2-1.6 9.2 0 3-1.6 6.2-1.6 9.2 0-.3 4.6-2.4 7.2-5.1 7.2-2.1 0-3.1-1.5-4.1-3-1 1.5-2 3-4.1 3-2.7 0-4.8-2.6-5.1-7.2z"/><circle cx="7.9" cy="11.6" r="1.3"/><circle cx="16.1" cy="11.6" r="1.3"/>',
    'balon':
        '<circle cx="12" cy="12" r="8.5"/><path d="M12 8.4l3.1 2.2-1.2 3.7h-3.8l-1.2-3.7z"/><path d="M12 3.6v4.8M15.1 10.6l4.3-1.4M13.9 14.3l2.6 3.8M10.1 14.3l-2.6 3.8M8.9 10.6L4.6 9.2"/>',
    // Interfaz del juego
    'ruleta':
        '<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5V12M12 12l6.6-5.3M12 12l8.3 1.9M12 12l3.7 7.7M12 12l-3.7 7.7M12 12l-8.3 1.9M12 12L5.4 6.7"/>',
    'quesito':
        '<path d="M12 12L12 3.5A8.5 8.5 0 0 1 20.2 9.8z"/><path d="M12 12l8.2-2.2A8.5 8.5 0 0 1 17.3 18.7z" opacity=".45"/><path d="M12 12L3.8 9.8A8.5 8.5 0 0 1 12 3.5z" opacity=".45"/>',
    'racha':
        '<path d="M12 21.2c-3.6 0-6-2.4-6-5.6 0-3.8 3.2-5.4 3.6-9.4 2.4 1.4 3.4 3.4 3.4 5.4 1-.6 1.6-1.6 1.8-2.8 1.8 1.6 3.2 3.8 3.2 6.6 0 3.4-2.4 5.8-6 5.8z"/>',
    'isla':
        '<path d="M3 19.5c1.5 1 3 1 4.5 0s3-1 4.5 0 3 1 4.5 0 3-1 4.5 0"/><path d="M5 16.2l4.6-8.4c.5-.9 1.5-.9 2 0l1.4 2.5 1.3-1.6c.5-.6 1.3-.5 1.7.2L19.5 16"/>',
    'bandera': '<path d="M6 21V3.5"/><path d="M6 4.5h11l-2.6 3.8L17 12H6"/>',
    'help':
        '<circle cx="12" cy="12" r="9"/><path d="M9.6 9.4a2.5 2.5 0 014.8.9c0 1.7-2.4 2.2-2.4 3.7"/><path d="M12 17.2v.1"/>',
    'clock': '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  };

  static String svg(String name, {double width = 2}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$width" stroke-linecap="round" '
      'stroke-linejoin="round">${paths[name] ?? paths['help']!}</svg>';
}

/// Un glifo de [QuizGlyphs] con su color.
class QuizGlyph extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final double strokeWidth;
  const QuizGlyph(this.name,
      {super.key, this.size = 18, required this.color, this.strokeWidth = 2});

  @override
  Widget build(BuildContext context) => GmIcon(
        QuizGlyphs.svg(name, width: strokeWidth),
        size: size,
        color: color,
      );
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
String _op(Color c) => c.a.toStringAsFixed(3);

/// Vino de la copa llena (día `#8C1F2E`, noche `#E0697E`).
Color quizWineLive(GmColors gm) =>
    gm.isDark ? const Color(0xFFE0697E) : const Color(0xFF8C1F2E);

/// Copa de vino = una vida. Llena: vino + trazo `label`; vacía: contorno
/// `label2` al 55 %.
class QuizCopa extends StatelessWidget {
  final bool full;
  final double size;
  const QuizCopa({super.key, required this.full, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final stroke = full ? gm.label : gm.label2;
    final body = full
        ? '<path d="M7.3 7.6h9.4l-.1.7a4.6 4.6 0 01-9.2 0z" fill="${_hex(quizWineLive(gm))}" stroke="none"/>'
        : '';
    return Opacity(
      opacity: full ? 1 : 0.55,
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="${_hex(stroke)}" stroke-opacity="${_op(stroke)}" stroke-width="2" '
        'stroke-linecap="round" stroke-linejoin="round">$body'
        '<path d="M7 3h10l-.4 5.2a4.6 4.6 0 01-9.2 0z"/><path d="M12 13v7M8.5 21h7"/></svg>',
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Fila de copas: [lives] llenas de [total].
class QuizCopas extends StatelessWidget {
  final int lives;
  final int total;
  final double size;
  final double gap;
  const QuizCopas(
      {super.key,
      required this.lives,
      this.total = 3,
      this.size = 22,
      this.gap = 2});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) SizedBox(width: gap),
              QuizCopa(full: i < lives, size: size),
            ],
          ],
        ),
      );
}

const _tierGlyph = {
  QuizMedalKind.bronze:
      '<path d="M4 14.5c1.6-1.6 3.2-1.6 4.8 0s3.2 1.6 4.8 0 3.2-1.6 4.8 0M4 9.5c1.6-1.6 3.2-1.6 4.8 0s3.2 1.6 4.8 0 3.2-1.6 4.8 0"/>',
  QuizMedalKind.silver:
      '<path d="M3.5 18.5l5.6-9.6c.5-.9 1.3-.9 1.8 0l.9 1.6 1.1-1.6c.5-.7 1.3-.7 1.8 0l5.8 9.6z"/><path d="M10.5 5.5l1-2M14 5.8l1.6-1.6"/>',
  QuizMedalKind.gold:
      '<path d="M4.5 17.5L3.5 8l4.6 3.6L12 5l3.9 6.6L20.5 8l-1 9.5z"/>',
};

/// Degradados de medalla (Sistema §5): oro, plata y bronce.
const kQuizMedalStops = {
  QuizMedalKind.gold: ['#F3DFA8', '#D6B675', '#B08A48'],
  QuizMedalKind.silver: ['#F4F4F6', '#C9CCD3', '#9EA2AB'],
  QuizMedalKind.bronze: ['#F2C9A2', '#CD8F5C', '#9C6236'],
};

/// Degradado de medalla como [LinearGradient] (posiciones del ranking).
LinearGradient quizMedalGradient(QuizMedalKind k) {
  Color c(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));
  final s = kQuizMedalStops[k]!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [c(s[0]), c(s[1]), c(s[2])],
    stops: const [0, 0.55, 1],
  );
}

/// Medalla de arena (Marea bronce · Volcán plata · Leyenda oro) con su glifo.
class QuizMedal extends StatelessWidget {
  final QuizMedalKind kind;
  final double size;
  const QuizMedal({super.key, required this.kind, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final s = kQuizMedalStops[kind]!;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30 30">'
      '<defs><linearGradient id="m" x1="0" y1="0" x2="0.4" y2="1">'
      '<stop offset="0" stop-color="${s[0]}"/><stop offset=".55" stop-color="${s[1]}"/>'
      '<stop offset="1" stop-color="${s[2]}"/></linearGradient></defs>'
      '<circle cx="15" cy="15" r="14" fill="url(#m)"/>'
      '<circle cx="15" cy="15" r="13.3" fill="none" stroke="#FFFFFF" stroke-opacity=".55" stroke-width="1"/>'
      '<g transform="translate(5.4 5.4) scale(0.8)" fill="none" stroke="#3A2A12" stroke-width="2.2" '
      'stroke-linecap="round" stroke-linejoin="round">${_tierGlyph[kind]}</g></svg>',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}

/// Humor de la mascota volcán.
enum QuizVolcanoMood { happy, sad, surprised }

/// Volcán mascota (100 × 70): feliz, triste o sorprendido (con gota).
class QuizVolcano extends StatelessWidget {
  final QuizVolcanoMood mood;
  final double width;
  const QuizVolcano(
      {super.key, this.mood = QuizVolcanoMood.happy, this.width = 96});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = _hex(gm.volcInk);
    final mouth = switch (mood) {
      QuizVolcanoMood.happy =>
        '<path d="M44.5 56.5q5.5 4.6 11 0" fill="none" stroke="$ink" stroke-width="2.4" stroke-linecap="round"/>',
      QuizVolcanoMood.sad =>
        '<path d="M45 59q5-3.8 10 0" fill="none" stroke="$ink" stroke-width="2.2" stroke-linecap="round"/>',
      QuizVolcanoMood.surprised =>
        '<ellipse cx="50" cy="58" rx="3.2" ry="3.8" fill="$ink"/>',
    };
    final eyes = mood == QuizVolcanoMood.happy
        ? '<path d="M39.5 50q3-3.4 6 0M54.5 50q3-3.4 6 0" fill="none" stroke="$ink" stroke-width="2.4" stroke-linecap="round"/>'
        : '<circle cx="42.5" cy="49" r="2.8" fill="$ink"/><circle cx="57.5" cy="49" r="2.8" fill="$ink"/>';
    final cheeks = mood == QuizVolcanoMood.happy
        ? '<circle cx="37" cy="55.5" r="2.6" fill="#E0603A" fill-opacity=".35"/><circle cx="63" cy="55.5" r="2.6" fill="#E0603A" fill-opacity=".35"/>'
        : '';
    final sweat = mood == QuizVolcanoMood.surprised
        ? '<path d="M66 38c2 3 2.6 4.6 2.6 5.6a2.6 2.6 0 01-5.2 0c0-1 .6-2.6 2.6-5.6z" fill="#7CC4E6"/>'
        : '';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70">'
      '<path d="M6 68l28-34c3-3.4 6-4.1 8.6-2.2l4.3 3c3.2 2.2 6.6 2.2 9.8 0l4.3-3c2.6-1.9 5.6-1.2 8.6 2.2L94 68z" '
      'fill="${_hex(gm.volcFill)}" stroke="${_hex(gm.sep)}" stroke-opacity="${_op(gm.sep)}" stroke-width="1.2"/>'
      '<path d="M41 32.6l3.6 6 2.6-3.2 3 4.4 3.2-4.6 2.6 3.4 3-6" fill="none" stroke="#E0603A" '
      'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" stroke-opacity=".85"/>'
      '$eyes$cheeks$mouth$sweat</svg>',
      width: width,
      height: width * 0.7,
      excludeFromSemantics: true,
    );
  }
}

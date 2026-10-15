import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';
import 'package:http/http.dart' as http;
import 'package:guachinches/services/app_storage.dart';

/// Escribir (o editar) una reseña — tablero FichaResena.
///
/// Validación de siempre: nota obligatoria; texto opcional pero, si se
/// escribe, entre 8 y 600 caracteres; título opcional de hasta 60. Con
/// [existingReview] se edita la reseña del usuario (`updateReview`).
class WriteReviewScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int initialRating;
  final Review? existingReview;

  const WriteReviewScreen({
    super.key,
    required this.restaurant,
    this.initialRating = 0,
    this.existingReview,
  });

  static const minChars = 8;
  static const maxChars = 600;
  static const maxTitle = 60;

  /// Nota obligatoria; texto vacío o ≥ 8 (bloqueamos solo 1–7).
  static bool canSubmit(int rating, String text) {
    if (rating <= 0) return false;
    final len = text.trim().length;
    return len == 0 || len >= minChars;
  }

  static const ratingLabels = [
    'Mala', 'Regular', 'Aceptable', 'Muy buena', 'Excelente'
  ];

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _titleCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  final _storage = AppStorage.instance;
  late final HttpRemoteRepository _repo =
      HttpRemoteRepository(http.Client());

  late int _rating;
  bool _submitting = false;

  bool get _editing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(0, 5);
    final e = widget.existingReview;
    if (e != null) {
      _titleCtrl.text = e.title;
      _reviewCtrl.text = e.review;
    }
    _reviewCtrl.addListener(() => setState(() {}));
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      WriteReviewScreen.canSubmit(_rating, _reviewCtrl.text);

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context, false);
        return;
      }
      final e = widget.existingReview;
      final ok = e != null
          ? await _repo.updateReview(userId, e.id, _titleCtrl.text.trim(),
              _rating.toString(), _reviewCtrl.text.trim())
          : await _repo.saveReview(
              userId,
              widget.restaurant,
              _titleCtrl.text.trim(),
              _reviewCtrl.text.trim(),
              _rating.toString(),
            );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_editing ? 'Reseña actualizada' : '¡Reseña publicada!'),
            backgroundColor: AppColors.laurisilva,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _submitting = false);
        _showError(_editing
            ? 'No se pudieron guardar los cambios. Inténtalo de nuevo.'
            : 'No se pudo publicar tu reseña. Inténtalo de nuevo.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Sin conexión. Comprueba tu internet.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.mojo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = widget.restaurant;
    final top = MediaQuery.paddingOf(context).top;
    final textLen = _reviewCtrl.text.trim().length;

    return Scaffold(
      backgroundColor: gm.canvas,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, top + 2, 16, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  GmToolbarButton(
                    icon: GmIcons.close,
                    iconSize: 16,
                    light: true,
                    semanticLabel: 'Cerrar sin publicar',
                    identifier: 'write-review-close-button',
                    onTap: () => Navigator.pop(context, false),
                  ),
                  Expanded(
                    child: Text(
                      _editing ? 'Editar reseña' : 'Escribir reseña',
                      textAlign: TextAlign.center,
                      style:
                          GmText.body17(color: gm.label, w: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GmRise(
              trigger: GmTrigger.mount,
              child: _RestaurantHeader(restaurant: r),
            ),
            const SizedBox(height: 16),
            GmRise(
              trigger: GmTrigger.mount,
              index: 1,
              child: _RatingPicker(
                value: _rating,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Título'),
            const SizedBox(height: 6),
            _Field(
              controller: _titleCtrl,
              hint: 'Ej. Los tomates rellenos, de diez',
              maxLength: WriteReviewScreen.maxTitle,
              identifier: 'write-review-title-field',
            ),
            const SizedBox(height: 6),
            _Counter(
                right:
                    '${_titleCtrl.text.length}/${WriteReviewScreen.maxTitle}'),
            const SizedBox(height: 12),
            const _FieldLabel('Tu reseña'),
            const SizedBox(height: 6),
            _Field(
              controller: _reviewCtrl,
              hint: 'Cuéntanos qué pediste, qué te gustó y qué no...',
              maxLength: WriteReviewScreen.maxChars,
              minLines: 6,
              maxLines: 9,
              identifier: 'write-review-text-field',
            ),
            const SizedBox(height: 6),
            _Counter(
              left:
                  'Si escribes, mínimo ${WriteReviewScreen.minChars} caracteres',
              leftWarn: textLen > 0 && textLen < WriteReviewScreen.minChars,
              right: '$textLen/${WriteReviewScreen.maxChars}',
            ),
            const SizedBox(height: 22),
            _SubmitButton(
              label: _editing ? 'Guardar cambios' : 'Publicar reseña',
              enabled: _canSubmit && !_submitting,
              loading: _submitting,
              onTap: _submit,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GmIcon(GmIcons.person, size: 12, color: gm.label2),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tu nombre se mostrará junto a tu reseña.',
                    textAlign: TextAlign.center,
                    style:
                        GmText.eyebrow(color: gm.label2, w: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantHeader({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final image = restaurant.mainFoto.isNotEmpty
        ? restaurant.mainFoto
        : (restaurant.fotos.isNotEmpty
            ? restaurant.fotos.first.photoUrl
            : null);
    final type = restaurantTypeLabel(restaurant.type);
    final muni = gmPlaceName(restaurant.municipio);
    final sub =
        [if (type.isNotEmpty) type, if (muni.isNotEmpty) muni].join(' · ');
    return GmCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
                width: 52,
                height: 52,
                child: GmPhoto(image, decodeWidth: 160)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gmDisplayName(restaurant.nombre),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.body17(color: gm.label, w: FontWeight.w600),
                ),
                if (sub.isNotEmpty)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          child:
                              CustomPaint(painter: GmGinghamPainter(cell: 3)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.eyebrow(
                              color: gm.label2, w: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RatingPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'write-review-rating',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        child: Column(
          children: [
            Text('¿Cómo fue tu experiencia?',
                textAlign: TextAlign.center,
                style: GmText.title2(color: gm.label)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 1; i <= 5; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: value == i,
                      label:
                          '$i de 5: ${WriteReviewScreen.ratingLabels[i - 1]}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: Center(
                                child: GmOnce(
                                  trigger: GmTrigger.mount,
                                  duration: const Duration(milliseconds: 560),
                                  delay: Duration(
                                      milliseconds: 150 + (i - 1) * 70),
                                  child: AnimatedScale(
                                    scale: i == value ? 1.12 : 1,
                                    duration:
                                        const Duration(milliseconds: 260),
                                    curve: GmMotion.spring,
                                    child: GmIcon(
                                      i <= value
                                          ? GmIcons.star
                                          : GmIcons.starOutline,
                                      size: 36,
                                      color: i <= value
                                          ? GmColors.star
                                          : gm.label2,
                                    ),
                                  ),
                                  builder: (_, t, c) {
                                    final p = GmMotion.spring.transform(t);
                                    return Transform.scale(
                                        scale: 0.6 + 0.4 * p, child: c);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(minHeight: 22),
                              padding: EdgeInsets.symmetric(
                                  horizontal: i == value ? 6 : 0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == value
                                    ? const Color(0x24C98200)
                                    : null,
                                borderRadius:
                                    BorderRadius.circular(GmRadius.pill),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  WriteReviewScreen.ratingLabels[i - 1],
                                  maxLines: 1,
                                  style: GmText.chip(
                                    color: i == value ? gm.label : gm.label2,
                                    w: i == value
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final s = TextStyle(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
        color: gm.label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: text, style: s),
        TextSpan(
            text: ' (opcional)',
            style: s.copyWith(fontWeight: FontWeight.w500, color: gm.label2)),
      ])),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final String identifier;

  const _Field({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.identifier,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gm.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: gm.shadow1,
        ),
        child: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: gm.accent,
          style: GmText.body17(color: gm.label),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GmText.body17(color: gm.label2),
            border: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String? left;
  final bool leftWarn;
  final String right;
  const _Counter({this.left, this.leftWarn = false, required this.right});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final s = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      color: gm.label2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(left ?? '',
                style: leftWarn ? s.copyWith(color: gm.warnText) : s),
          ),
          Text(right, style: s),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    if (!enabled && !loading) {
      return Semantics(
        identifier: 'write-review-submit-button',
        button: true,
        enabled: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: gm.isDark
                ? const Color(0x2E4DAEDB)
                : const Color(0xFFDDE6E4),
            borderRadius: BorderRadius.circular(GmRadius.pill),
          ),
          child: Text(label,
              style: GmText.body17(color: gm.label2, w: FontWeight.w600)),
        ),
      );
    }
    return Semantics(
      identifier: 'write-review-submit-button',
      child: SizedBox(
        width: double.infinity,
        child: GmCapsuleButton(
          label: loading ? 'Publicando…' : label,
          height: 52,
          fontSize: 17,
          onTap: loading ? null : onTap,
        ),
      ),
    );
  }
}

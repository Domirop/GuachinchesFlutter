import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:http/http.dart' as http;

class WriteReviewScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int initialRating;

  const WriteReviewScreen({
    super.key,
    required this.restaurant,
    this.initialRating = 0,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _titleCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  final _reviewFocus = FocusNode();
  final _storage = const FlutterSecureStorage();
  late final HttpRemoteRepository _repo =
      HttpRemoteRepository(http.Client());

  late int _rating;
  bool _submitting = false;

  static const _minChars = 8;
  static const _maxChars = 600;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(0, 5);
    _reviewCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reviewCtrl.dispose();
    _reviewFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_rating <= 0) return false;
    final len = _reviewCtrl.text.trim().length;
    // Texto opcional: vacío o ≥ _minChars; bloqueamos solo el rango 1–7.
    return len == 0 || len >= _minChars;
  }

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
      final ok = await _repo.saveReview(
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
            content: const Text('¡Reseña publicada!'),
            backgroundColor: AppColors.laurisilva,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _submitting = false);
        _showError('No se pudo publicar tu reseña. Inténtalo de nuevo.');
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

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Mala';
      case 2:
        return 'Regular';
      case 3:
        return 'Aceptable';
      case 4:
        return 'Muy buena';
      case 5:
        return 'Excelente';
      default:
        return 'Toca una estrella';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final r = widget.restaurant;

    return Scaffold(
      backgroundColor: brand.base,
      appBar: AppBar(
        backgroundColor: brand.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: brand.textPrimary),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Escribir reseña',
          style: AppTextStyles.displaySection(size: 13),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RestaurantHeader(restaurant: r),
              const SizedBox(height: 20),
              _RatingPicker(
                value: _rating,
                label: _ratingLabel,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = v);
                },
              ),
              const SizedBox(height: 18),
              _Field(
                controller: _titleCtrl,
                label: 'Título (opcional)',
                hint: 'Ej. La mejor ropa vieja de Tenerife',
                maxLength: 60,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _reviewCtrl,
                focusNode: _reviewFocus,
                label: 'Tu reseña (opcional)',
                hint: 'Cuéntanos qué pediste, qué te gustó y qué no...',
                maxLines: 7,
                minLines: 5,
                maxLength: _maxChars,
              ),
              const SizedBox(height: 6),
              _CharCounter(
                current: _reviewCtrl.text.trim().length,
                min: _minChars,
                max: _maxChars,
                ratingSet: _rating > 0,
              ),
              const SizedBox(height: 24),
              _SubmitButton(
                enabled: _canSubmit && !_submitting,
                loading: _submitting,
                onTap: _submit,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tu nombre se mostrará junto a tu reseña.',
                  style: AppTextStyles.ui(
                    size: 11,
                    color: brand.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantHeader({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final image = restaurant.mainFoto.isNotEmpty
        ? restaurant.mainFoto
        : (restaurant.fotos.isNotEmpty
            ? restaurant.fotos.first.photoUrl
            : null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.surface,
        border: Border.all(color: brand.borderStrong),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: image != null
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImageFallback(brand: brand),
                    )
                  : _ImageFallback(brand: brand),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESEÑANDO',
                  style: AppTextStyles.eyebrow(
                    size: 9,
                    color: brand.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displayHero(size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final dynamic brand;
  const _ImageFallback({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: brand.elevated,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_rounded,
        color: brand.textMuted,
        size: 22,
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  const _RatingPicker({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: brand.surface,
        border: Border.all(color: brand.borderStrong),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '¿CÓMO FUE TU EXPERIENCIA?',
            style: AppTextStyles.displaySection(size: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final starN = i + 1;
              final filled = starN <= value;
              return GestureDetector(
                onTap: () => onChanged(starN),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: filled ? 1.0 : 0.92,
                    duration: const Duration(milliseconds: 120),
                    child: Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 40,
                      color: filled
                          ? AppColors.sol
                          : brand.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              label,
              key: ValueKey(label),
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w600,
                color: value > 0
                    ? AppColors.sol
                    : brand.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final int maxLines;
  final int? minLines;
  final int? maxLength;

  const _Field({
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.eyebrow(
            size: 10,
            color: brand.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          cursorColor: AppColors.atlantico,
          style: AppTextStyles.ui(
            size: 14,
            color: brand.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.ui(
              size: 14,
              color: brand.textMuted,
            ),
            counterText: '',
            filled: true,
            fillColor: brand.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: brand.borderStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: brand.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.atlantico, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _CharCounter extends StatelessWidget {
  final int current;
  final int min;
  final int max;
  final bool ratingSet;

  const _CharCounter({
    required this.current,
    required this.min,
    required this.max,
    required this.ratingSet,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final empty = current == 0;
    final tooShort = !empty && current < min;
    final ok = ratingSet && (empty || current >= min);

    String label;
    Color color;
    if (tooShort) {
      label = 'Mínimo $min caracteres si escribes algo';
      color = AppColors.mojo;
    } else if (!ratingSet) {
      label = 'Selecciona una valoración';
      color = brand.textMuted;
    } else if (ok && empty) {
      label = 'Listo para publicar (texto opcional)';
      color = AppColors.laurisilva;
    } else {
      label = 'Listo para publicar';
      color = AppColors.laurisilva;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.ui(
              size: 11,
              color: color,
              weight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current / $max',
          style: AppTextStyles.ui(
            size: 11,
            color: brand.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.atlantico,
          disabledBackgroundColor: AppColors.atlantico.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: enabled ? onTap : null,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'PUBLICAR RESEÑA',
                style: AppTextStyles.displaySection(size: 12)
                    .copyWith(color: Colors.white, letterSpacing: 1.0),
              ),
      ),
    );
  }
}

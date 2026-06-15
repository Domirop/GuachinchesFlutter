import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/floating_buttons.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ntk_box.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/pros_cons_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/restaurant_info_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/services_chips_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/visit_header_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/visit_pills_row.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';
import 'package:guachinches/ui/components/video/vertical_video_player.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';
import 'package:guachinches/ui/pages/visit/visit_presenter.dart';
import 'package:guachinches/ui/pages/visit/widgets/visit_reel_hero.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart';

class VisitDetailPage extends StatefulWidget {
  final String visitId;
  final String? title;

  /// Cuando se presenta dentro de un sheet glass: fondos transparentes (para
  /// que el frost se vea entre las tarjetas) y sin botón "atrás" (el sheet se
  /// cierra arrastrando o tocando fuera).
  final bool asSheet;

  const VisitDetailPage({
    Key? key,
    required this.visitId,
    this.title,
    this.asSheet = false,
  }) : super(key: key);

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage>
    implements VisitDetailView {
  late RemoteRepository _repo;
  late VisitDetailPresenter _presenter;

  vm.Visit? _visit;
  bool _loading = true;
  bool _liked = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = HttpRemoteRepository(sharedHttpClient);
    _presenter = VisitDetailPresenter(_repo, this);
    _presenter.loadVisit(widget.visitId);
  }

  // ===== VisitDetailView =====

  @override
  void showLoading() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  @override
  void showVisit(vm.Visit visit) {
    if (!mounted) return;
    setState(() {
      _visit = visit;
      _loading = false;
      _error = null;
    });
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  // ===== Acciones =====

  Future<void> _openVideoExternal() async {
    final url = _visit?.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Reproduce el vídeo del hero: mp4 self-host → reproductor in-app vertical;
  /// si no, embed de YouTube in-app; último recurso, abrir externo.
  void _playVideo() {
    final v = _visit;
    if (v == null) return;
    // mp4 self-host SOLO si el códec es reproducible en iOS (H.264/HEVC); si es
    // AV1/desconocido pintaría negro → fallback a YouTube embed.
    if (v.selfHostVideoPlayable) {
      showVerticalVideo(context,
          url: v.videoFileUrl!, visit: v, onOpenRestaurant: _goToRestaurant);
      return;
    }
    final ytId = v.youtubeVideoId;
    if (ytId != null && ytId.trim().isNotEmpty) {
      YoutubeEmbedSheet.show(context, videoId: ytId);
      return;
    }
    _openVideoExternal();
  }

  void _share() {
    final name =
        _visit?.name ?? _visit?.restaurant?.nombre ?? widget.title ?? 'Visita';
    SharePlus.instance.share(ShareParams(text: '$name en ¿Dónde Comer Canarias?'));
  }

  void _goToRestaurant() {
    final restaurantId = _visit?.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(id: restaurantId),
      ),
    );
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    // En sheet, los fondos van transparentes para dejar ver el cristal.
    final bg = widget.asSheet ? Colors.transparent : context.brand.base;
    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const _LoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: _ErrorView(
          message: _error!,
          onRetry: () => _presenter.loadVisit(widget.visitId),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _buildScrollContent(context),
          _buildFloatingButtons(context),
        ],
      ),
    );
  }

  Widget _buildScrollContent(BuildContext context) {
    final v = _visit!;
    final r = v.restaurant;
    final title = (v.name?.isNotEmpty == true ? v.name! : r?.nombre) ?? '';
    final summary = _summary(v);

    return Semantics(
      identifier: 'visit-detail-content',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ① Hero reel: vídeo (+ fotos de platos) en marco de móvil flotante.
            if (VisitReelHero.hasMedia(v))
              VisitReelHero(
                visit: v,
                asSheet: widget.asSheet,
                onPlayVideo: _playVideo,
              )
            else
              SizedBox(height: MediaQuery.of(context).padding.top + 64),

            // ② Autor + fecha + sentimiento.
            VisitHeaderSection(visit: v),

            // ③ Título editorial.
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Text(title, style: _titleStyle(context)),
              ),

            // ④ Resumen en cursiva editorial.
            if (summary != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  summary,
                  style: AppTextStyles.editorial(size: 14),
                ),
              ),
            ],

            // ⑤ VER LOCAL + me gusta + guardar.
            const SizedBox(height: 18),
            _ActionRow(
              liked: _liked,
              saved: _saved,
              onVerLocal: _goToRestaurant,
              onLike: () {
                HapticFeedback.selectionClick();
                setState(() => _liked = !_liked);
              },
              onSave: () {
                HapticFeedback.selectionClick();
                setState(() => _saved = !_saved);
              },
            ),
            const SizedBox(height: 22),

            // ⑥ Tarjeta del local.
            if (r != null) ...[
              RestaurantInfoCard(
                restaurant: r,
                visit: v,
                onTap: _goToRestaurant,
              ),
              const SizedBox(height: 12),
              VisitPillsRow(restaurant: r, visit: v),
              const SizedBox(height: 20),
            ],

            // ⑦ SERVICIOS.
            if (ServicesChipsSection.shouldRender(v.services)) ...[
              ServicesChipsSection(services: v.services),
              const SizedBox(height: 20),
            ],

            // ⑧ LO QUE PEDIMOS.
            if (DishesSection.shouldRender(v.dishes)) ...[
              DishesSection(dishes: v.dishes, heroPrefix: v.id),
              const SizedBox(height: 20),
            ],

            // ⑨ A FAVOR / EN CONTRA.
            if (ProsConsSection.shouldRender(v.highlights, v.lowlights)) ...[
              ProsConsSection(pros: v.highlights, cons: v.lowlights),
              const SizedBox(height: 20),
            ],

            // ⑩ LO QUE NECESITAS SABER.
            if (r != null) ...[
              NTKBox(restaurant: r, visit: v, instagram: v.instagram),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Stack(
      children: [
        // En sheet no hay botón "atrás": se cierra arrastrando/tocando fuera.
        if (!widget.asSheet)
          Positioned(
            top: top,
            left: 12,
            child: FloatingCircleButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => Navigator.pop(context),
                identifier: 'visit-detail-back-button'),
          ),
        Positioned(
          top: top,
          right: 12,
          child: Row(
            children: [
              FloatingCircleButton(
                  icon: Icons.ios_share_rounded,
                  onTap: _share,
                  identifier: 'visit-detail-share-button'),
              const SizedBox(width: 10),
              FloatingCircleButton(
                  icon: Icons.storefront_outlined,
                  onTap: _goToRestaurant,
                  identifier: 'visit-detail-restaurant-button'),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _titleStyle(BuildContext context) => TextStyle(
        fontFamily: 'Merriweather',
        fontWeight: FontWeight.w700,
        fontSize: 25,
        height: 1.16,
        color: context.brand.textPrimary,
      );

  String? _summary(vm.Visit v) {
    if (v.summary?.isNotEmpty == true) return v.summary;
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    final editorial = v.restaurant?.editorialBody;
    if (editorial != null && editorial.isNotEmpty) return editorial;
    return null;
  }
}

// ── Fila de acciones (VER LOCAL + me gusta + guardar) ──────────────────────

class _ActionRow extends StatelessWidget {
  final bool liked;
  final bool saved;
  final VoidCallback onVerLocal;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const _ActionRow({
    required this.liked,
    required this.saved,
    required this.onVerLocal,
    required this.onLike,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // VER LOCAL — pill outline atlántico.
          Expanded(
            child: Semantics(
              identifier: 'visit-detail-ver-local-button',
              button: true,
              child: GestureDetector(
                onTap: onVerLocal,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border:
                        Border.all(color: AppColors.atlantico, width: 1.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded,
                          size: 16, color: AppColors.atlantico),
                      const SizedBox(width: 8),
                      Text('VER LOCAL',
                          style: AppTextStyles.displaySection(
                              size: 12, color: AppColors.atlantico)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RoundAction(
            icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: liked ? AppColors.mojo : context.brand.textSecondary,
            onTap: onLike,
            identifier: 'visit-detail-like-button',
          ),
          const SizedBox(width: 10),
          _RoundAction(
            icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? AppColors.atlantico : context.brand.textSecondary,
            onTap: onSave,
            identifier: 'visit-detail-save-button',
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String identifier;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.brand.surface,
            shape: BoxShape.circle,
            border: Border.all(color: context.brand.border),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ── Estados ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'visit-detail-skeleton',
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero: marco de móvil vertical (9:16) centrado.
            Builder(builder: (context) {
              final w = (MediaQuery.of(context).size.width * 0.62)
                  .clamp(210.0, 280.0);
              return Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 56, bottom: 4),
                child: Center(
                  child: ShimmerBox(width: w, height: w * 16 / 9, radius: 34),
                ),
              );
            }),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 220, height: 22, radius: 6),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 160, height: 16, radius: 6),
            ),
            const SizedBox(height: 20),
            // Paragraph block 1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 14, radius: 4),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Paragraph block 2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 240, height: 14, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: 'visit-detail-error',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: context.brand.textMuted, size: 32),
                const SizedBox(height: 12),
                Text(message,
                    style: AppTextStyles.ui(size: 13, color: context.brand.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Semantics(
                  identifier: 'visit-detail-retry-button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.atlantico,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

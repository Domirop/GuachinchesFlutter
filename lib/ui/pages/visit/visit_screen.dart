import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/del_video_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ntk_box.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/pros_cons_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/restaurant_info_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/services_chips_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ticket_card_widget.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/visit_header_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/visit_pills_row.dart';
import 'package:guachinches/ui/pages/visit/visit_presenter.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VisitDetailPage extends StatefulWidget {
  final String visitId;
  final String? title;

  const VisitDetailPage({
    Key? key,
    required this.visitId,
    this.title,
  }) : super(key: key);

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage>
    implements VisitDetailView {
  late RemoteRepository _repo;
  late VisitDetailPresenter _presenter;

  vm.Visit? _visit;
  YoutubePlayerController? _ytController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = HttpRemoteRepository(Client());
    _presenter = VisitDetailPresenter(_repo, this);
    _presenter.loadVisit(widget.visitId);
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
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
    final videoId = _extractVideoId(visit.videoUrl);
    _ytController?.dispose();
    _ytController = videoId != null
        ? YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: false,
              forceHD: false,
            ),
          )
        : null;
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

  // ===== Helpers =====

  static String? _extractVideoId(String? url) {
    if (url == null || url.isEmpty) return null;
    // youtube.com/watch?v=ID
    // youtu.be/ID
    // youtube.com/shorts/ID
    // youtube.com/embed/ID
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }
    final segs = uri.pathSegments;
    if (segs.isEmpty) return null;
    if (uri.host.contains('youtu.be')) return segs.first;
    for (final kw in ['shorts', 'embed']) {
      final idx = segs.indexOf(kw);
      if (idx != -1 && idx + 1 < segs.length) return segs[idx + 1];
    }
    return null;
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

  void _openMaps() {
    final r = _visit?.restaurant;
    if (r == null) return;
    if (r.lat != 0 && r.lon != 0) {
      MapsLauncher.launchCoordinates(r.lat, r.lon, r.nombre);
    } else {
      MapsLauncher.launchQuery(r.nombre);
    }
  }

  Future<void> _call() async {
    final phone = _visit?.restaurant?.telefono ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _share() {
    final name = _visit?.restaurant?.nombre ?? widget.title ?? 'Visita';
    Share.share('$name en ¿Dónde Comer Canarias?');
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
    if (_loading) {
      return Scaffold(
        backgroundColor: context.brand.base,
        body: const _LoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.brand.base,
        body: _ErrorView(
          message: _error!,
          onRetry: () => _presenter.loadVisit(widget.visitId),
        ),
      );
    }

    // Con player YouTube: YoutubePlayerBuilder gestiona el fullscreen
    if (_ytController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.atlantico,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.atlantico,
            handleColor: AppColors.atlanticoClaro,
          ),
          onReady: () {},
        ),
        builder: (context, player) => _buildScaffold(context, player: player),
      );
    }

    // Sin video ID: thumbnail estático con botón de abrir externo
    return _buildScaffold(context, player: null);
  }

  Widget _buildScaffold(BuildContext context, {required Widget? player}) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: Stack(
        children: [
          _buildScrollContent(player),
          _buildFloatingButtons(),
        ],
      ),
      bottomNavigationBar: _visit != null
          ? _BottomBar(
              onDirections: _openMaps,
              onCall: (_visit?.restaurant?.telefono?.isNotEmpty == true)
                  ? _call
                  : null,
              onShare: _share,
            )
          : null,
    );
  }

  Widget _buildScrollContent(Widget? player) {
    final v = _visit!;
    final r = v.restaurant;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① Hero: player inline o thumbnail estático
          if (player != null)
            player
          else
            _StaticVideoHero(
              visit: v,
              onTap: _openVideoExternal,
            ),

          // ② Visit header (creator · fecha · sentiment)
          VisitHeaderSection(visit: v),

          // ③ Tarjeta azul info restaurante
          if (r != null) ...[
            RestaurantInfoCard(restaurant: r),
            const SizedBox(height: 12),
            VisitPillsRow(restaurant: r),
            const SizedBox(height: 16),
          ],

          // ④ Descripción
          if (_description(v) != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _description(v)!,
                style: AppTextStyles.ui(
                  size: 13,
                  color: context.brand.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ⑤ "42€ PARA DOS"
          if (TicketCardWidget.shouldRender(v)) ...[
            TicketCardWidget(visit: v),
            const SizedBox(height: 20),
          ],

          // ⑥ DEL VIDEO — citas del short
          if (r != null && DelVideoSection.shouldRender(r.shortQuotes)) ...[
            DelVideoSection(quotes: r.shortQuotes, videoId: r.shortVideoId),
            const SizedBox(height: 20),
          ],

          // ⑦ LO QUE PEDIMOS
          if (DishesSection.shouldRender(v.dishes)) ...[
            DishesSection(dishes: v.dishes),
            const SizedBox(height: 20),
          ],

          // ⑧ A FAVOR / EN CONTRA
          if (ProsConsSection.shouldRender(v.highlights, v.lowlights)) ...[
            ProsConsSection(pros: v.highlights, cons: v.lowlights),
            const SizedBox(height: 20),
          ],

          // ⑨ SERVICIOS
          if (ServicesChipsSection.shouldRender(v.services)) ...[
            ServicesChipsSection(services: v.services),
            const SizedBox(height: 20),
          ],

          // ⑩ LO QUE NECESITAS SABER
          if (r != null) ...[
            NTKBox(restaurant: r, instagram: v.instagram),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    final top = MediaQuery.of(context).padding.top + 8;
    return Stack(
      children: [
        Positioned(
          top: top,
          left: 12,
          child: _FloatingButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: top,
          right: 12,
          child: _FloatingButton(
            icon: Icons.ios_share,
            onTap: _share,
          ),
        ),
        Positioned(
          top: top,
          right: 56,
          child: _FloatingButton(
            icon: Icons.storefront_outlined,
            onTap: _goToRestaurant,
          ),
        ),
      ],
    );
  }

  String? _description(vm.Visit v) {
    final editorial = v.restaurant?.editorialBody;
    if (editorial != null && editorial.isNotEmpty) return editorial;
    if (v.summary != null && v.summary!.isNotEmpty) return v.summary;
    if (v.extraText != null && v.extraText!.isNotEmpty) return v.extraText;
    return null;
  }
}

// ── Thumbnail estático (fallback sin video ID) ────────────────────────────────

class _StaticVideoHero extends StatelessWidget {
  final vm.Visit visit;
  final VoidCallback onTap;

  const _StaticVideoHero({required this.visit, required this.onTap});

  bool get _hasVideo => visit.videoUrl != null && visit.videoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasVideo ? onTap : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnail(context),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            if (_hasVideo) const Center(child: _PlayButton()),
            if (visit.durationSeconds != null)
              Positioned(
                bottom: 10,
                right: 12,
                child: _DurationBadge(visit.durationSeconds!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final thumb = visit.thumbnail;
    final mainPhoto = visit.restaurant?.mainFoto ?? '';
    if (thumb != null && thumb.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback(context, mainPhoto),
      );
    }
    return _fallback(context, mainPhoto);
  }

  Widget _fallback(BuildContext context, String mainPhoto) {
    if (mainPhoto.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: mainPhoto,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: context.brand.elevated),
      );
    }
    return Container(color: context.brand.elevated);
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.atlantico.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          alignment: Alignment.center,
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.play_arrow, color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final int seconds;
  const _DurationBadge(this.seconds);

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$m:${s.toString().padLeft(2, '0')}',
        style: AppTextStyles.ui(
            size: 10, weight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

// ── Botón flotante ────────────────────────────────────────────────────────────

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback onShare;

  const _BottomBar({
    required this.onDirections,
    required this.onShare,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: context.brand.base,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.atlantico,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: onDirections,
              child: Text(
                'CÓMO LLEGAR ›',
                style: AppTextStyles.displaySection(size: 11)
                    .copyWith(color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          ),
          if (onCall != null) ...[
            const SizedBox(width: 8),
            _IconBtn(icon: Icons.phone_outlined, onTap: onCall!),
          ],
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.ios_share, onTap: onShare),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.brand.surface,
          border: Border.all(color: context.brand.borderStrong),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: context.brand.textPrimary),
      ),
    );
  }
}

// ── Estados ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.atlantico),
          const SizedBox(height: 12),
          Text('Cargando visita…',
              style:
                  AppTextStyles.ui(size: 11, color: context.brand.textMuted)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: context.brand.textMuted, size: 32),
            const SizedBox(height: 12),
            Text(message,
                style: AppTextStyles.ui(
                    size: 13, color: context.brand.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.atlantico,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

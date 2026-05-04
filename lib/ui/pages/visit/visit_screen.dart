import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/data/model/short_quote.dart';
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
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  bool _ytEmbedBlocked = false;
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
    _ytController?.close();
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
    _ytController?.close();
    _ytEmbedBlocked = false;
    if (videoId != null) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: false,
          playsInline: true,
          color: 'white',
        ),
      );
      // Detecta error de embedding (código 101/150/152) y cae al thumbnail
      _ytController!.listen((value) {
        if (value.error != YoutubeError.none && mounted && !_ytEmbedBlocked) {
          setState(() => _ytEmbedBlocked = true);
        }
      });
    } else {
      _ytController = null;
    }
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
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    // ?v=ID
    if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
    final segs = uri.pathSegments;
    if (segs.isEmpty) return null;
    // youtu.be/ID
    if (uri.host.contains('youtu.be')) return segs.first;
    // /shorts/ID  or  /embed/ID
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

  Future<void> _openMaps() async {
    final mapsUrl = _visit?.googleMapsUrl;
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      final uri = Uri.parse(mapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final r = _visit?.restaurant;
    final name = _visit?.name ?? r?.nombre ?? '';
    if (r != null && r.lat != 0 && r.lon != 0) {
      MapsLauncher.launchCoordinates(r.lat, r.lon, name);
    } else if (name.isNotEmpty) {
      MapsLauncher.launchQuery(name);
    }
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

    // Con player inline (solo si embedding no está bloqueado)
    if (_ytController != null && !_ytEmbedBlocked) {
      return YoutubePlayerScaffold(
        controller: _ytController!,
        aspectRatio: 16 / 9,
        backgroundColor: Colors.black,
        builder: (context, player) => _buildScaffold(context, player: player),
      );
    }

    // Sin video ID: thumbnail estático
    return _buildScaffold(context, player: null);
  }

  Widget _buildScaffold(BuildContext context, {required Widget? player}) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: Stack(
        children: [
          _buildScrollContent(context, player),
          _buildFloatingButtons(context),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        onDirections: _openMaps,
        onShare: _share,
      ),
    );
  }

  Widget _buildScrollContent(BuildContext context, Widget? player) {
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
            _StaticVideoHero(visit: v, onTap: _openVideoExternal),

          // ② Visit header
          VisitHeaderSection(visit: v),

          // ③ Info restaurante
          if (r != null) ...[
            RestaurantInfoCard(
              restaurant: r,
              visit: v,
              onTap: _goToRestaurant,
            ),
            const SizedBox(height: 12),
            VisitPillsRow(restaurant: r, visit: v),
            const SizedBox(height: 16),
          ],

          // ④ Descripción
          if (_description(v) != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _description(v)!,
                style: AppTextStyles.ui(size: 13, color: context.brand.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ⑤ SERVICIOS (justo debajo de la descripción)
          if (ServicesChipsSection.shouldRender(v.services)) ...[
            ServicesChipsSection(services: v.services),
            const SizedBox(height: 20),
          ],

          // ⑥ Ticket "42€ PARA DOS" — ocultado: dato no fiable de momento
          // if (TicketCardWidget.shouldRender(v)) ...[
          //   TicketCardWidget(visit: v),
          //   const SizedBox(height: 20),
          // ],

          // ⑦ DEL VIDEO — ocultado temporalmente (problema de render por investigar)
          // if (_videoQuotes(v).isNotEmpty) ...[
          //   DelVideoSection(
          //     quotes: _videoQuotes(v),
          //     videoId: v.youtubeVideoId,
          //   ),
          //   const SizedBox(height: 20),
          // ],

          // ⑧ LO QUE PEDIMOS
          if (DishesSection.shouldRender(v.dishes)) ...[
            DishesSection(dishes: v.dishes),
            const SizedBox(height: 20),
          ],

          // ⑨ A FAVOR / EN CONTRA
          if (ProsConsSection.shouldRender(v.highlights, v.lowlights)) ...[
            ProsConsSection(pros: v.highlights, cons: v.lowlights),
            const SizedBox(height: 20),
          ],

          // ⑩ LO QUE NECESITAS SABER
          if (r != null) ...[
            NTKBox(restaurant: r, visit: v, instagram: v.instagram),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Stack(
      children: [
        Positioned(
          top: top, left: 12,
          child: _FloatingButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
        ),
        Positioned(
          top: top, right: 12,
          child: _FloatingButton(icon: Icons.ios_share, onTap: _share),
        ),
        Positioned(
          top: top, right: 56,
          child: _FloatingButton(icon: Icons.storefront_outlined, onTap: _goToRestaurant),
        ),
      ],
    );
  }

  String? _description(vm.Visit v) {
    if (v.summary?.isNotEmpty == true) return v.summary;
    final editorial = v.restaurant?.editorialBody;
    if (editorial != null && editorial.isNotEmpty) return editorial;
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    return null;
  }

  List<ShortQuote> _videoQuotes(vm.Visit v) {
    if (v.quotes.isNotEmpty) {
      return v.quotes
          .where((q) => q.text.isNotEmpty)
          .map((q) => ShortQuote(text: q.text, timestamp: q.timestamp))
          .toList();
    }
    return v.restaurant?.shortQuotes ?? const [];
  }
}

// ── Thumbnail estático (sin video ID válido) ──────────────────────────────────

class _StaticVideoHero extends StatelessWidget {
  final vm.Visit visit;
  final VoidCallback onTap;

  const _StaticVideoHero({required this.visit, required this.onTap});

  bool get _hasVideo => visit.videoUrl?.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasVideo ? onTap : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumb(context),
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
                bottom: 10, right: 12,
                child: _DurationBadge(visit.durationSeconds!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    final thumb = visit.thumbnail;
    final fallback = visit.restaurant?.mainFoto ?? '';
    if (thumb?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: thumb!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback(context, fallback),
      );
    }
    return _fallback(context, fallback);
  }

  Widget _fallback(BuildContext context, String url) {
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
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
          width: 64, height: 64,
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
      decoration: BoxDecoration(color: AppColors.glassDark, borderRadius: BorderRadius.circular(7)),
      child: Text('$m:${s.toString().padLeft(2, '0')}',
          style: AppTextStyles.ui(size: 10, weight: FontWeight.w600, color: Colors.white)),
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
            width: 36, height: 36,
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
  final VoidCallback onShare;

  const _BottomBar({required this.onDirections, required this.onShare});

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: onDirections,
              child: Text('CÓMO LLEGAR ›',
                  style: AppTextStyles.displaySection(size: 11)
                      .copyWith(color: Colors.white, letterSpacing: 1.0)),
            ),
          ),
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
        width: 46, height: 46,
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
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.atlantico),
            const SizedBox(height: 12),
            Text('Cargando visita…',
                style: AppTextStyles.ui(size: 11, color: context.brand.textMuted)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
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
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.atlantico,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

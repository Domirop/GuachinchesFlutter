import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';
import 'package:guachinches/ui/pages/visit/visit_presenter.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _loading = true;
  String? _error;

  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _repo = HttpRemoteRepository(Client());
    _presenter = VisitDetailPresenter(_repo, this);
    _presenter.loadVisit(widget.visitId);
  }

  @override
  void dispose() {
    _isDisposing = true;
    super.dispose();
  }

  // ===== VisitDetailView =====
  @override
  void showLoading() {
    if (!mounted || _isDisposing) return;
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  @override
  void showVisit(vm.Visit visit) {
    if (!mounted || _isDisposing) return;
    setState(() {
      _visit = visit;
      _loading = false;
      _error = null;
    });
  }

  @override
  void showError(String message) {
    if (!mounted || _isDisposing) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  // ===== Acciones =====

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openYoutubeLink() async {
    final url = _visit?.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ===== Build helpers =====

  Widget _buildActionButton(
      String text, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: GlobalMethods.blueColor, width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: GlobalMethods.blueColor, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: GlobalMethods.blueColor,
                fontFamily: 'SF Pro Display',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    final videoUrl = _visit?.videoUrl;

    // Thumbnail + abrir en YouTube app
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return GestureDetector(
        onTap: _openYoutubeLink,
        child: Stack(
          children: [
            if (_visit?.thumbnail != null && _visit!.thumbnail!.isNotEmpty)
              Image.network(
                _visit!.thumbnail!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildVideoPlaceholder(),
              )
            else
              _buildVideoPlaceholder(),
            Container(
              width: double.infinity,
              height: 220,
              color: Colors.black.withOpacity(0.4),
            ),
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 72),
                    SizedBox(height: 10),
                    Text(
                      'Ver en YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Sin video pero con thumbnail → imagen hero
    if (_visit?.thumbnail != null && _visit!.thumbnail!.isNotEmpty) {
      return Image.network(
        _visit!.thumbnail!,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            color: Colors.white38, size: 64),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final restaurantName =
        _visit?.restaurant?.nombre ?? widget.title ?? 'Visita';
    final municipio = _visit?.restaurant?.municipio ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoSection(),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                if (municipio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        municipio,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildActionButton(
                  'Cómo llegar',
                  Icons.location_on,
                  () => MapsLauncher.launchQuery(
                      _visit?.restaurant?.nombre ?? ''),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'Llamar',
                  Icons.phone,
                  () => _makePhoneCall(_visit?.restaurant?.telefono ?? ''),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Divider(
                color: Color.fromRGBO(208, 221, 255, 0.15), thickness: 0.5),
          ),

          if (_visit?.extraText?.isNotEmpty ?? false) ...[
            _buildSectionHeader('Nuestra experiencia', null),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _visit!.extraText!,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 15,
                  height: 1.65,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Divider(
                  color: Color.fromRGBO(208, 221, 255, 0.15), thickness: 0.5),
            ),
          ],

          if (_visit?.myTicket?.isNotEmpty ?? false) ...[
            _buildSectionHeader('Nuestro ticket', Icons.receipt_long),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _visit!.myTicket!,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 15,
                  height: 1.65,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = GlobalMethods.bgColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _visit?.restaurant?.nombre ?? widget.title ?? 'Visita',
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(
                  message: _error!,
                  onRetry: () => _presenter.loadVisit(widget.visitId),
                )
              : _buildBody(),
      bottomNavigationBar: _visit != null
          ? BottomAppBar(
              color: bg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => GlobalMethods()
                        .pushPage(context, Details(_visit!.restaurantId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalMethods.blueColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ver restaurante'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({Key? key, required this.message, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

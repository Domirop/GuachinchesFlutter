import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';
import 'package:guachinches/ui/pages/visit/visit_presenter.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
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

  YoutubePlayerController? _ytController;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _repo = HttpRemoteRepository(Client());
    _presenter = VisitDetailPresenter(_repo, this);
    _presenter.loadVisit(widget.visitId);
  }
  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          elevation: MaterialStateProperty.all(0.0),
          side: MaterialStateProperty.all(
              BorderSide(width: 1, color: GlobalMethods.blueColor)),
          // Borde blanco
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  10.0), // Ajusta el valor para redondear más las esquinas
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: GlobalMethods.blueColor,
              size: 18,
            ),
            SizedBox(
              width: 8.0,
            ),
            Text(
              text,
              style: TextStyle(
                color: GlobalMethods.blueColor,
                fontFamily: 'SF Pro Display',
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _isDisposing = true;
    _ytController?.close();
    _ytController = null;
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
    _initYoutube(visit.videoUrl ?? '');
  }

  @override
  void showError(String message) {
    if (!mounted || _isDisposing) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  // ===== YouTube =====
  void _initYoutube(String url) {
    if (_isDisposing) return;

    final id = YoutubePlayerController.convertUrlToId(url);
    if (id == null) {
      setState(() => _error = 'El enlace de YouTube no es válido');
      return;
    }

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: id,
      params: const YoutubePlayerParams(
        mute: false,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        showVideoAnnotations: false
      ),
    );
  }
// Función para realizar una llamada telefónica
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await canLaunchUrl(launchUri);
    } else {
      // Maneja el error si no se puede realizar la llamada
      print('No se puede realizar la llamada al $phoneNumber');
    }
  }


  @override
  Widget build(BuildContext context) {
    final bg = GlobalMethods.bgColor;
    final title =
        _visit?.restaurant?.nombre ?? widget.title ?? "Visita";

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(
        message: _error!,
        onRetry: () => _presenter.loadVisit(widget.visitId),
      )
          : (_ytController == null)
          ? _ErrorView(
        message: 'No se pudo inicializar el video.',
        onRetry: () => _presenter.loadVisit(widget.visitId),
      )
          : SingleChildScrollView( // 👈 envolvemos el contenido
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _ytController!,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 8),
              child: Row(
                children: [
                  _buildButton(
                      'Como llegar',
                      Icons.location_on,
                          () => MapsLauncher.launchQuery(
                          '${_visit!.restaurant!.nombre}')),
                  const SizedBox(width: 8),
                  _buildButton(
                      'Llamar',
                      Icons.phone,
                          () => _makePhoneCall(
                          _visit!.restaurant!.telefono)),
                ],
              ),
            ),
            if ((_visit?.extraText?.isNotEmpty ?? false)) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  "Experiencia",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _visit!.extraText!,
                  style: const TextStyle(
                      color: Colors.white,
                    fontSize: 14,
                      fontWeight: FontWeight.normal

                  ),
                ),
              ),
            ],
            if ((_visit?.myTicket?.isNotEmpty ?? false)) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  "Nuestro ticket",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _visit!.myTicket!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.normal
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80), // 👈 espacio para no tapar el contenido con el bottom bar
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => GlobalMethods().pushPage(context, Details(_visit!.restaurantId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalMethods.blueColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // 👈 evita que ocupe todo el ancho
                    children: const [
                      Text("Ver restaurante"),
                      SizedBox(width: 8), // separación
                      Icon(Icons.arrow_forward_ios,size: 16,),
                    ],
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
            child: const Text("Reintentar"),
          )
        ],
      ),
    );
  }
}

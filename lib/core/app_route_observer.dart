import 'package:flutter/widgets.dart';

/// Observer global de rutas. Lo usan widgets que necesitan saber cuándo se
/// apila otra pantalla encima (p.ej. el reel inline de una visita, para pausar
/// el vídeo al navegar a "ver local" y reanudarlo al volver). Se registra en
/// `MaterialApp.navigatorObservers` en main.dart.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

/// Cliente HTTP compartido de vida-aplicación, reutilizado entre pantallas.
///
/// Reutilizar un único [Client] agrupa conexiones (keep-alive) dentro de los
/// fan-outs de requests, evitando el churn de abrir/cerrar un pool por montaje.
///
/// PERO se acota [HttpClient.idleTimeout] a 5s: un proxy/balanceador upstream
/// cierra silenciosamente las conexiones keep-alive ociosas tras unos segundos;
/// si el cliente reutiliza una de esas conexiones medio-cerradas, la petición
/// se queda colgada hasta agotar su propio timeout (15s) — justo el síntoma de
/// "detalle atascado en skeleton". Cerrando las conexiones ociosas en el lado
/// cliente ANTES de que el upstream las mate, garantizamos que cada burst de
/// requests (todos disparados en ms) sí comparte conexión, pero nunca se reusa
/// una conexión rancia entre navegaciones.
///
/// No se cierra: vive lo que vive la app (patrón recomendado del paquete http).
final Client sharedHttpClient = IOClient(
  HttpClient()..idleTimeout = const Duration(seconds: 5),
);

import 'package:http/http.dart';

/// App-lifetime HTTP client shared across all screens.
/// Reuses connection pools and TLS sessions for keep-alive efficiency.
/// Never call [close] on this instance — it is intentionally long-lived.
final Client sharedHttpClient = Client();

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    http.Client? httpClient,
  })  : _connectivity = connectivity ?? Connectivity(),
        _http = httpClient ?? http.Client();

  final Connectivity _connectivity;
  final http.Client _http;

  static final _probeUris = <Uri>[
    Uri.parse('https://clients3.google.com/generate_204'),
    Uri.parse('https://www.google.com/generate_204'),
  ];

  Stream<bool> get onlineStream async* {
    yield await isOnline;
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }

  /// Raw interface changes (Wi‑Fi/mobile/none). Use with [hasInternetAccess]
  /// for true reachability.
  Stream<List<ConnectivityResult>> get connectivityChanges =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  Future<bool> get isWifi async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  /// True network reachability (not just interface up).
  Future<bool> hasInternetAccess({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!await isOnline) return false;
    for (final uri in _probeUris) {
      try {
        final response = await _http
            .head(uri)
            .timeout(timeout);
        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true;
        }
        // generate_204 often returns 204
        if (response.statusCode == 204) return true;
      } catch (_) {
        try {
          final response = await _http.get(uri).timeout(timeout);
          if (response.statusCode == 204 ||
              (response.statusCode >= 200 && response.statusCode < 400)) {
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Stream<bool> get onConnectivityChanged;
  Future<bool> checkIsOnline();
  void dispose();
}

class AppConnectivityService implements ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  AppConnectivityService() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = _isResultsOnline(results);
      _controller.add(isOnline);
    });
  }

  bool _isResultsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> checkIsOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isResultsOnline(results);
    } catch (_) {
      return true; // Default fallback
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

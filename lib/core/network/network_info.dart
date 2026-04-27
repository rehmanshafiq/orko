import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction for connectivity checking.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Concrete implementation using connectivity_plus.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

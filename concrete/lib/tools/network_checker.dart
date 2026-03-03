import 'package:core/core.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

class NetworkInfoFake implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);
}

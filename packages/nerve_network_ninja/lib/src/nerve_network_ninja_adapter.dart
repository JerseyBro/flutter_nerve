import 'package:dio/dio.dart';
import 'package:nerve_core/nerve_core.dart';
import 'package:network_ninja/network_ninja.dart';

class NerveNetworkNinjaAdapter {
  NerveNetworkNinjaAdapter()
    : plugin = StaticDebugHubPlugin(
        id: 'network',
        title: 'Network',
        priority: 10,
        summary: () => DebugHubSummary(
          label: 'Captured requests',
          value: NetworkNinjaController.logCount.toString(),
        ),
      );

  final DebugHubPlugin plugin;

  void attachTo(Dio dio) {
    NetworkNinjaController.addInterceptor(dio);
  }

  void detachFrom(Dio dio) {
    NetworkNinjaController.removeInterceptor(dio);
  }

  void clear() {
    NetworkNinjaController.clearLogs();
  }

  int interceptorCount(Dio dio) {
    return dio.interceptors
        .where(
          (interceptor) =>
              interceptor.runtimeType.toString().contains('NetworkNinja'),
        )
        .length;
  }
}

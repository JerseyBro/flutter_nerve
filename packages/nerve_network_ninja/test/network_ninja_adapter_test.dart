import 'package:dio/dio.dart';
import 'package:nerve_network_ninja/nerve_network_ninja.dart';
import 'package:test/test.dart';

void main() {
  test('attachTo adds a single Network Ninja interceptor per Dio', () {
    final dio = Dio();
    final adapter = NerveNetworkNinjaAdapter();

    adapter.attachTo(dio);
    adapter.attachTo(dio);

    expect(adapter.interceptorCount(dio), 1);
  });

  test('plugin summary reports captured log count', () {
    final adapter = NerveNetworkNinjaAdapter()..clear();

    expect(adapter.plugin.id, 'network');
    expect(adapter.plugin.summary().value, '0');
  });
}

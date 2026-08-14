import 'package:nerve_core/nerve_core.dart';
import 'package:test/test.dart';

void main() {
  test('EnvironmentDebugPlugin summarizes the active environment', () {
    final plugin = EnvironmentDebugPlugin(
      env: 'dev',
      hosts: {'api': 'https://api.example.com', 'ws': 'wss://ws.example.com'},
    );

    expect(plugin.id, 'environment');
    expect(plugin.summary().label, 'Environment');
    expect(plugin.summary().value, 'dev');
    expect(
      plugin.diagnostics()['hosts'],
      containsPair('api', 'https://api.example.com'),
    );
  });

  test(
    'FlagsDebugPlugin summarizes enabled flags without exposing secrets',
    () {
      final plugin = FlagsDebugPlugin({
        'ENABLE_DEVTOOL': true,
        'FORCE_REVIEW_MODE': false,
        'token': 'secret',
      });

      expect(plugin.summary().value, '1 on');
      expect(plugin.diagnostics()['token'], '[REDACTED]');
    },
  );

  test(
    'ConnectivityDebugPlugin reports last probe status after running check',
    () async {
      final plugin = ConnectivityDebugPlugin(
        probes: [
          ConnectivityProbe(
            id: 'app-init',
            label: 'App init',
            check: () async => const ConnectivityProbeResult.ok(
              statusCode: 200,
              durationMs: 42,
            ),
          ),
        ],
      );

      expect(plugin.summary().value, 'not run');

      final results = await plugin.runAll();

      expect(results.single.status, ConnectivityProbeStatus.ok);
      expect(plugin.summary().value, '1 ok');
    },
  );
}

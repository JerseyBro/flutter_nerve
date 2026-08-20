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
    'DebugSettingsPlugin summarizes changed settings and redacts diagnostics',
    () {
      final plugin = DebugSettingsPlugin(
        settings: () => const [
          DebugSetting(
            id: 'env',
            label: 'Environment',
            type: DebugSettingType.select,
            currentValue: 'dev',
            defaultValue: 'prod',
            options: [
              DebugSettingOption(value: 'dev', label: 'Development'),
              DebugSettingOption(value: 'prod', label: 'Production'),
            ],
            restartRequired: true,
          ),
          DebugSetting(
            id: 'api_token',
            label: 'API Token',
            type: DebugSettingType.text,
            currentValue: 'secret-token',
            defaultValue: '',
            sensitive: true,
          ),
        ],
      );

      expect(plugin.id, 'settings');
      expect(plugin.summary().value, '2 changed');

      final diagnostics = plugin.diagnostics();
      final settings = diagnostics['settings']! as List<Object?>;
      expect(settings.toString(), isNot(contains('secret-token')));
      expect(settings.toString(), contains('[REDACTED]'));
    },
  );

  test(
    'DebugSettingsPlugin normalizes apply values and marks restart required',
    () async {
      late Map<String, Object?> applied;
      final plugin = DebugSettingsPlugin(
        settings: () => const [
          DebugSetting(
            id: 'env',
            label: 'Environment',
            type: DebugSettingType.select,
            currentValue: 'dev',
            defaultValue: 'prod',
            options: [
              DebugSettingOption(value: 'dev', label: 'Development'),
              DebugSettingOption(value: 'prod', label: 'Production'),
            ],
            restartRequired: true,
          ),
          DebugSetting(
            id: 'FORCE_REVIEW_MODE',
            label: 'Force review mode',
            type: DebugSettingType.boolean,
            currentValue: false,
            defaultValue: false,
          ),
        ],
        onApply: (values) async {
          applied = values;
          return const DebugSettingsApplyResult(message: 'Saved');
        },
      );

      final result = await plugin.apply({
        'env': 'prod',
        'FORCE_REVIEW_MODE': 'not-bool',
        'unknown': true,
      });

      expect(applied, {'env': 'prod', 'FORCE_REVIEW_MODE': false});
      expect(result.message, 'Saved');
      expect(result.restartRequired, isTrue);
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

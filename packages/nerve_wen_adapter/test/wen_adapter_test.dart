import 'package:nerve_core/nerve_core.dart';
import 'package:nerve_wen_adapter/nerve_wen_adapter.dart';
import 'package:test/test.dart';

void main() {
  test('buildWenDiagnostics keeps hosts visible and secrets redacted', () {
    final diagnostics = buildWenDiagnostics(
      env: 'dev',
      apiHost: 'https://api.example.com',
      wsHost: 'wss://ws.example.com',
      mpcHost: 'https://mpc.example.com',
      headers: {'Authorization': 'sample-auth-value'},
    );

    expect(diagnostics['env'], 'dev');
    expect(diagnostics['apiHost'], 'https://api.example.com');
    expect((diagnostics['headers'] as Map)['Authorization'], '[REDACTED]');
  });

  test('buildWenDebugSettingsPlugin exposes Wen runtime settings', () async {
    late Map<String, Object?> applied;
    final plugin = buildWenDebugSettingsPlugin(
      env: 'dev',
      forceReviewMode: false,
      environments: const ['dev', 'prod'],
      onApply: (values) async {
        applied = values;
        return const DebugSettingsApplyResult(
          message: 'Saved. Restart required.',
        );
      },
    );

    final settings = plugin.settings();
    expect(plugin.id, 'settings');
    expect(settings.map((setting) => setting.id), ['env', 'FORCE_REVIEW_MODE']);
    expect(settings.first.options.map((option) => option.value), [
      'dev',
      'prod',
    ]);

    final result = await plugin.apply({
      'env': 'prod',
      'FORCE_REVIEW_MODE': true,
    });

    expect(applied, {'env': 'prod', 'FORCE_REVIEW_MODE': true});
    expect(result.restartRequired, isTrue);
  });
}

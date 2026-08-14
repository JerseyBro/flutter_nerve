import 'package:nerve_core/nerve_core.dart';
import 'package:test/test.dart';

void main() {
  test('registerPlugin exposes enabled plugins in priority order', () {
    final controller = DebugHubController();

    controller.registerPlugin(
      StaticDebugHubPlugin(
        id: 'device',
        title: 'Device',
        priority: 30,
        summary: () => const DebugHubSummary(label: 'Device', value: 'iOS'),
      ),
    );
    controller.registerPlugin(
      StaticDebugHubPlugin(
        id: 'network',
        title: 'Network',
        priority: 10,
        summary: () => const DebugHubSummary(label: 'Network', value: '2'),
      ),
    );

    expect(controller.plugins.map((plugin) => plugin.id), [
      'network',
      'device',
    ]);
    expect(controller.summaryTiles.map((tile) => tile.value), ['2', 'iOS']);
  });

  test('redactDiagnostics removes sensitive values recursively', () {
    final redactor = DebugHubRedactor();

    final redacted = redactor.redact({
      'Authorization': 'sample-auth-value',
      'headers': {'Cookie': 'sample-cookie-value', 'x-request-id': 'req-1'},
      'wallet': {
        'address': '0x123',
        'privateKey': 'sample-sensitive-value',
        'mnemonic': 'sample-sensitive-value',
      },
      'items': [
        {'token': 'sample-sensitive-value'},
      ],
    });

    expect(redacted['Authorization'], '[REDACTED]');
    expect((redacted['headers'] as Map)['Cookie'], '[REDACTED]');
    expect((redacted['headers'] as Map)['x-request-id'], 'req-1');
    expect((redacted['wallet'] as Map)['privateKey'], '[REDACTED]');
    expect((redacted['wallet'] as Map)['mnemonic'], '[REDACTED]');
    expect(((redacted['items'] as List).first as Map)['token'], '[REDACTED]');
  });
}

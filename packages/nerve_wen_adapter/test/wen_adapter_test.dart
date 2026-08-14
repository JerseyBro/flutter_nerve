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
}

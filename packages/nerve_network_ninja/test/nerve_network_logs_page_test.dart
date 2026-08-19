import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nerve_flutter/nerve_flutter.dart';
import 'package:nerve_network_ninja/nerve_network_ninja.dart';
import 'package:network_ninja/network_ninja.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clipboardText = '';

  setUp(() {
    NetworkLogsService.instance.clearLogs();
    clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              clipboardText = (call.arguments as Map)['text'] as String;
              return null;
            case 'Clipboard.getData':
              return {'text': clipboardText};
          }
          return null;
        });
  });

  testWidgets('shows captured network logs and opens details', (tester) async {
    NetworkLogsService.instance.addLog(
      NetworkLog(
        id: '1',
        timestamp: DateTime(2026, 8, 18, 10, 30),
        method: 'GET',
        endpoint: 'https://api.example.com/api/v1/app/init',
        responseStatus: 200,
        duration: const Duration(milliseconds: 320),
      ),
    );

    await tester.pumpWidget(_TestHost());

    expect(find.text('Network Logs'), findsOneWidget);
    expect(find.text('GET'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);

    await tester.tap(find.text('GET'));
    await tester.pumpAndSettle();

    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Request Headers'), findsOneWidget);
    expect(find.text('Copy Request'), findsOneWidget);
  });

  testWidgets('search and filter narrow the log list', (tester) async {
    NetworkLogsService.instance
      ..addLog(
        NetworkLog(
          id: '1',
          timestamp: DateTime(2026, 8, 18, 10, 30),
          method: 'GET',
          endpoint: 'https://api.example.com/api/v1/chains',
          responseStatus: 200,
        ),
      )
      ..addLog(
        NetworkLog(
          id: '2',
          timestamp: DateTime(2026, 8, 18, 10, 31),
          method: 'POST',
          endpoint: 'https://api.example.com/api/v1/auth/login',
          responseStatus: 500,
        ),
      );

    await tester.pumpWidget(_TestHost());

    await tester.enterText(find.byType(TextField), 'auth');
    await tester.pumpAndSettle();
    expect(find.text('POST'), findsOneWidget);
    expect(find.text('GET'), findsNothing);

    await tester.tap(find.text('ERROR'));
    await tester.pumpAndSettle();
    expect(find.text('POST'), findsOneWidget);
  });

  testWidgets('copy payload redacts sensitive headers', (tester) async {
    NetworkLogsService.instance.addLog(
      NetworkLog(
        id: '1',
        timestamp: DateTime(2026, 8, 18, 10, 30),
        method: 'POST',
        endpoint: 'https://api.example.com/api/v1/wallets',
        requestHeaders: const {'Authorization': 'Bearer secret-token'},
        requestBody: '{"mnemonic":"secret words"}',
        responseStatus: 200,
        responseBody: '{"ok":true}',
      ),
    );

    await tester.pumpWidget(_TestHost());
    await tester.tap(find.text('POST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy Request'));
    await tester.pumpAndSettle();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, contains('[REDACTED]'));
    expect(clipboard?.text, isNot(contains('secret-token')));
    expect(clipboard?.text, isNot(contains('secret words')));
  });

  testWidgets('renders in a plain Material shell', (tester) async {
    NetworkLogsService.instance.addLog(
      NetworkLog(
        id: '1',
        timestamp: DateTime(2026, 8, 18, 10, 30),
        method: 'GET',
        endpoint: 'https://api.example.com/api/v1/app/init',
        responseStatus: 200,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: NerveNetworkLogsPage(
            actions: DebugHubPluginPageActions(
              showHome: () {},
              dismiss: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Network Logs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: NerveNetworkLogsPage(
          actions: DebugHubPluginPageActions(showHome: () {}, dismiss: () {}),
        ),
      ),
    );
  }
}

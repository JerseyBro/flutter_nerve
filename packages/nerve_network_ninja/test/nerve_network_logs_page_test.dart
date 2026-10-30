import 'dart:convert';

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

  testWidgets('shows backend response before the transport error', (
    tester,
  ) async {
    NetworkLogsService.instance.addLog(
      NetworkLog(
        id: 'requote',
        timestamp: DateTime(2026, 10, 30, 9, 12),
        method: 'POST',
        endpoint: 'https://api.example.com/swap/v1/routes/prepare',
        responseStatus: 409,
        responseBody: jsonEncode(<String, Object?>{
          'success': false,
          'requestId': 'req_test_requote',
          'data': null,
          'error': <String, Object?>{
            'code': 'REQUOTE_REQUIRED',
            'message':
                'LI.FI refreshed minimum output is below the quoted minimum.',
            'displayMessage': 'LI.FI latest minimum output is below the quote.',
            'errorCategory': 'BUSINESS',
            'directFallbackEligible': false,
          },
        }),
        error:
            '[REDACTED] 409 and RequestOptions.validateStatus was configured to throw',
      ),
    );

    await tester.pumpWidget(_TestHost());
    await tester.tap(find.text('POST'));
    await tester.pumpAndSettle();
    await _scrollDetailUntilVisible(tester, find.text('Backend Error'));

    expect(find.text('Backend Error'), findsOneWidget);
    expect(find.textContaining('REQUOTE_REQUIRED'), findsAtLeastNWidgets(1));
    expect(
      find.textContaining('LI.FI latest minimum output'),
      findsAtLeastNWidgets(1),
    );

    await _scrollDetailUntilVisible(tester, find.text('Backend Response'));
    expect(find.text('Backend Response'), findsOneWidget);

    await _scrollDetailUntilVisible(tester, find.text('Transport Error'));
    expect(find.text('Transport Error'), findsOneWidget);
    expect(find.textContaining('validateStatus'), findsOneWidget);
  });

  testWidgets('copies both backend response and transport error', (
    tester,
  ) async {
    NetworkLogsService.instance.addLog(
      NetworkLog(
        id: 'copy-error',
        timestamp: DateTime(2026, 10, 30, 9, 12),
        method: 'POST',
        endpoint: 'https://api.example.com/swap/v1/routes/prepare',
        responseStatus: 409,
        responseBody: '{"error":{"code":"REQUOTE_REQUIRED"}}',
        error: 'Dio transport error',
      ),
    );

    await tester.pumpWidget(_TestHost());
    await tester.tap(find.text('POST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy Response'));
    await tester.pumpAndSettle();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, contains('REQUOTE_REQUIRED'));
    expect(clipboard?.text, contains('Dio transport error'));
  });

  testWidgets('keeps a successful response in the response body section', (
    tester,
  ) async {
    NetworkLogsService.instance.addLog(
      NetworkLog(
        id: 'success',
        timestamp: DateTime(2026, 10, 30, 9, 12),
        method: 'GET',
        endpoint: 'https://api.example.com/health',
        responseStatus: 200,
        responseBody: '{"ok":true}',
      ),
    );

    await tester.pumpWidget(_TestHost());
    await tester.tap(find.text('GET'));
    await tester.pumpAndSettle();
    await _scrollDetailUntilVisible(tester, find.text('Response Body'));

    expect(find.text('Response Body'), findsOneWidget);
    expect(find.text('Backend Response'), findsNothing);
    expect(find.textContaining('"ok": true'), findsOneWidget);
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
            actions: DebugHubPluginPageActions(showHome: () {}, dismiss: () {}),
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
      home: Scaffold(
        body: SizedBox.expand(
          child: NerveNetworkLogsPage(
            actions: DebugHubPluginPageActions(showHome: () {}, dismiss: () {}),
          ),
        ),
      ),
    );
  }
}

Future<void> _scrollDetailUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  for (var attempt = 0; attempt < 6; attempt++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.dragFrom(const Offset(400, 300), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

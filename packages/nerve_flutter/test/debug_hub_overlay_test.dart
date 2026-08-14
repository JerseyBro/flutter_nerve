import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nerve_core/nerve_core.dart';
import 'package:nerve_flutter/nerve_flutter.dart';

void main() {
  testWidgets('DebugHubOverlayHost hides the launcher when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DebugHubOverlayHost(
          enabled: false,
          controller: DebugHubController(),
          child: const Text('Home'),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.byTooltip('Open Nerve'), findsNothing);
  });

  testWidgets('DebugHubOverlayHost opens a plugin panel when enabled', (
    tester,
  ) async {
    final controller = DebugHubController()
      ..registerPlugin(
        StaticDebugHubPlugin(
          id: 'env',
          title: 'Environment',
          priority: 1,
          summary: () => const DebugHubSummary(label: 'Env', value: 'dev'),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: DebugHubOverlayHost(
          enabled: true,
          controller: controller,
          child: const Text('Home'),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open Nerve'));
    await tester.pumpAndSettle();

    expect(find.text('Nerve'), findsOneWidget);
    expect(find.text('Environment'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
  });
}

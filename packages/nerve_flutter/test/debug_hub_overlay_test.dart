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
    expect(find.byIcon(Icons.bolt_rounded), findsNothing);
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
    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nerve'), findsOneWidget);
    expect(find.text('Environment'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
  });

  testWidgets(
    'works when mounted in MaterialApp.builder without Overlay/Navigator '
    'ancestor (regression: Tooltip assert in builder placement)',
    (tester) async {
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
          home: const Text('Home'),
          builder: (context, child) => DebugHubOverlayHost(
            enabled: true,
            controller: controller,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bolt_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Nerve'), findsOneWidget);
      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('dev'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Nerve'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('panel close button dismisses the panel', (tester) async {
    final controller = DebugHubController();
    await tester.pumpWidget(
      MaterialApp(
        home: DebugHubOverlayHost(
          enabled: true,
          controller: controller,
          child: const Text('Home'),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nerve'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nerve'), findsNothing);
  });
}

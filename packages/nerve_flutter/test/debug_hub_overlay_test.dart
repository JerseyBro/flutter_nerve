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

  testWidgets('launcher can open a configured plugin page directly', (
    tester,
  ) async {
    final controller = DebugHubController()
      ..registerPlugin(
        StaticDebugHubPlugin(
          id: 'network',
          title: 'Network',
          summary: () =>
              const DebugHubSummary(label: 'Captured requests', value: '3'),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: DebugHubOverlayHost(
          enabled: true,
          controller: controller,
          launchPluginId: 'network',
          pluginPages: {
            'network': (context, actions) => TextButton(
              onPressed: actions.showHome,
              child: const Text('Network Logs'),
            ),
          },
          child: const Text('Home'),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Network Logs'), findsOneWidget);

    await tester.tap(find.text('Network Logs'));
    await tester.pumpAndSettle();
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('environment page applies the selected environment', (
    tester,
  ) async {
    var appliedEnvironment = '';
    final controller = DebugHubController()
      ..registerPlugin(
        const EnvironmentDebugPlugin(
          env: 'dev',
          hosts: {'api': 'https://api.example.com'},
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: DebugHubOverlayHost(
          enabled: true,
          controller: controller,
          launchPluginId: 'environment',
          pluginPages: {
            'environment': (context, actions) => DebugHubEnvironmentPage(
              actions: actions,
              currentEnvironment: 'dev',
              options: const [
                DebugHubEnvironmentOption(value: 'dev', label: 'Development'),
                DebugHubEnvironmentOption(value: 'prod', label: 'Production'),
              ],
              onApply: (environment) async {
                appliedEnvironment = environment;
              },
            ),
          },
          child: const Text('Home'),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nerve-debug-launcher')));
    await tester.pumpAndSettle();
    expect(find.text('Environment'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('environment-option-prod')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch & Restart'));
    await tester.pumpAndSettle();

    expect(appliedEnvironment, 'prod');
  });

  testWidgets('settings page edits select bool text and shows restart notice', (
    tester,
  ) async {
    late Map<String, Object?> applied;
    final plugin = DebugSettingsPlugin(
      settings: () => const [
        DebugSetting(
          id: 'env',
          label: 'Environment',
          group: 'Runtime',
          type: DebugSettingType.select,
          currentValue: 'dev',
          defaultValue: 'dev',
          options: [
            DebugSettingOption(value: 'dev', label: 'Development'),
            DebugSettingOption(value: 'prod', label: 'Production'),
          ],
          restartRequired: true,
        ),
        DebugSetting(
          id: 'FORCE_REVIEW_MODE',
          label: 'Force review mode',
          group: 'Runtime',
          type: DebugSettingType.boolean,
          currentValue: false,
          defaultValue: false,
          restartRequired: true,
        ),
        DebugSetting(
          id: 'api_host',
          label: 'API host',
          group: 'Network',
          type: DebugSettingType.text,
          currentValue: 'https://api.dev.example.com',
          defaultValue: 'https://api.dev.example.com',
          restartRequired: true,
        ),
      ],
      onApply: (values) async {
        applied = values;
        return const DebugSettingsApplyResult(
          message: 'Saved. Restart the app to apply changes.',
          restartRequired: true,
        );
      },
    );
    final controller = DebugHubController()..registerPlugin(plugin);

    await tester.pumpWidget(
      MaterialApp(
        home: DebugHubOverlayHost(
          enabled: true,
          controller: controller,
          launchPluginId: 'settings',
          pluginPages: {
            'settings': (context, actions) =>
                DebugHubSettingsPage(actions: actions, plugin: plugin),
          },
          child: const Text('Home'),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nerve-debug-launcher')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Runtime'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('debug-setting-env')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Production').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('debug-setting-FORCE_REVIEW_MODE')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('debug-setting-api_host')),
      'https://api.override.example.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('debug-settings-apply')));
    await tester.pumpAndSettle();

    expect(applied, {
      'env': 'prod',
      'FORCE_REVIEW_MODE': true,
      'api_host': 'https://api.override.example.com',
    });
    expect(
      find.text('Saved. Restart the app to apply changes.'),
      findsOneWidget,
    );
  });

  testWidgets('dragging the launcher repositions it without opening panel', (
    tester,
  ) async {
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

    final finder = find.byKey(const ValueKey('nerve-debug-launcher'));
    expect(finder, findsOneWidget);
    final before = tester.getTopLeft(finder);

    await tester.drag(finder, const Offset(-100, -100));
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(finder);
    expect(after.dx, lessThan(before.dx));
    expect(after.dy, lessThan(before.dy));
    expect(find.text('Nerve'), findsNothing);

    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(find.text('Nerve'), findsOneWidget);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nerve_core/nerve_core.dart';
import 'package:nerve_flutter/nerve_flutter.dart';
import 'package:nerve_network_ninja/nerve_network_ninja.dart';

void main() {
  runApp(const NerveExampleApp());
}

class NerveExampleApp extends StatefulWidget {
  const NerveExampleApp({super.key});

  @override
  State<NerveExampleApp> createState() => _NerveExampleAppState();
}

class _NerveExampleAppState extends State<NerveExampleApp> {
  late final Dio _dio;
  late final DebugHubController _controller;
  late final DebugSettingsPlugin _settingsPlugin;
  String _environment = 'dev';
  bool _forceReviewMode = false;
  String _apiHost = 'https://api.dev.example.com';
  int _restartEpoch = 0;

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    final networkAdapter = NerveNetworkNinjaAdapter()..attachTo(_dio);
    _settingsPlugin = DebugSettingsPlugin(
      settings: _buildSettings,
      onApply: _applySettings,
    );
    _controller = DebugHubController()
      ..registerPlugin(networkAdapter.plugin)
      ..registerPlugin(_buildEnvironmentPlugin())
      ..registerPlugin(_settingsPlugin)
      ..registerPlugin(FlagsDebugPlugin(_buildFlags()));
  }

  EnvironmentDebugPlugin _buildEnvironmentPlugin() {
    return EnvironmentDebugPlugin(
      env: _environment,
      hosts: _environment == 'dev'
          ? const {
              'api': 'https://api.dev.example.com',
              'ws': 'wss://ws.example.com',
            }
          : const {
              'api': 'https://api.example.com',
              'ws': 'wss://ws.example.com',
            },
    );
  }

  Map<String, Object?> _buildFlags() => {
    'ENABLE_DEVTOOL': true,
    'FORCE_REVIEW_MODE': _forceReviewMode,
  };

  List<DebugSetting> _buildSettings() {
    return [
      DebugSetting(
        id: 'env',
        label: 'Environment',
        description: 'Saved changes require an app restart.',
        group: 'Runtime',
        type: DebugSettingType.select,
        currentValue: _environment,
        defaultValue: 'dev',
        options: const [
          DebugSettingOption(value: 'dev', label: 'Development'),
          DebugSettingOption(value: 'prod', label: 'Production'),
        ],
        restartRequired: true,
      ),
      DebugSetting(
        id: 'FORCE_REVIEW_MODE',
        label: 'Force review mode',
        description: 'Local-only review mode override.',
        group: 'Runtime',
        type: DebugSettingType.boolean,
        currentValue: _forceReviewMode,
        defaultValue: false,
        restartRequired: true,
      ),
      DebugSetting(
        id: 'api_host',
        label: 'API host',
        description: 'Example text setting for host overrides.',
        group: 'Network',
        type: DebugSettingType.text,
        currentValue: _apiHost,
        defaultValue: 'https://api.dev.example.com',
        restartRequired: true,
      ),
    ];
  }

  Future<DebugSettingsApplyResult> _applySettings(
    Map<String, Object?> values,
  ) async {
    setState(() {
      _environment = values['env']?.toString() ?? _environment;
      _forceReviewMode = values['FORCE_REVIEW_MODE'] == true;
      _apiHost = values['api_host']?.toString() ?? _apiHost;
      _controller.unregisterPlugin('environment');
      _controller.registerPlugin(_buildEnvironmentPlugin());
      _controller.unregisterPlugin('flags');
      _controller.registerPlugin(FlagsDebugPlugin(_buildFlags()));
      _restartEpoch += 1;
    });
    return const DebugSettingsApplyResult(
      message: 'Saved. Restart the app to apply changes.',
      restartRequired: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: KeyedSubtree(
        key: ValueKey(_restartEpoch),
        child: DebugHubOverlayHost(
          enabled: true,
          controller: _controller,
          launchPluginId: 'network',
          pluginPages: {
            'network': (context, actions) =>
                NerveNetworkLogsPage(actions: actions),
            'settings': (context, actions) =>
                DebugHubSettingsPage(actions: actions, plugin: _settingsPlugin),
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Nerve Example')),
            body: Center(
              child: FilledButton.icon(
                icon: const Icon(Icons.http_rounded),
                label: const Text('Send sample request'),
                onPressed: () {
                  _dio.get('https://example.com');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

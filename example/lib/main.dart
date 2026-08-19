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
  String _environment = 'dev';
  int _restartEpoch = 0;

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    final networkAdapter = NerveNetworkNinjaAdapter()..attachTo(_dio);
    _controller = DebugHubController()
      ..registerPlugin(networkAdapter.plugin)
      ..registerPlugin(_buildEnvironmentPlugin())
      ..registerPlugin(
        FlagsDebugPlugin(const {
          'ENABLE_DEVTOOL': true,
          'FORCE_REVIEW_MODE': false,
        }),
      );
  }

  EnvironmentDebugPlugin _buildEnvironmentPlugin() {
    return EnvironmentDebugPlugin(
      env: _environment,
      hosts: _environment == 'dev'
          ? const {
              'api': 'https://api.example.com',
              'ws': 'wss://ws.example.com',
            }
          : const {
              'api': 'https://api.example.com',
              'ws': 'wss://ws.example.com',
            },
    );
  }

  Future<void> _switchEnvironment(String environment) async {
    setState(() {
      _environment = environment;
      _controller.unregisterPlugin('environment');
      _controller.registerPlugin(_buildEnvironmentPlugin());
      _restartEpoch += 1;
    });
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
            'environment': (context, actions) => DebugHubEnvironmentPage(
                  actions: actions,
                  currentEnvironment: _environment,
                  options: const [
                    DebugHubEnvironmentOption(
                      value: 'dev',
                      label: 'Development',
                      description: 'Use dev backend and debug settings.',
                    ),
                    DebugHubEnvironmentOption(
                      value: 'prod',
                      label: 'Production',
                      description: 'Use prod backend and release settings.',
                    ),
                  ],
                  onApply: (environment) async {
                    await _switchEnvironment(environment);
                  },
                ),
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

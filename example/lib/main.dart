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

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    final networkAdapter = NerveNetworkNinjaAdapter()..attachTo(_dio);
    _controller = DebugHubController()
      ..registerPlugin(networkAdapter.plugin)
      ..registerPlugin(
        const EnvironmentDebugPlugin(
          env: 'dev',
          hosts: {
            'api': 'https://api.example.com',
            'ws': 'wss://ws.example.com',
          },
        ),
      )
      ..registerPlugin(
        FlagsDebugPlugin(const {
          'ENABLE_DEVTOOL': true,
          'FORCE_REVIEW_MODE': false,
        }),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: DebugHubOverlayHost(
        enabled: true,
        controller: _controller,
        launchPluginId: 'network',
        pluginPages: {
          'network': (context, actions) =>
              NerveNetworkLogsPage(actions: actions),
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
    );
  }
}

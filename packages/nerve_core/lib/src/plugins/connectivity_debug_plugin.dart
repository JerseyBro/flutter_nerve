import '../debug_hub_plugin.dart';

class ConnectivityDebugPlugin implements DebugHubPlugin {
  ConnectivityDebugPlugin({
    required List<ConnectivityProbe> probes,
    this.priority = 30,
    this.enabled = true,
  }) : probes = List.unmodifiable(probes);

  final List<ConnectivityProbe> probes;
  List<ConnectivityProbeResult> _lastResults = const [];

  @override
  final int priority;

  @override
  final bool enabled;

  @override
  String get id => 'connectivity';

  @override
  String get title => 'Connectivity';

  @override
  DebugHubSummary summary() {
    if (_lastResults.isEmpty) {
      return const DebugHubSummary(label: 'Probe status', value: 'not run');
    }
    final okCount = _lastResults
        .where((result) => result.status == ConnectivityProbeStatus.ok)
        .length;
    final hasError = _lastResults.any(
      (result) => result.status == ConnectivityProbeStatus.error,
    );
    return DebugHubSummary(
      label: 'Probe status',
      value: '$okCount ok',
      status: hasError ? DebugHubStatus.error : DebugHubStatus.ok,
    );
  }

  Future<List<ConnectivityProbeResult>> runAll() async {
    final results = <ConnectivityProbeResult>[];
    for (final probe in probes) {
      try {
        results.add(await probe.check());
      } catch (error) {
        results.add(ConnectivityProbeResult.error(message: error.toString()));
      }
    }
    _lastResults = List.unmodifiable(results);
    return _lastResults;
  }
}

class ConnectivityProbe {
  const ConnectivityProbe({
    required this.id,
    required this.label,
    required this.check,
  });

  final String id;
  final String label;
  final Future<ConnectivityProbeResult> Function() check;
}

class ConnectivityProbeResult {
  const ConnectivityProbeResult.ok({
    required this.statusCode,
    required this.durationMs,
  }) : status = ConnectivityProbeStatus.ok,
       message = null;

  const ConnectivityProbeResult.error({
    required this.message,
    this.statusCode,
    this.durationMs,
  }) : status = ConnectivityProbeStatus.error;

  final ConnectivityProbeStatus status;
  final int? statusCode;
  final int? durationMs;
  final String? message;
}

enum ConnectivityProbeStatus { ok, error }

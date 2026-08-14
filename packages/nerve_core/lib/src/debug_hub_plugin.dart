typedef DebugHubSummaryBuilder = DebugHubSummary Function();

abstract interface class DebugHubPlugin {
  String get id;
  String get title;
  int get priority;
  bool get enabled;
  DebugHubSummary summary();
}

class StaticDebugHubPlugin implements DebugHubPlugin {
  const StaticDebugHubPlugin({
    required this.id,
    required this.title,
    required DebugHubSummaryBuilder summary,
    this.priority = 100,
    this.enabled = true,
  }) : _summary = summary;

  @override
  final String id;

  @override
  final String title;

  @override
  final int priority;

  @override
  final bool enabled;

  final DebugHubSummaryBuilder _summary;

  @override
  DebugHubSummary summary() => _summary();
}

class DebugHubSummary {
  const DebugHubSummary({
    required this.label,
    required this.value,
    this.status = DebugHubStatus.neutral,
    this.detail,
  });

  final String label;
  final String value;
  final DebugHubStatus status;
  final String? detail;

  Map<String, Object?> toJson() => {
    'label': label,
    'value': value,
    'status': status.name,
    if (detail != null) 'detail': detail,
  };
}

enum DebugHubStatus { neutral, ok, warning, error }

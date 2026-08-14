import '../debug_hub_plugin.dart';

class EnvironmentDebugPlugin implements DebugHubPlugin {
  const EnvironmentDebugPlugin({
    required this.env,
    this.hosts = const {},
    this.priority = 20,
    this.enabled = true,
  });

  final String env;
  final Map<String, String> hosts;

  @override
  final int priority;

  @override
  final bool enabled;

  @override
  String get id => 'environment';

  @override
  String get title => 'Environment';

  @override
  DebugHubSummary summary() {
    return DebugHubSummary(label: 'Environment', value: env);
  }

  Map<String, Object?> diagnostics() => {'env': env, 'hosts': hosts};
}

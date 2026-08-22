import '../debug_hub_plugin.dart';
import '../debug_log.dart';

class LogDebugPlugin implements DebugHubPlugin {
  LogDebugPlugin(this.store, {this.priority = 15, this.enabled = true});

  final DebugLogStore store;

  @override
  final int priority;

  @override
  final bool enabled;

  @override
  String get id => 'logs';

  @override
  String get title => 'Logs';

  @override
  DebugHubSummary summary() {
    final c = store.length;
    final hasError = store.entries.any((e) => e.level == DebugLogLevel.error || e.level == DebugLogLevel.critical);
    return DebugHubSummary(
      label: 'App logs',
      value: c == 0 ? 'empty' : '$c entries',
      status: hasError ? DebugHubStatus.error : (c == 0 ? DebugHubStatus.neutral : DebugHubStatus.ok),
    );
  }

  Map<String, Object?> diagnostics() => {
        'count': store.length,
        'errorCount': store.entries
            .where((e) => e.level == DebugLogLevel.error || e.level == DebugLogLevel.critical)
            .length,
        'categories': store.categories.toList()..sort(),
      };
}

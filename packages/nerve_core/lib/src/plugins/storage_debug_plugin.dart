import '../debug_hub_plugin.dart';
import '../debug_hub_redactor.dart';

typedef StorageSnapshotProvider = Map<String, Object?> Function();

class StorageDebugPlugin implements DebugHubPlugin {
  StorageDebugPlugin({
    required StorageSnapshotProvider snapshot,
    this.id = 'storage',
    this.title = 'Storage',
    this.priority = 16,
    this.enabled = true,
    DebugHubRedactor? redactor,
  })  : _snapshot = snapshot,
        _redactor = redactor ?? DebugHubRedactor();

  final StorageSnapshotProvider _snapshot;
  final DebugHubRedactor _redactor;

  @override
  final String id;

  @override
  final String title;

  @override
  final int priority;

  @override
  final bool enabled;

  Map<String, Object?> get snapshot => _snapshot();

  @override
  DebugHubSummary summary() {
    final count = snapshot.length;
    return DebugHubSummary(
      label: 'Local storage',
      value: count == 0 ? 'empty' : '$count keys',
    );
  }

  Map<String, Object?> diagnostics() {
    return _redactor.redact(snapshot);
  }
}

import 'dart:async';

import 'debug_hub_plugin.dart';
import 'debug_hub_redactor.dart';

class DebugHubController {
  DebugHubController({DebugHubRedactor? redactor})
    : redactor = redactor ?? DebugHubRedactor();

  final DebugHubRedactor redactor;
  final Map<String, DebugHubPlugin> _plugins = {};

  final _changeController = StreamController<void>.broadcast();

  /// 插件集合变化流，便于面板实时刷新摘要。
  Stream<void> get changes => _changeController.stream;

  void _notifyChanged() {
    if (!_changeController.isClosed) _changeController.add(null);
  }

  void registerPlugin(DebugHubPlugin plugin) {
    _plugins[plugin.id] = plugin;
    _notifyChanged();
  }

  void unregisterPlugin(String id) {
    _plugins.remove(id);
    _notifyChanged();
  }

  void notifyChanged() => _notifyChanged();

  List<DebugHubPlugin> get plugins {
    final enabled = _plugins.values.where((plugin) => plugin.enabled).toList();
    enabled.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      return priority == 0 ? a.title.compareTo(b.title) : priority;
    });
    return List.unmodifiable(enabled);
  }

  List<DebugHubSummary> get summaryTiles =>
      plugins.map((plugin) => plugin.summary()).toList(growable: false);

  Map<String, Object?> exportDiagnostics({
    Map<String, Object?> extra = const {},
  }) {
    final payload = <String, Object?>{
      'generatedAt': DateTime.now().toIso8601String(),
      'plugins': [
        for (final plugin in plugins)
          {
            'id': plugin.id,
            'title': plugin.title,
            'summary': plugin.summary().toJson(),
            'diagnostics': _safeDiagnostics(plugin),
          },
      ],
      ...extra,
    };
    return redactor.redact(payload);
  }

  Map<String, Object?> _safeDiagnostics(DebugHubPlugin plugin) {
    try {
      final d = (plugin as dynamic).diagnostics();
      if (d is Map<String, Object?>) return d;
      if (d is Map) return d.cast<String, Object?>();
    } catch (_) {}
    return const {};
  }

  void dispose() {
    _changeController.close();
  }
}

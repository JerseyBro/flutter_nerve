import 'debug_hub_plugin.dart';
import 'debug_hub_redactor.dart';

class DebugHubController {
  DebugHubController({DebugHubRedactor? redactor})
    : redactor = redactor ?? DebugHubRedactor();

  final DebugHubRedactor redactor;
  final Map<String, DebugHubPlugin> _plugins = {};

  void registerPlugin(DebugHubPlugin plugin) {
    _plugins[plugin.id] = plugin;
  }

  void unregisterPlugin(String id) {
    _plugins.remove(id);
  }

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
          },
      ],
      ...extra,
    };
    return redactor.redact(payload);
  }
}

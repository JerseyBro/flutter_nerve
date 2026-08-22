import 'dart:async';
import 'dart:convert';

/// 日志级别，与常见开源方案对齐。
enum DebugLogLevel { verbose, debug, info, warning, error, critical }

extension DebugLogLevelX on DebugLogLevel {
  String get label => switch (this) {
        DebugLogLevel.verbose => 'V',
        DebugLogLevel.debug => 'D',
        DebugLogLevel.info => 'I',
        DebugLogLevel.warning => 'W',
        DebugLogLevel.error => 'E',
        DebugLogLevel.critical => 'C',
      };

  String get nameUpper => name.toUpperCase();
}

/// 单条日志。
class DebugLogEntry {
  DebugLogEntry({
    required this.message,
    this.level = DebugLogLevel.info,
    this.category = 'app',
    DateTime? timestamp,
    this.metadata,
    this.error,
    this.stackTrace,
    this.route,
    this.traceId,
  }) : timestamp = timestamp ?? DateTime.now(),
       id = _nextId++;

  static int _nextId = 0;

  final int id;
  final DateTime timestamp;
  final DebugLogLevel level;
  final String category;
  final String message;
  final Map<String, Object?>? metadata;
  final Object? error;
  final StackTrace? stackTrace;
  final String? route;
  final String? traceId;

  Map<String, Object?> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'category': category,
        'message': message,
        if (metadata != null) 'metadata': metadata,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (route != null) 'route': route,
        if (traceId != null) 'traceId': traceId,
      };

  /// 导出时的 NDJSON 行
  String toNdJson() => jsonEncode(toJson());
}

/// 有容量上限的环形日志存储。
class DebugLogStore {
  DebugLogStore({this.maxEntries = 600});

  final int maxEntries;

  final List<DebugLogEntry> _entries = [];
  final StreamController<List<DebugLogEntry>> _ctrl =
      StreamController.broadcast();

  /// 只读快照，新est在前。
  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  Stream<List<DebugLogEntry>> get stream => _ctrl.stream;

  int get length => _entries.length;

  void add(DebugLogEntry entry) {
    // 插入最前，保持时间倒序便于 UI 展示
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    _ctrl.add(entries);
  }

  void addAll(Iterable<DebugLogEntry> entries) {
    for (final e in entries) {
      add(e);
    }
  }

  void clear() {
    _entries.clear();
    _ctrl.add(entries);
  }

  List<DebugLogEntry> where({
    Set<DebugLogLevel>? levels,
    String? category,
    String? keyword,
  }) {
    return _entries.where((e) {
      if (levels != null && !levels.contains(e.level)) return false;
      if (category != null && category.isNotEmpty && e.category != category) {
        return false;
      }
      if (keyword != null && keyword.isNotEmpty) {
        final k = keyword.toLowerCase();
        if (!e.message.toLowerCase().contains(k) &&
            !(e.category.toLowerCase().contains(k)) &&
            !(e.error?.toString().toLowerCase().contains(k) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  Set<String> get categories =>
      _entries.map((e) => e.category).toSet();

  void dispose() {
    _ctrl.close();
  }
}

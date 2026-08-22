import 'dart:async';

import 'debug_log.dart';

/// 统一日志采集器：Zone 捕获、FlutterError、以及业务显式写入。
///
/// 设计上不直接替换全局 print，而是提供 [zoneSpec] 供 runZonedGuarded 使用，
/// 同时提供便捷的 [log]/[captureError] API。
class DebugLogCollector {
  DebugLogCollector({DebugLogStore? store})
      : store = store ?? DebugLogStore();

  final DebugLogStore store;

  /// 供 runZonedGuarded 传入的 ZoneSpecification。
  ZoneSpecification get zoneSpec => ZoneSpecification(
        print: (self, parent, zone, line) {
          // print 统一走 debug 级别，category=print
          store.add(DebugLogEntry(
            level: DebugLogLevel.debug,
            category: 'print',
            message: line,
          ));
          parent.print(zone, line);
        },
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
          store.add(DebugLogEntry(
            level: DebugLogLevel.error,
            category: 'uncaught',
            message: error.toString(),
            error: error,
            stackTrace: stackTrace,
          ));
          parent.handleUncaughtError(zone, error, stackTrace);
        },
      );

  /// 业务显式写入。
  void log(
    String message, {
    DebugLogLevel level = DebugLogLevel.info,
    String category = 'app',
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
    String? route,
    String? traceId,
  }) {
    store.add(DebugLogEntry(
      level: level,
      category: category,
      message: message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
      route: route,
      traceId: traceId,
    ));
  }

  void captureError(
    Object error,
    StackTrace? stackTrace, {
    String category = 'error',
    String? route,
  }) {
    store.add(DebugLogEntry(
      level: DebugLogLevel.error,
      category: category,
      message: error.toString(),
      error: error,
      stackTrace: stackTrace,
      route: route,
    ));
  }

  /// 快捷：info/warning/error
  void info(String m, {String category = 'app', Map<String, Object?>? data}) =>
      log(m, level: DebugLogLevel.info, category: category, metadata: data);
  void warning(String m, {String category = 'app', Map<String, Object?>? data}) =>
      log(m, level: DebugLogLevel.warning, category: category, metadata: data);
  void error(String m, {String category = 'app', Object? err, StackTrace? st}) =>
      log(m, level: DebugLogLevel.error, category: category, error: err, stackTrace: st);
}

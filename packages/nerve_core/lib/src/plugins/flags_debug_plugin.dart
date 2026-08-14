import '../debug_hub_plugin.dart';
import '../debug_hub_redactor.dart';

class FlagsDebugPlugin implements DebugHubPlugin {
  FlagsDebugPlugin(
    this.flags, {
    this.priority = 40,
    this.enabled = true,
    DebugHubRedactor? redactor,
  }) : _redactor = redactor ?? DebugHubRedactor();

  final Map<String, Object?> flags;
  final DebugHubRedactor _redactor;

  @override
  final int priority;

  @override
  final bool enabled;

  @override
  String get id => 'flags';

  @override
  String get title => 'Flags';

  @override
  DebugHubSummary summary() {
    final enabledCount = flags.values.where((value) => value == true).length;
    return DebugHubSummary(label: 'Enabled flags', value: '$enabledCount on');
  }

  Map<String, Object?> diagnostics() => _redactor.redact(flags);
}

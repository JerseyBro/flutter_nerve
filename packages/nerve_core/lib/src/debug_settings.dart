import 'debug_hub_plugin.dart';
import 'debug_hub_redactor.dart';

typedef DebugSettingsLoader = List<DebugSetting> Function();

typedef DebugSettingsApply =
    Future<DebugSettingsApplyResult> Function(Map<String, Object?> values);

enum DebugSettingType { select, boolean, text }

class DebugSettingOption {
  const DebugSettingOption({
    required this.value,
    required this.label,
    this.description,
  });

  final Object? value;
  final String label;
  final String? description;

  Map<String, Object?> toJson() => {
    'value': value,
    'label': label,
    if (description != null) 'description': description,
  };
}

class DebugSetting {
  const DebugSetting({
    required this.id,
    required this.label,
    required this.type,
    required this.currentValue,
    required this.defaultValue,
    this.description,
    this.group = 'General',
    this.options = const [],
    this.restartRequired = false,
    this.sensitive = false,
  });

  final String id;
  final String label;
  final String? description;
  final String group;
  final DebugSettingType type;
  final Object? currentValue;
  final Object? defaultValue;
  final List<DebugSettingOption> options;
  final bool restartRequired;
  final bool sensitive;

  bool get isDirty => currentValue != defaultValue;

  DebugSetting copyWith({
    Object? currentValue = _unset,
    Object? defaultValue = _unset,
  }) {
    return DebugSetting(
      id: id,
      label: label,
      description: description,
      group: group,
      type: type,
      currentValue: currentValue == _unset ? this.currentValue : currentValue,
      defaultValue: defaultValue == _unset ? this.defaultValue : defaultValue,
      options: options,
      restartRequired: restartRequired,
      sensitive: sensitive,
    );
  }

  Map<String, Object?> toDiagnostics(DebugHubRedactor redactor) {
    final payload = <String, Object?>{
      'id': id,
      'label': label,
      'group': group,
      'type': type.name,
      'currentValue': sensitive ? '[REDACTED]' : currentValue,
      'defaultValue': sensitive ? '[REDACTED]' : defaultValue,
      'restartRequired': restartRequired,
      'dirty': isDirty,
      if (description != null) 'description': description,
      if (options.isNotEmpty)
        'options': options.map((option) => option.toJson()).toList(),
    };
    return redactor.redact(payload);
  }

  Object? normalizedValue(Object? value) {
    switch (type) {
      case DebugSettingType.boolean:
        return value == true;
      case DebugSettingType.text:
        return value?.toString() ?? '';
      case DebugSettingType.select:
        final allowed = options.map((option) => option.value).toSet();
        if (allowed.isEmpty || allowed.contains(value)) return value;
        return currentValue;
    }
  }
}

class DebugSettingsApplyResult {
  const DebugSettingsApplyResult({
    this.message = 'Settings saved.',
    this.restartRequired = false,
  });

  final String message;
  final bool restartRequired;
}

class DebugSettingsPlugin implements DebugHubPlugin {
  DebugSettingsPlugin({
    required DebugSettingsLoader settings,
    DebugSettingsApply? onApply,
    this.priority = 30,
    this.enabled = true,
    DebugHubRedactor? redactor,
  }) : _settings = settings,
       _onApply = onApply,
       _redactor = redactor ?? DebugHubRedactor();

  final DebugSettingsLoader _settings;
  final DebugSettingsApply? _onApply;
  final DebugHubRedactor _redactor;

  @override
  final int priority;

  @override
  final bool enabled;

  @override
  String get id => 'settings';

  @override
  String get title => 'Settings';

  List<DebugSetting> settings() => List.unmodifiable(_settings());

  Future<DebugSettingsApplyResult> apply(Map<String, Object?> values) async {
    final current = settings();
    final normalized = <String, Object?>{
      for (final setting in current)
        if (values.containsKey(setting.id))
          setting.id: setting.normalizedValue(values[setting.id]),
    };
    final result =
        await (_onApply?.call(normalized) ??
            Future.value(const DebugSettingsApplyResult()));
    return DebugSettingsApplyResult(
      message: result.message,
      restartRequired:
          result.restartRequired ||
          current.any(
            (setting) =>
                setting.restartRequired &&
                normalized.containsKey(setting.id) &&
                normalized[setting.id] != setting.currentValue,
          ),
    );
  }

  Map<String, Object?> diagnostics() {
    return _redactor.redact({
      'settings': [
        for (final setting in settings()) setting.toDiagnostics(_redactor),
      ],
    });
  }

  @override
  DebugHubSummary summary() {
    final changedCount = settings().where((setting) => setting.isDirty).length;
    return DebugHubSummary(
      label: 'Debug settings',
      value: changedCount == 0 ? 'default' : '$changedCount changed',
      status: changedCount == 0 ? DebugHubStatus.ok : DebugHubStatus.warning,
    );
  }
}

const Object _unset = Object();

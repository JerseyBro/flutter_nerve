import 'package:nerve_core/nerve_core.dart';

DebugSettingsPlugin buildWenDebugSettingsPlugin({
  required String env,
  required bool forceReviewMode,
  DebugSettingsApply? onApply,
  List<String> environments = const ['dev', 'test', 'prod'],
  List<DebugSetting> extraSettings = const [],
}) {
  return DebugSettingsPlugin(
    settings: () => [
      DebugSetting(
        id: 'env',
        label: 'Environment',
        description: 'Saved changes require an app restart.',
        group: 'Runtime',
        type: DebugSettingType.select,
        currentValue: env,
        defaultValue: 'prod',
        options: [
          for (final value in environments)
            DebugSettingOption(value: value, label: _environmentLabel(value)),
        ],
        restartRequired: true,
      ),
      DebugSetting(
        id: 'FORCE_REVIEW_MODE',
        label: 'Force review mode',
        description: 'Local-only review-mode override for acceptance testing.',
        group: 'Runtime',
        type: DebugSettingType.boolean,
        currentValue: forceReviewMode,
        defaultValue: false,
        restartRequired: true,
      ),
      ...extraSettings,
    ],
    onApply: onApply,
  );
}

String _environmentLabel(String value) {
  return switch (value) {
    'dev' => 'Development',
    'test' => 'Test',
    'prod' => 'Production',
    _ => value,
  };
}

import 'package:flutter/material.dart';
import 'package:nerve_core/nerve_core.dart';
import 'package:nerve_flutter/src/debug_hub_overlay_host.dart';

class DebugHubSettingsPage extends StatefulWidget {
  const DebugHubSettingsPage({
    required this.actions,
    required this.plugin,
    super.key,
  });

  final DebugHubPluginPageActions actions;
  final DebugSettingsPlugin plugin;

  @override
  State<DebugHubSettingsPage> createState() => _DebugHubSettingsPageState();
}

class _DebugHubSettingsPageState extends State<DebugHubSettingsPage> {
  late Map<String, Object?> _values;
  bool _submitting = false;
  String? _statusMessage;
  String? _errorMessage;
  bool _restartRequired = false;

  List<DebugSetting> get _settings => widget.plugin.settings();

  @override
  void initState() {
    super.initState();
    _values = _initialValues();
  }

  @override
  void didUpdateWidget(DebugHubSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plugin != widget.plugin) {
      _values = _initialValues();
      _statusMessage = null;
      _errorMessage = null;
      _restartRequired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final hasChanges = settings.any(
      (setting) => _values[setting.id] != setting.currentValue,
    );
    final groups = <String, List<DebugSetting>>{};
    for (final setting in settings) {
      groups.putIfAbsent(setting.group, () => []).add(setting);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsHeader(actions: widget.actions),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in groups.entries) ...[
                    _GroupHeader(title: entry.key),
                    const SizedBox(height: 8),
                    for (final setting in entry.value) ...[
                      _SettingTile(
                        setting: setting,
                        value: _values[setting.id],
                        onChanged: (value) {
                          setState(() {
                            _values[setting.id] = value;
                            _statusMessage = null;
                            _errorMessage = null;
                            _restartRequired = false;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              _MessageBanner.error(_errorMessage!),
              const SizedBox(height: 10),
            ] else if (_restartRequired) ...[
              _MessageBanner.warning(
                _statusMessage ?? 'Saved. Restart the app to apply changes.',
              ),
              const SizedBox(height: 10),
            ] else if (_statusMessage != null) ...[
              _MessageBanner.ok(_statusMessage!),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('debug-settings-reset'),
                    onPressed: hasChanges && !_submitting ? _reset : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF394150)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('debug-settings-apply'),
                    onPressed: hasChanges && !_submitting ? _apply : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC400),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(_submitting ? 'Applying...' : 'Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Object?> _initialValues() => {
    for (final setting in _settings) setting.id: setting.currentValue,
  };

  void _reset() {
    setState(() {
      _values = _initialValues();
      _statusMessage = null;
      _errorMessage = null;
      _restartRequired = false;
    });
  }

  Future<void> _apply() async {
    setState(() {
      _submitting = true;
      _statusMessage = null;
      _errorMessage = null;
      _restartRequired = false;
    });
    try {
      final result = await widget.plugin.apply(_values);
      if (!mounted) return;
      setState(() {
        _statusMessage = result.message;
        _restartRequired = result.restartRequired;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.actions});

  final DebugHubPluginPageActions actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIcon(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: actions.showHome,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _ActionIcon(icon: Icons.close_rounded, onTap: actions.dismiss),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.setting,
    required this.value,
    required this.onChanged,
  });

  final DebugSetting setting;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B303B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setting.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (setting.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        setting.description!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (setting.restartRequired)
                const Icon(
                  Icons.restart_alt_rounded,
                  key: ValueKey('debug-settings-restart-required'),
                  color: Color(0xFFFFC400),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingControl(setting: setting, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingControl extends StatelessWidget {
  const _SettingControl({
    required this.setting,
    required this.value,
    required this.onChanged,
  });

  final DebugSetting setting;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (setting.type) {
      case DebugSettingType.select:
        return _InlineSelectControl(
          key: ValueKey('debug-setting-${setting.id}'),
          options: setting.options,
          value: value,
          onChanged: onChanged,
        );
      case DebugSettingType.boolean:
        return SwitchListTile.adaptive(
          key: ValueKey('debug-setting-${setting.id}'),
          value: value == true,
          onChanged: onChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            value == true ? 'true' : 'false',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          activeThumbColor: const Color(0xFFFFC400),
        );
      case DebugSettingType.text:
        return TextFormField(
          key: ValueKey('debug-setting-${setting.id}'),
          initialValue: value?.toString() ?? '',
          obscureText: setting.sensitive,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(),
          onChanged: onChanged,
        );
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF10131A),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF343A46)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFFC400)),
      ),
    );
  }
}

class _InlineSelectControl extends StatelessWidget {
  const _InlineSelectControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<DebugSettingOption> options;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _SelectOptionButton(
            option: option,
            selected: option.value == value,
            onTap: () => onChanged(option.value),
          ),
      ],
    );
  }
}

class _SelectOptionButton extends StatelessWidget {
  const _SelectOptionButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DebugSettingOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFFFC400)
        : const Color(0xFF343A46);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFF2A2614) : const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              option.label,
              style: TextStyle(
                color: selected ? const Color(0xFFFFC400) : Colors.white,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner._({
    required this.message,
    required this.color,
    required this.icon,
  });

  const _MessageBanner.ok(String message)
    : this._(
        message: message,
        color: const Color(0xFF4ADE80),
        icon: Icons.check_circle_outline_rounded,
      );

  const _MessageBanner.warning(String message)
    : this._(
        message: message,
        color: const Color(0xFFFFC400),
        icon: Icons.restart_alt_rounded,
      );

  const _MessageBanner.error(String message)
    : this._(
        message: message,
        color: const Color(0xFFF87171),
        icon: Icons.error_outline_rounded,
      );

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('debug-settings-message'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
      ),
    );
  }
}

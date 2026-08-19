import 'package:flutter/material.dart';
import 'package:nerve_flutter/src/debug_hub_overlay_host.dart';

typedef DebugHubEnvironmentApply = Future<void> Function(String environment);

class DebugHubEnvironmentOption {
  const DebugHubEnvironmentOption({
    required this.value,
    required this.label,
    this.description,
  });

  final String value;
  final String label;
  final String? description;
}

class DebugHubEnvironmentPage extends StatefulWidget {
  const DebugHubEnvironmentPage({
    required this.actions,
    required this.currentEnvironment,
    required this.options,
    required this.onApply,
    super.key,
  });

  final DebugHubPluginPageActions actions;
  final String currentEnvironment;
  final List<DebugHubEnvironmentOption> options;
  final DebugHubEnvironmentApply onApply;

  @override
  State<DebugHubEnvironmentPage> createState() => _DebugHubEnvironmentPageState();
}

class _DebugHubEnvironmentPageState extends State<DebugHubEnvironmentPage> {
  late String _selectedEnvironment;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = widget.currentEnvironment;
  }

  @override
  Widget build(BuildContext context) {
    final hasChange = _selectedEnvironment != widget.currentEnvironment;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ActionIcon(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: widget.actions.showHome,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Environment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ActionIcon(
                  icon: Icons.close_rounded,
                  onTap: widget.actions.dismiss,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select the runtime environment and restart the app to apply.',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: widget.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final selected = option.value == _selectedEnvironment;
                  return _EnvironmentOptionTile(
                    key: ValueKey('environment-option-${option.value}'),
                    option: option,
                    selected: selected,
                    onTap: () => setState(() => _selectedEnvironment = option.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: !hasChange || _submitting ? null : _applySelected,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC400),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                _submitting ? 'Applying...' : 'Switch & Restart',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applySelected() async {
    setState(() => _submitting = true);
    try {
      await widget.onApply(_selectedEnvironment);
      if (mounted) {
        widget.actions.dismiss();
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _EnvironmentOptionTile extends StatelessWidget {
  const _EnvironmentOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DebugHubEnvironmentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1D2030) : const Color(0xFF171A22),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFFFC400) : const Color(0xFF2B303B),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (option.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.description!,
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
              if (selected)
                const Icon(Icons.check_rounded, color: Color(0xFFFFC400)),
            ],
          ),
        ),
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

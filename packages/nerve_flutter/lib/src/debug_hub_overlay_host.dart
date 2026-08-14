import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerve_core/nerve_core.dart';

class DebugHubOverlayHost extends StatelessWidget {
  const DebugHubOverlayHost({
    required this.enabled,
    required this.controller,
    required this.child,
    super.key,
  });

  final bool enabled;
  final DebugHubController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (enabled)
          Positioned(
            right: 20 + MediaQuery.paddingOf(context).right,
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
            child: _NerveLauncher(controller: controller),
          ),
      ],
    );
  }
}

class _NerveLauncher extends StatelessWidget {
  const _NerveLauncher({required this.controller});

  final DebugHubController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'Open Nerve',
        child: FloatingActionButton.small(
          heroTag: 'nerve-debug-launcher',
          backgroundColor: const Color(0xFF16181D),
          foregroundColor: Colors.white,
          onPressed: () => _showNervePanel(context, controller),
          child: const Icon(Icons.bolt_rounded, size: 20),
        ),
      ),
    );
  }
}

void _showNervePanel(BuildContext context, DebugHubController controller) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101216),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _NervePanel(controller: controller),
  );
}

class _NervePanel extends StatelessWidget {
  const _NervePanel({required this.controller});

  final DebugHubController controller;

  @override
  Widget build(BuildContext context) {
    final plugins = controller.plugins;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nerve',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy diagnostics',
                  color: Colors.white70,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: controller.exportDiagnostics().toString(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plugins.isEmpty)
              const _EmptyPluginState()
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final plugin = plugins[index];
                    return _PluginTile(plugin: plugin);
                  },
                  separatorBuilder: (_, _) =>
                      const Divider(color: Color(0xFF252A33), height: 1),
                  itemCount: plugins.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PluginTile extends StatelessWidget {
  const _PluginTile({required this.plugin});

  final DebugHubPlugin plugin;

  @override
  Widget build(BuildContext context) {
    final summary = plugin.summary();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        plugin.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        summary.label,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: Text(
        summary.value,
        style: TextStyle(
          color: _statusColor(summary.status),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(DebugHubStatus status) {
    return switch (status) {
      DebugHubStatus.ok => const Color(0xFF4ADE80),
      DebugHubStatus.warning => const Color(0xFFFACC15),
      DebugHubStatus.error => const Color(0xFFF87171),
      DebugHubStatus.neutral => Colors.white,
    };
  }
}

class _EmptyPluginState extends StatelessWidget {
  const _EmptyPluginState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'No debug plugins registered.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}

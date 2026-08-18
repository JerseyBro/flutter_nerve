import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerve_core/nerve_core.dart';

/// Host widget that overlays the Nerve launcher and panel on top of [child].
///
/// Self-contained by design: it requires no [Overlay] or [Navigator] ancestor,
/// so it works both inside a `MaterialApp.builder` (above the navigator) and
/// as a plain `home:` widget (below the navigator).
class DebugHubOverlayHost extends StatefulWidget {
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
  State<DebugHubOverlayHost> createState() => _DebugHubOverlayHostState();
}

class _DebugHubOverlayHostState extends State<DebugHubOverlayHost> {
  bool _panelVisible = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            right: 20 + MediaQuery.paddingOf(context).right,
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
            child: _NerveLauncher(onPressed: _openPanel),
          ),
        if (widget.enabled && _panelVisible)
          Positioned.fill(
            child: _NervePanelOverlay(
              controller: widget.controller,
              onDismiss: _closePanel,
            ),
          ),
      ],
    );
  }

  void _openPanel() => setState(() => _panelVisible = true);

  void _closePanel() => setState(() => _panelVisible = false);
}

class _NerveLauncher extends StatelessWidget {
  const _NerveLauncher({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open Nerve debug console',
      button: true,
      child: FloatingActionButton.small(
        heroTag: 'nerve-debug-launcher',
        backgroundColor: const Color(0xFF16181D),
        foregroundColor: Colors.white,
        onPressed: onPressed,
        child: const Icon(Icons.bolt_rounded, size: 20),
      ),
    );
  }
}

class _NervePanelOverlay extends StatelessWidget {
  const _NervePanelOverlay({
    required this.controller,
    required this.onDismiss,
  });

  final DebugHubController controller;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 160),
            builder: (context, opacity, _) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: ColoredBox(color: Color.fromRGBO(0, 0, 0, opacity * 0.6)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - t)),
                child: child,
              ),
            ),
            child: Material(
              color: const Color(0xFF101216),
              clipBehavior: Clip.antiAlias,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
                child: _NervePanel(
                  controller: controller,
                  onDismiss: onDismiss,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NervePanel extends StatelessWidget {
  const _NervePanel({required this.controller, required this.onDismiss});

  final DebugHubController controller;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final plugins = controller.plugins;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                IconButton(
                  color: Colors.white70,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onDismiss,
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

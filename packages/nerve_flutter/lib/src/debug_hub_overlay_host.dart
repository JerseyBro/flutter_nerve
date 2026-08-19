import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerve_core/nerve_core.dart';

typedef DebugHubPluginPageBuilder =
    Widget Function(BuildContext context, DebugHubPluginPageActions actions);

class DebugHubPluginPageActions {
  const DebugHubPluginPageActions({
    required this.showHome,
    required this.dismiss,
  });

  final VoidCallback showHome;
  final VoidCallback dismiss;
}

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
    this.pluginPages = const {},
    this.launchPluginId,
    super.key,
  });

  final bool enabled;
  final DebugHubController controller;
  final Widget child;
  final Map<String, DebugHubPluginPageBuilder> pluginPages;
  final String? launchPluginId;

  @override
  State<DebugHubOverlayHost> createState() => _DebugHubOverlayHostState();
}

class _DebugHubOverlayHostState extends State<DebugHubOverlayHost> {
  bool _panelVisible = false;
  String? _activePluginId;

  static const _kLauncherSize = 44.0;
  static const _kLauncherMargin = 20.0;
  static const _kLauncherBottomOffset = 96.0;

  // Draggable launcher state — absolute left/top position.
  Offset? _launcherPosition;
  Offset? _dragStartGlobalPosition;
  Offset? _dragStartLauncherPosition;
  bool _launcherDragged = false;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final screen = MediaQuery.sizeOf(context);

    // Default: bottom-right with safe-area padding.
    final defaultX =
        screen.width - _kLauncherSize - _kLauncherMargin - padding.right;
    final defaultY = screen.height -
        _kLauncherSize -
        _kLauncherBottomOffset -
        padding.bottom;
    final pos = _clampLauncherPosition(
      _launcherPosition ?? Offset(defaultX, defaultY),
      screen,
      padding,
    );

    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            left: pos.dx.clamp(0, screen.width - _kLauncherSize),
            top: pos.dy.clamp(0, screen.height - _kLauncherSize),
            child: _NerveLauncher(
              key: const ValueKey('nerve-debug-launcher'),
              onPanStart: (details) => _handleLauncherPanStart(details),
              onPanUpdate: (details) => _handleLauncherPanUpdate(
                details,
                screen,
                padding,
              ),
              onPanEnd: _handleLauncherPanEnd,
              onPanCancel: _resetLauncherDragState,
              onTap: _openPanel,
            ),
          ),
        if (widget.enabled && _panelVisible)
          Positioned.fill(
            child: _NervePanelOverlay(
              controller: widget.controller,
              pluginPages: widget.pluginPages,
              activePluginId: _activePluginId,
              onDismiss: _closePanel,
              onOpenPlugin: _openPluginPage,
              onShowHome: _showHome,
            ),
          ),
      ],
    );
  }

  void _openPanel() => setState(() {
    _activePluginId = widget.launchPluginId;
    _panelVisible = true;
  });

  void _openPluginPage(String pluginId) => setState(() {
    _activePluginId = pluginId;
  });

  void _showHome() => setState(() {
    _activePluginId = null;
  });

  void _closePanel() => setState(() {
    _panelVisible = false;
    _activePluginId = null;
  });

  void _handleLauncherPanStart(DragStartDetails details) {
    _dragStartGlobalPosition = details.globalPosition;
    _dragStartLauncherPosition =
        _launcherPosition ?? const Offset(_kLauncherMargin, _kLauncherMargin);
    _launcherDragged = false;
  }

  void _handleLauncherPanUpdate(
    DragUpdateDetails details,
    Size screen,
    EdgeInsets padding,
  ) {
    final dragStartLauncherPosition = _dragStartLauncherPosition;
    final dragStartGlobalPosition = _dragStartGlobalPosition;
    if (dragStartGlobalPosition == null || dragStartLauncherPosition == null) {
      return;
    }
    final delta = details.globalPosition - dragStartGlobalPosition;
    if (!_launcherDragged && delta.distance < 6) {
      return;
    }
    if (!_launcherDragged) {
      _launcherDragged = true;
    }
    setState(() {
      _launcherPosition = _clampLauncherPosition(
        dragStartLauncherPosition + delta,
        screen,
        padding,
      );
    });
  }

  void _handleLauncherPanEnd(DragEndDetails details) {
    final wasDragged = _launcherDragged;
    _resetLauncherDragState();
    if (!wasDragged) _openPanel();
  }

  void _resetLauncherDragState([PointerEvent? event]) {
    _dragStartGlobalPosition = null;
    _dragStartLauncherPosition = null;
    _launcherDragged = false;
  }

  Offset _clampLauncherPosition(
    Offset position,
    Size screen,
    EdgeInsets padding,
  ) {
    final minX = _kLauncherMargin + padding.left;
    final minY = _kLauncherMargin + padding.top;
    final maxX = math.max(
      minX,
      screen.width - _kLauncherSize - _kLauncherMargin - padding.right,
    );
    final maxY = math.max(
      minY,
      screen.height - _kLauncherSize - _kLauncherMargin - padding.bottom,
    );
    return Offset(
      position.dx.clamp(minX, maxX),
      position.dy.clamp(minY, maxY),
    );
  }
}

class _NerveLauncher extends StatelessWidget {
  const _NerveLauncher({
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.onTap,
    super.key,
  });

  final void Function(DragStartDetails details) onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final void Function(DragEndDetails details) onPanEnd;
  final VoidCallback onPanCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open Nerve debug console',
      button: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        onPanCancel: onPanCancel,
        child: Material(
          color: const Color(0xFF16181D),
          shape: const CircleBorder(),
          elevation: 6,
          child: const SizedBox.square(
            dimension: _DebugHubOverlayHostState._kLauncherSize,
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _NervePanelOverlay extends StatelessWidget {
  const _NervePanelOverlay({
    required this.controller,
    required this.pluginPages,
    required this.activePluginId,
    required this.onDismiss,
    required this.onOpenPlugin,
    required this.onShowHome,
  });

  final DebugHubController controller;
  final Map<String, DebugHubPluginPageBuilder> pluginPages;
  final String? activePluginId;
  final VoidCallback onDismiss;
  final ValueChanged<String> onOpenPlugin;
  final VoidCallback onShowHome;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final activePage = activePluginId == null
        ? null
        : pluginPages[activePluginId];
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
                child: activePage == null
                    ? _NervePanel(
                        controller: controller,
                        pluginPages: pluginPages,
                        onDismiss: onDismiss,
                        onOpenPlugin: onOpenPlugin,
                      )
                    : activePage(
                        context,
                        DebugHubPluginPageActions(
                          showHome: onShowHome,
                          dismiss: onDismiss,
                        ),
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
  const _NervePanel({
    required this.controller,
    required this.pluginPages,
    required this.onDismiss,
    required this.onOpenPlugin,
  });

  final DebugHubController controller;
  final Map<String, DebugHubPluginPageBuilder> pluginPages;
  final VoidCallback onDismiss;
  final ValueChanged<String> onOpenPlugin;

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
                _NerveIconAction(
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: controller.exportDiagnostics().toString(),
                      ),
                    );
                  },
                ),
                _NerveIconAction(
                  icon: Icons.close_rounded,
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
                    return _PluginTile(
                      plugin: plugin,
                      canOpen: pluginPages.containsKey(plugin.id),
                      onTap: () => onOpenPlugin(plugin.id),
                    );
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

class _NerveIconAction extends StatelessWidget {
  const _NerveIconAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }
}

class _PluginTile extends StatelessWidget {
  const _PluginTile({
    required this.plugin,
    required this.canOpen,
    required this.onTap,
  });

  final DebugHubPlugin plugin;
  final bool canOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = plugin.summary();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: canOpen ? onTap : null,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary.value,
            style: TextStyle(
              color: _statusColor(summary.status),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canOpen) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ],
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

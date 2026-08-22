import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerve_core/nerve_core.dart';

import '../debug_hub_overlay_host.dart';

class DebugHubLogsPage extends StatefulWidget {
  const DebugHubLogsPage({
    required this.actions,
    required this.store,
    required this.redactor,
    super.key,
  });

  final DebugHubPluginPageActions actions;
  final DebugLogStore store;
  final DebugHubRedactor redactor;

  @override
  State<DebugHubLogsPage> createState() => _DebugHubLogsPageState();
}

class _DebugHubLogsPageState extends State<DebugHubLogsPage> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';
  Set<DebugLogLevel> _levels = {
    DebugLogLevel.verbose,
    DebugLogLevel.debug,
    DebugLogLevel.info,
    DebugLogLevel.warning,
    DebugLogLevel.error,
    DebugLogLevel.critical,
  };
  String _category = '全部';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _keyword = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([]),
        builder: (context, _) {
          return StreamBuilder<List<DebugLogEntry>>(
            stream: widget.store.stream,
            initialData: widget.store.entries,
            builder: (context, snap) {
              final all = snap.data ?? widget.store.entries;
              final categories = <String>{'全部', ...all.map((e) => e.category)};
              final filtered = all.where((e) {
                if (!_levels.contains(e.level)) return false;
                if (_category != '全部' && e.category != _category) return false;
                if (_keyword.isNotEmpty) {
                  final k = _keyword.toLowerCase();
                  if (!e.message.toLowerCase().contains(k) &&
                      !e.category.toLowerCase().contains(k) &&
                      !(e.error?.toString().toLowerCase().contains(k) ?? false)) {
                    return false;
                  }
                }
                return true;
              }).toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      actions: widget.actions,
                      count: filtered.length,
                      onClear: () => widget.store.clear(),
                      onExport: () => _export(filtered),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '搜索 message / category / error',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                        suffixIcon: _keyword.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                                onPressed: () => _searchCtrl.clear(),
                              ),
                        filled: true,
                        fillColor: const Color(0xFF171A22),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2B303B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2B303B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LevelFilter(levels: _levels, onChanged: (s) => setState(() => _levels = s)),
                    const SizedBox(height: 8),
                    _CategoryFilter(
                      categories: categories.toList()..sort(),
                      selected: _category,
                      onSelected: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('暂无日志', style: TextStyle(color: Colors.white54)),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final e = filtered[i];
                                return _LogTile(
                                  entry: e,
                                  redactor: widget.redactor,
                                  onCopy: () => _copy(e),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _copy(DebugLogEntry e) {
    final text = '[${e.level.nameUpper}] ${e.category} ${e.message}'
        '${e.error != null ? '\nError: ${e.error}' : ''}'
        '${e.stackTrace != null ? '\n${e.stackTrace}' : ''}';
    Clipboard.setData(ClipboardData(text: widget.redactor.redactText(text)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制（已脱敏）'), duration: Duration(milliseconds: 900)),
    );
  }

  void _export(List<DebugLogEntry> entries) {
    final jsonList = entries.map((e) {
      final m = e.toJson();
      // 导出前对 message/error 脱敏
      m['message'] = widget.redactor.redactText(e.message);
      if (m['error'] != null) m['error'] = widget.redactor.redactText(m['error'].toString());
      return m;
    }).toList();
    final text = const JsonEncoder.withIndent('  ').convert(jsonList);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制 ${entries.length} 条（JSON，已脱敏）')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.actions, required this.count, required this.onClear, required this.onExport});
  final DebugHubPluginPageActions actions;
  final int count;
  final VoidCallback onClear;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: actions.showHome),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Logs', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text('$count 条', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('清空', style: TextStyle(color: Colors.white70))),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: onExport,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black),
          child: const Text('复制JSON'),
        ),
        const SizedBox(width: 8),
        _ActionIcon(icon: Icons.close_rounded, onTap: actions.dismiss),
      ],
    );
  }
}

class _LevelFilter extends StatelessWidget {
  const _LevelFilter({required this.levels, required this.onChanged});
  final Set<DebugLogLevel> levels;
  final ValueChanged<Set<DebugLogLevel>> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(DebugLogLevel l) {
      final sel = levels.contains(l);
      return FilterChip(
        label: Text(l.nameUpper, style: TextStyle(color: sel ? Colors.black : Colors.white70, fontSize: 11)),
        selected: sel,
        selectedColor: const Color(0xFFFFC400),
        backgroundColor: const Color(0xFF1D2030),
        checkmarkColor: Colors.black,
        onSelected: (v) {
          final next = Set<DebugLogLevel>.from(levels);
          if (v) {
            next.add(l);
          } else {
            next.remove(l);
          }
          if (next.isEmpty) return;
          onChanged(next);
        },
      );
    }

    return Wrap(spacing: 6, runSpacing: 6, children: DebugLogLevel.values.map(chip).toList());
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.categories, required this.selected, required this.onSelected});
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(c, style: TextStyle(color: c == selected ? Colors.black : Colors.white70, fontSize: 12)),
                selected: c == selected,
                selectedColor: const Color(0xFF2A2614),
                backgroundColor: const Color(0xFF171A22),
                onSelected: (_) => onSelected(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.redactor, required this.onCopy});
  final DebugLogEntry entry;
  final DebugHubRedactor redactor;
  final VoidCallback onCopy;

  Color _levelColor(DebugLogLevel l) => switch (l) {
        DebugLogLevel.verbose => Colors.white38,
        DebugLogLevel.debug => const Color(0xFF8E8E92),
        DebugLogLevel.info => const Color(0xFF4ADE80),
        DebugLogLevel.warning => const Color(0xFFFACC15),
        DebugLogLevel.error => const Color(0xFFF87171),
        DebugLogLevel.critical => const Color(0xFFFF3859),
      };

  @override
  Widget build(BuildContext context) {
    final msg = redactor.redactText(entry.message);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B303B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _levelColor(entry.level).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                child: Text(entry.level.nameUpper, style: TextStyle(color: _levelColor(entry.level), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.category, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
              Text(
                '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy_rounded, color: Colors.white38, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(msg, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
          if (entry.error != null) ...[
            const SizedBox(height: 6),
            Text(redactor.redactText(entry.error.toString()), style: const TextStyle(color: Color(0xFFF87171), fontSize: 11)),
          ],
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 6),
            Text(
              entry.stackTrace.toString().split('\n').take(6).join('\n'),
              style: const TextStyle(color: Colors.white38, fontSize: 10, height: 1.2),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.metadata.toString(),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white70, size: 22)),
      ),
    );
  }
}

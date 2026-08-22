import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerve_core/nerve_core.dart';

import '../debug_hub_overlay_host.dart';

class DebugHubStoragePage extends StatefulWidget {
  const DebugHubStoragePage({
    required this.actions,
    required this.snapshotProvider,
    required this.redactor,
    super.key,
  });

  final DebugHubPluginPageActions actions;
  final Map<String, Object?> Function() snapshotProvider;
  final DebugHubRedactor redactor;

  @override
  State<DebugHubStoragePage> createState() => _DebugHubStoragePageState();
}

class _DebugHubStoragePageState extends State<DebugHubStoragePage> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _keyword = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshotProvider();
    final redacted = widget.redactor.redact(snapshot);
    final entries = redacted.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final filtered = _keyword.isEmpty
        ? entries
        : entries.where((e) {
            final k = _keyword.toLowerCase();
            return e.key.toLowerCase().contains(k) ||
                (e.value?.toString().toLowerCase().contains(k) ?? false);
          }).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ActionIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: widget.actions.showHome),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Storage', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                _CopyAllButton(snapshot: redacted),
                const SizedBox(width: 8),
                _ActionIcon(icon: Icons.close_rounded, onTap: widget.actions.dismiss),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2030),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2B303B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('只读查看，不支持修改', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                  Text('${entries.length} keys', style: const TextStyle(color: Color(0xFFFFC400), fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索 key / value',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18), onPressed: () => _searchCtrl.clear()),
                filled: true,
                fillColor: const Color(0xFF171A22),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2B303B))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2B303B))),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(snapshot.isEmpty ? '暂无数据' : '无匹配结果', style: const TextStyle(color: Colors.white54)),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return _StorageTile(keyName: e.key, value: e.value, redactor: widget.redactor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyAllButton extends StatelessWidget {
  const _CopyAllButton({required this.snapshot});
  final Map<String, Object?> snapshot;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: snapshot.toString()));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制（已脱敏）'), duration: Duration(milliseconds: 900)));
      },
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black, minimumSize: const Size(0, 36)),
      child: const Text('复制'),
    );
  }
}

class _StorageTile extends StatelessWidget {
  const _StorageTile({required this.keyName, required this.value, required this.redactor});
  final String keyName;
  final Object? value;
  final DebugHubRedactor redactor;

  @override
  Widget build(BuildContext context) {
    final display = value?.toString() ?? 'null';
    final truncated = display.length > 200 ? '${display.substring(0, 200)}…' : display;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B303B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(keyName, style: const TextStyle(color: Color(0xFFFFC400), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SelectableText(truncated, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: '$keyName: $value'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), duration: Duration(milliseconds: 700)));
            },
            child: const Icon(Icons.copy_rounded, color: Colors.white38, size: 16),
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
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white70, size: 22)),
      ),
    );
  }
}

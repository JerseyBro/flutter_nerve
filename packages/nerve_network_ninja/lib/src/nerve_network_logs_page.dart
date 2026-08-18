import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerve_core/nerve_core.dart';
import 'package:nerve_flutter/nerve_flutter.dart';
import 'package:network_ninja/network_ninja.dart';

class NerveNetworkLogsPage extends StatefulWidget {
  const NerveNetworkLogsPage({required this.actions, this.redactor, super.key});

  final DebugHubPluginPageActions actions;
  final DebugHubRedactor? redactor;

  @override
  State<NerveNetworkLogsPage> createState() => _NerveNetworkLogsPageState();
}

class _NerveNetworkLogsPageState extends State<NerveNetworkLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  final NetworkLogsService _logsService = NetworkLogsService.instance;
  late final DebugHubRedactor _redactor;
  StreamSubscription<List<NetworkLog>>? _logsSubscription;

  List<NetworkLog> _logs = const [];
  NetworkLog? _selectedLog;
  _NerveNetworkFilter _filter = _NerveNetworkFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _redactor = widget.redactor ?? DebugHubRedactor();
    _logs = _logsService.logs;
    _logsSubscription = _logsService.logsStream.listen((logs) {
      if (!mounted) return;
      setState(() {
        _logs = logs;
        if (_selectedLog != null) {
          for (final log in logs) {
            if (log.id == _selectedLog!.id) {
              _selectedLog = log;
              return;
            }
          }
          _selectedLog = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _logsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: _selectedLog == null
          ? _NerveNetworkListView(
              logs: _filteredLogs,
              totalCount: _logs.length,
              filter: _filter,
              queryController: _searchController,
              query: _query,
              onQueryChanged: (value) => setState(() => _query = value),
              onFilterChanged: (value) => setState(() => _filter = value),
              onClearLogs: _clearLogs,
              onClose: widget.actions.dismiss,
              onBack: widget.actions.showHome,
              onSelectLog: (log) => setState(() => _selectedLog = log),
            )
          : _NerveNetworkDetailView(
              log: _selectedLog!,
              redactor: _redactor,
              onBack: () => setState(() => _selectedLog = null),
              onClose: widget.actions.dismiss,
            ),
    );
  }

  List<NetworkLog> get _filteredLogs {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _logs.where((log) {
      final matchesFilter = switch (_filter) {
        _NerveNetworkFilter.all => true,
        _NerveNetworkFilter.success => log.isSuccess,
        _NerveNetworkFilter.error => log.hasError,
        _NerveNetworkFilter.pending => log.responseStatus == null,
      };
      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;
      return log.method.toLowerCase().contains(normalizedQuery) ||
          log.endpoint.toLowerCase().contains(normalizedQuery) ||
          log.statusText.toLowerCase().contains(normalizedQuery);
    }).toList();
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  void _clearLogs() {
    _logsService.clearLogs();
    setState(() => _selectedLog = null);
  }
}

enum _NerveNetworkFilter { all, success, error, pending }

class _NerveNetworkListView extends StatelessWidget {
  const _NerveNetworkListView({
    required this.logs,
    required this.totalCount,
    required this.filter,
    required this.queryController,
    required this.query,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onClearLogs,
    required this.onClose,
    required this.onBack,
    required this.onSelectLog,
  });

  final List<NetworkLog> logs;
  final int totalCount;
  final _NerveNetworkFilter filter;
  final TextEditingController queryController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_NerveNetworkFilter> onFilterChanged;
  final VoidCallback onClearLogs;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final ValueChanged<NetworkLog> onSelectLog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NerveToolbar(
            title: 'Network Logs',
            subtitle: '$totalCount captured',
            leadingIcon: Icons.arrow_back_ios_new_rounded,
            onLeadingPressed: onBack,
            onClose: onClose,
            actions: [
              IconButton(
                tooltip: 'Clear logs',
                color: Colors.white70,
                icon: const Icon(Icons.clear_all_rounded),
                onPressed: totalCount == 0 ? null : onClearLogs,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SearchField(
            controller: queryController,
            query: query,
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 12),
          _FilterChips(filter: filter, onChanged: onFilterChanged),
          const SizedBox(height: 12),
          Expanded(
            child: logs.isEmpty
                ? _EmptyNetworkState(hasQuery: query.trim().isNotEmpty)
                : ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _NetworkLogTile(
                      log: logs[index],
                      onTap: () => onSelectLog(logs[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NerveToolbar extends StatelessWidget {
  const _NerveToolbar({
    required this.title,
    required this.onClose,
    this.subtitle,
    this.leadingIcon,
    this.onLeadingPressed,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final List<Widget> actions;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null)
          IconButton(
            color: Colors.white,
            icon: Icon(leadingIcon),
            onPressed: onLeadingPressed,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
        ),
        ...actions,
        IconButton(
          color: Colors.white70,
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search URL, method, or status',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                color: Colors.white54,
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: const Color(0xFF1B1D26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final _NerveNetworkFilter filter;
  final ValueChanged<_NerveNetworkFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in _NerveNetworkFilter.values) ...[
            _FilterChip(
              label: item.name.toUpperCase(),
              selected: item == filter,
              onTap: () => onChanged(item),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFC400) : const Color(0xFF191B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFFFC400) : const Color(0xFF2A2E3A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NetworkLogTile extends StatelessWidget {
  const _NetworkLogTile({required this.log, required this.onTap});

  final NetworkLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF191B2D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF262A3A)),
        ),
        child: Row(
          children: [
            _StatusMark(log: log),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.method.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          log.endpoint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTime(log.timestamp),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        log.statusText,
                        style: TextStyle(
                          color: _statusColor(log),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (log.durationText.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          log.durationText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.log});

  final NetworkLog log;

  @override
  Widget build(BuildContext context) {
    return Icon(
      log.responseStatus == null
          ? Icons.hourglass_top_rounded
          : log.hasError
          ? Icons.error_rounded
          : Icons.check_circle_rounded,
      color: _statusColor(log),
      size: 26,
    );
  }
}

class _EmptyNetworkState extends StatelessWidget {
  const _EmptyNetworkState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.cloud_off_rounded,
            size: 48,
            color: Colors.white30,
          ),
          const SizedBox(height: 14),
          Text(
            hasQuery ? 'No matching requests' : 'No network requests yet',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Captured Dio requests will appear here.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NerveNetworkDetailView extends StatelessWidget {
  const _NerveNetworkDetailView({
    required this.log,
    required this.redactor,
    required this.onBack,
    required this.onClose,
  });

  final NetworkLog log;
  final DebugHubRedactor redactor;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NerveToolbar(
            title: '${log.method.toUpperCase()} ${log.statusText}',
            subtitle: log.endpoint,
            leadingIcon: Icons.arrow_back_ios_new_rounded,
            onLeadingPressed: onBack,
            onClose: onClose,
            actions: [
              PopupMenuButton<_CopyAction>(
                iconColor: Colors.white70,
                color: const Color(0xFF1D2028),
                onSelected: (action) => _copy(context, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _CopyAction.url,
                    child: Text('Copy URL'),
                  ),
                  PopupMenuItem(
                    value: _CopyAction.curl,
                    child: Text('Copy cURL'),
                  ),
                  PopupMenuItem(
                    value: _CopyAction.request,
                    child: Text('Copy Request'),
                  ),
                  PopupMenuItem(
                    value: _CopyAction.response,
                    child: Text('Copy Response'),
                  ),
                  PopupMenuItem(
                    value: _CopyAction.json,
                    child: Text('Copy JSON'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _DetailSection(
                  title: 'Summary',
                  child: _KeyValueBlock(
                    values: {
                      'Method': log.method.toUpperCase(),
                      'Status': log.statusText,
                      'Duration': log.durationText.isEmpty
                          ? '-'
                          : log.durationText,
                      'Time': _formatTime(log.timestamp),
                      'URL': log.endpoint,
                    },
                  ),
                ),
                _DetailSection(
                  title: 'Request Headers',
                  child: _CodeBlock(text: _pretty(log.requestHeaders)),
                ),
                _DetailSection(
                  title: 'Request Body',
                  child: _CodeBlock(text: _pretty(log.requestBody)),
                ),
                _DetailSection(
                  title: 'Response Headers',
                  child: _CodeBlock(text: _pretty(log.responseHeaders)),
                ),
                _DetailSection(
                  title: log.error == null ? 'Response Body' : 'Error',
                  child: _CodeBlock(
                    text: _pretty(log.error ?? log.responseBody),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pretty(Object? value) {
    if (value == null) return '-';
    final redacted = _redactForDisplay(value);
    if (redacted is String) {
      if (redacted.trim().isEmpty) return '-';
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(redacted));
      } catch (_) {
        return redacted;
      }
    }
    return const JsonEncoder.withIndent('  ').convert(redacted);
  }

  String _copyPayload(_CopyAction action) {
    return switch (action) {
      _CopyAction.url => log.endpoint,
      _CopyAction.curl => _curl(),
      _CopyAction.request => _pretty({
        'method': log.method,
        'url': log.endpoint,
        'headers': log.requestHeaders,
        'body': log.requestBody,
      }),
      _CopyAction.response => _pretty({
        'status': log.responseStatus,
        'headers': log.responseHeaders,
        'body': log.responseBody,
        'error': log.error,
      }),
      _CopyAction.json => _pretty({
        'method': log.method,
        'url': log.endpoint,
        'timestamp': log.timestamp.toIso8601String(),
        'status': log.responseStatus,
        'durationMs': log.duration?.inMilliseconds,
        'requestHeaders': log.requestHeaders,
        'requestBody': log.requestBody,
        'responseHeaders': log.responseHeaders,
        'responseBody': log.responseBody,
        'error': log.error,
      }),
    };
  }

  String _curl() {
    final buffer = StringBuffer('curl -X ${log.method.toUpperCase()}');
    final headers = _redactForDisplay(log.requestHeaders);
    if (headers is Map) {
      for (final entry in headers.entries) {
        if (entry.key.toString().toLowerCase() == 'host') continue;
        buffer.write(" -H '${entry.key}: ${entry.value}'");
      }
    }
    final body = _redactForDisplay(log.requestBody);
    if (body is String && body.isNotEmpty) {
      buffer.write(' --data ${_shellQuote(body)}');
    }
    buffer.write(' ${_shellQuote(log.endpoint)}');
    return buffer.toString();
  }

  Object? _redactForDisplay(Object? value) {
    if (value is String) {
      try {
        final parsed = jsonDecode(value);
        return _redactForDisplay(parsed);
      } catch (_) {
        return redactor.redactValue(value);
      }
    }
    if (value is Map) {
      final redacted = redactor.redact(value);
      return redacted.map(
        (key, nestedValue) => MapEntry(key, _redactForDisplay(nestedValue)),
      );
    }
    if (value is Iterable) {
      return value.map(_redactForDisplay).toList(growable: false);
    }
    return redactor.redactValue(value);
  }

  void _copy(BuildContext _, _CopyAction action) {
    Clipboard.setData(ClipboardData(text: _copyPayload(action)));
  }
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", r"'\''")}'";
}

enum _CopyAction { url, curl, request, response, json }

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _KeyValueBlock extends StatelessWidget {
  const _KeyValueBlock({required this.values});

  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _blockDecoration(),
      child: Column(
        children: [
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _blockDecoration(),
      child: SelectableText(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          height: 1.35,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

BoxDecoration _blockDecoration() {
  return BoxDecoration(
    color: const Color(0xFF161922),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF272B36)),
  );
}

String _formatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}

Color _statusColor(NetworkLog log) {
  if (log.responseStatus == null) return const Color(0xFFF59E0B);
  if (log.hasError) return const Color(0xFFEF4444);
  return const Color(0xFF4ADE80);
}

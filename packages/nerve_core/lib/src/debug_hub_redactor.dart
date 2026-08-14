class DebugHubRedactor {
  DebugHubRedactor({
    Iterable<String> sensitiveKeys = const {
      'authorization',
      'cookie',
      'set-cookie',
      'token',
      'access_token',
      'refresh_token',
      'jwt',
      'secret',
      'password',
      'privatekey',
      'private_key',
      'mnemonic',
      'seed',
      'signature',
    },
  }) : _sensitiveKeys = sensitiveKeys.map(_normalize).toSet();

  static const redactedValue = '[REDACTED]';

  final Set<String> _sensitiveKeys;

  Map<String, Object?> redact(Map<dynamic, dynamic> value) {
    return _redactMap(value).cast<String, Object?>();
  }

  Object? redactValue(Object? value) => _redactAny(value);

  Map<String, Object?> _redactMap(Map<dynamic, dynamic> value) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      result[key] = _isSensitiveKey(key)
          ? redactedValue
          : _redactAny(entry.value);
    }
    return result;
  }

  Object? _redactAny(Object? value) {
    if (value is Map) return _redactMap(value);
    if (value is Iterable) {
      return value.map((item) => _redactAny(item)).toList(growable: false);
    }
    return value;
  }

  bool _isSensitiveKey(String key) => _sensitiveKeys.contains(_normalize(key));

  static String _normalize(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
}

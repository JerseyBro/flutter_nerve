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

  // 文本级脱敏：Authorization / Bearer / JWT / 私钥 / 助记词 模式
  static final _bearerRe = RegExp(r'Bearer\s+[A-Za-z0-9\-_\.=]+', caseSensitive: false);
  static final _jwtRe = RegExp(r'eyJ[A-Za-z0-9_\-]+\.eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-=/+]+');
  static final _privateKeyRe = RegExp(r'0x[0-9a-fA-F]{64}');
  static final _mnemonicRe = RegExp(r'\b(\w+\s+){11}\w+\b');

  String redactText(String input) {
    var out = input;
    out = out.replaceAll(_bearerRe, 'Bearer $redactedValue');
    out = out.replaceAll(_jwtRe, redactedValue);
    // 保守：过长的 0x 私钥直接打码
    out = out.replaceAll(_privateKeyRe, redactedValue);
    // 助记词仅对明显长句兜底
    if (_mnemonicRe.hasMatch(out) && out.split(RegExp(r'\s+')).length >= 12) {
      // 不直接替换整句，避免误伤；仅标记
      out = out.replaceAll(_mnemonicRe, redactedValue);
    }
    return out;
  }

  Object? _redactAny(Object? value) {
    if (value is Map) return _redactMap(value);
    if (value is Iterable) {
      return value.map((item) => _redactAny(item)).toList(growable: false);
    }
    if (value is String) return redactText(value);
    return value;
  }

  bool _isSensitiveKey(String key) => _sensitiveKeys.contains(_normalize(key));

  static String _normalize(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
}

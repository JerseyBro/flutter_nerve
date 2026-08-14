import 'package:nerve_core/nerve_core.dart';

Map<String, Object?> buildWenDiagnostics({
  required String env,
  required String apiHost,
  required String wsHost,
  required String mpcHost,
  Map<String, Object?> headers = const {},
  Map<String, Object?> extra = const {},
}) {
  final redactor = DebugHubRedactor();
  return redactor.redact({
    'env': env,
    'apiHost': apiHost,
    'wsHost': wsHost,
    'mpcHost': mpcHost,
    'headers': headers,
    ...extra,
  });
}

// The current app uses Drift's stable sql.js compatibility backend. A WASM
// migration requires shipping sqlite3.wasm and a generated Drift worker.
// ignore_for_file: deprecated_member_use
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens the browser-local Drift database used by the web guest/offline cache.
///
/// The Flutter web shell loads sql.js from `web/index.html`. `readIntsAsBigInt`
/// keeps Drift int64 values lossless for financial amounts.
QueryExecutor openConnection() {
  return WebDatabase(
    'mizan',
    readIntsAsBigInt: true,
  );
}

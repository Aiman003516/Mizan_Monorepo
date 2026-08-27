// The current app uses Drift's stable sql.js compatibility backend. A WASM
// migration requires shipping sqlite3.wasm and a generated Drift worker.
// ignore_for_file: deprecated_member_use
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens the browser-local Drift database used by the web guest/offline cache.
///
/// The Flutter web shell loads the vendored sql.js runtime from `web/index.html`.
/// Browser financial inputs are bounded to the JavaScript safe-integer range.
QueryExecutor openConnection() {
  return WebDatabase(
    'mizan',
    // The web data models use Dart int fields and all browser financial inputs
    // are bounded by the JavaScript safe-integer validation rule. Returning
    // sql.js integers as BigInt here causes generated Drift rows to fail type
    // conversion before account/report streams can render.
    readIntsAsBigInt: false,
  );
}

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    return WasmDatabase.open(
      databaseName: 'mizan',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
  });
}

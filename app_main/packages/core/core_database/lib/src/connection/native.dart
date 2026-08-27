import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mizan.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute('PRAGMA foreign_keys = ON');
        database.execute('PRAGMA journal_mode = WAL');
        database.execute('PRAGMA synchronous = NORMAL');
        database.execute('PRAGMA busy_timeout = 5000');
        database.execute('PRAGMA cache_size = -32768');
      },
    );
  });
}

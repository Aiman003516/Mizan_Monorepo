import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;

// UPDATED Local Imports
import 'package:core_database/core_database.dart';
import 'package:feature_auth/feature_auth.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// This provider must be overridden in app_mizan
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

enum SyncStatus { idle, inProgress, success, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

class SyncService {
  SyncService(this._ref);
  final Ref _ref;

  static const String _dbFileName = 'mizan.db';
  static const String _backupFileName = 'mizan_backup.db';

  Future<drive.DriveApi> _getDriveApi() async {
    final authRepo = _ref.read(authRepositoryProvider);
    final client = await authRepo.getHttpClient();
    return drive.DriveApi(client);
  }

  Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _dbFileName));
    return file;
  }

  Future<void> backupDatabase() async {
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.inProgress;
    final db = _ref.read(databaseProvider);
    final driveApi = await _getDriveApi();

    File? dbFile;
    File? backupFile;

    try {
      dbFile = await _getDbFile();
      if (!await dbFile.exists()) {
        throw Exception('Database file not found.');
      }

      await db.close();

      final tempDir = await getTemporaryDirectory();
      backupFile = await dbFile.copy(p.join(tempDir.path, _backupFileName));

      final response = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$_backupFileName'",
        $fields: 'files(id, name)',
      );

      final fileToUpload = drive.File()..name = _backupFileName;
      final media = drive.Media(backupFile.openRead(), await backupFile.length());

      if (response.files != null && response.files!.isNotEmpty) {
        final fileId = response.files!.first.id!;
        await driveApi.files.update(
          fileToUpload,
          fileId,
          uploadMedia: media,
        );
      } else {
        fileToUpload.parents = ['appDataFolder'];
        await driveApi.files.create(
          fileToUpload,
          uploadMedia: media,
        );
      }

      _ref.read(syncStatusProvider.notifier).state = SyncStatus.success;

    } catch (e) {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    } finally {
      // This will re-open the connection
      _ref.refresh(databaseProvider); 

      try {
        if (backupFile != null && await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (e) {
        print('Error cleaning up backup file: $e');
      }
    }
  }

  Future<void> restoreDatabase() async {
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.inProgress;
    final db = _ref.read(databaseProvider);
    final driveApi = await _getDriveApi();

    File? dbFile;

    try {
      final response = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$_backupFileName'",
        $fields: 'files(id, name)',
      );

      if (response.files == null || response.files!.isEmpty) {
        throw Exception('No backup file found on Google Drive.');
      }

      final fileId = response.files!.first.id!;
      dbFile = await _getDbFile();

      await db.close();

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final fileSink = dbFile.openWrite(mode: FileMode.write);
      await media.stream.pipe(fileSink);
      await fileSink.close();

      _ref.read(syncStatusProvider.notifier).state = SyncStatus.success;

    } catch (e) {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    } finally {
      _ref.refresh(databaseProvider);
    }
  }
}
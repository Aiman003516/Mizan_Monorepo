import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:core_database/core_database.dart';
import 'package:feature_auth/feature_auth.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

// ⚡ FIX: Split the states so Backup and Restore don't confuse each other
enum SyncStatus { 
  idle, 
  backupInProgress, 
  restoreInProgress, 
  backupSuccess, 
  restoreSuccess, 
  error 
}

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
    // ⚡ SET SPECIFIC STATE
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.backupInProgress;
    
    final db = _ref.read(appDatabaseProvider);
    
    // Reset state after a delay or on error, but we handle success explicitly
    File? backupFile;

    try {
      final driveApi = await _getDriveApi(); // Moved inside try to catch auth errors
      
      final tempDir = await getTemporaryDirectory();
      final backupPath = p.join(tempDir.path, _backupFileName);
      backupFile = File(backupPath);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      // Safe Backup
      await db.customStatement('VACUUM INTO ?', [backupPath]);

      // --- Upload ---
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

      // ⚡ SPECIFIC SUCCESS
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.backupSuccess;

    } catch (e) {
      print("Backup Error: $e");
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    } finally {
      try {
        if (backupFile != null && await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (e) {
        print('Error cleaning up: $e');
      }
      
      // Auto-reset state after 2 seconds so the success message disappears/resets
      Future.delayed(const Duration(seconds: 2), () {
        if (_ref.read(syncStatusProvider) == SyncStatus.backupSuccess) {
          _ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
        }
      });
    }
  }

  Future<void> restoreDatabase() async {
    // ⚡ SET SPECIFIC STATE
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.restoreInProgress;
    
    final db = _ref.read(appDatabaseProvider);
    
    File? dbFile;

    try {
      final driveApi = await _getDriveApi(); // Auth check inside try block

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

      // For Restore, we must close the DB
      await db.close();

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final fileSink = dbFile.openWrite(mode: FileMode.write);
      await media.stream.pipe(fileSink);
      await fileSink.close();

      // ⚡ SPECIFIC SUCCESS
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.restoreSuccess;

    } catch (e) {
      print("Restore Error: $e");
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    } finally {
      // Resurrection
      _ref.refresh(appDatabaseProvider);
      
      // Auto-reset state
      Future.delayed(const Duration(seconds: 2), () {
        if (_ref.read(syncStatusProvider) == SyncStatus.restoreSuccess) {
          _ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
        }
      });
    }
  }
}
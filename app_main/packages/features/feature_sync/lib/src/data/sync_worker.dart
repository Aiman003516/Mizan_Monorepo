import 'package:workmanager/workmanager.dart';
import 'package:feature_sync/src/data/sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("Native called background task: $task");
      // Execute the silent backup
      await SyncService.performSilentBackup();
      return true;
    } catch (e) {
      if (SyncService.isNonRetryableSilentBackupError(e)) {
        print(
          "Background backup skipped: Google Drive setup or authorization "
          "is required; no automatic retry will be scheduled.",
        );
        return true;
      }
      print("Background task failed temporarily: $e");
      return false;
    }
  });
}

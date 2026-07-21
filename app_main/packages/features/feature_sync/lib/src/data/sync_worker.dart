import 'package:workmanager/workmanager.dart';
import 'package:feature_sync/src/data/sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("Native called background task: $task");
      // Execute the silent backup
      await SyncService.performSilentBackup();
      return Future.value(true);
    } catch (e) {
      print("Background task failed: $e");
      return Future.value(false);
    }
  });
}

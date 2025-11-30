import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_sync/src/data/sync_service.dart';

final syncControllerProvider =
    StateNotifierProvider<SyncController, AsyncValue<void>>((ref) {
  return SyncController(ref.watch(syncServiceProvider), ref);
});

class SyncController extends StateNotifier<AsyncValue<void>> {
  SyncController(this._syncService, this._ref) : super(const AsyncData(null));

  final SyncService _syncService;
  final Ref _ref;

  Future<void> runBackup() async {
    state = const AsyncLoading();
    // Service handles setting 'backupInProgress' and 'backupSuccess'
    // We just handle the AsyncValue state here.

    try {
      await _syncService.backupDatabase();
      state = const AsyncData(null);
      // ✂️ REMOVED: Redundant state setting
    } catch (e, st) {
      state = AsyncError(e, st);
      // Service handles setting 'error' status for the UI snackbar
    }
  }

  Future<void> runRestore() async {
    state = const AsyncLoading();
    // Service handles setting 'restoreInProgress' and 'restoreSuccess'

    try {
      await _syncService.restoreDatabase();
      state = const AsyncData(null);
      // ✂️ REMOVED: Redundant state setting (This fixes the double message)
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
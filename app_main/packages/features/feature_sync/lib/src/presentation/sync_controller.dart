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
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.inProgress;

    try {
      await _syncService.backupDatabase();
      state = const AsyncData(null);
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
    } catch (e, st) {
      state = AsyncError(e, st);
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }

  Future<void> runRestore() async {
    state = const AsyncLoading();
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.inProgress;

    try {
      await _syncService.restoreDatabase();
      state = const AsyncData(null);
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
    } catch (e, st) {
      state = AsyncError(e, st);
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }
}
// FILE: packages/features/feature_sync/lib/src/presentation/sync_gatekeeper.dart

import 'dart:async';
import 'package:feature_sync/src/data/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🛡️ THE GATEKEEPER
/// Ensures "Strict Consistency" by blocking the UI until data is confirmed in the Cloud.
class SyncGatekeeper {
  final CloudSyncService _syncService;
  
  // In Phase 6, we will inject BillingRepository here to check entitlements.
  // For now, we assume if we are running, we are Enterprise/Pro.
  
  SyncGatekeeper(this._syncService);

  /// The Blocking Method. Call this before popping a screen after a save.
  Future<void> ensureStrictConsistency(BuildContext context) async {
    // 1. Show the Blocking Overlay
    // We use a Dialog that cannot be dismissed by tapping outside.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _BlockingSyncDialog(),
    );

    try {
      // 2. Run the Immediate Sync with a Safety Timeout
      // If internet is fast, this takes 500ms.
      // If internet is dead, it throws TimeoutException after 20s.
      await _syncService.runImmediateSync().timeout(const Duration(seconds: 20));

      // 3. Success: Close the Dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close Dialog
      }
    } catch (e) {
      // 4. Failure (Timeout or Network Error): Close the Spinner first
      if (context.mounted) {
        Navigator.of(context).pop(); // Close Spinner
      }
      
      // 5. Show the "Escape Hatch" Dialog
      if (context.mounted) {
        await _showFailureDialog(context, e);
      }
    }
  }

  Future<void> _showFailureDialog(BuildContext context, Object error) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('☁️ Sync Warning'),
        content: Text(
          'We saved your data locally, but could not confirm it with the Headquarters.\n\n'
          'Reason: This device seems to be offline.\n\n'
          'Your data is safe, but other devices won\'t see it until you reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Just close dialog
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

// The UI for the Blocking Spinner
class _BlockingSyncDialog extends StatelessWidget {
  const _BlockingSyncDialog();

  @override
  Widget build(BuildContext context) {
    // PopScope prevents Android Back Button
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Syncing with Headquarters...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Please wait while we secure your data.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 💉 Provider
final syncGatekeeperProvider = Provider<SyncGatekeeper>((ref) {
  final syncService = ref.watch(cloudSyncServiceProvider);
  return SyncGatekeeper(syncService);
});
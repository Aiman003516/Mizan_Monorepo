import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_database/core_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

/// 🔄 THE HYBRID SYNC ENGINE (Engine B)
class CloudSyncService {
  final AppDatabase _localDb;
  final FirebaseFirestore _firestore;
  final String? _currentTenantId;

  StreamSubscription? _outgoingSyncSub;
  StreamSubscription? _incomingSyncSub;

  DateTime _lastPushTime = DateTime.now().subtract(const Duration(days: 365));

  CloudSyncService({
    required AppDatabase localDb,
    required FirebaseFirestore firestore,
    String? tenantId,
  })  : _localDb = localDb,
        _firestore = firestore,
        _currentTenantId = tenantId;

  void startSync() {
    if (_currentTenantId == null) {
      print('⚠️ [CloudSync] Cannot start: No Tenant ID (Free Tier?)');
      return;
    }
    print('🚀 [CloudSync] Starting Engine for Tenant: $_currentTenantId');
    _startOutgoingSync();
  }

  void stopSync() {
    _outgoingSyncSub?.cancel();
    _incomingSyncSub?.cancel();
    print('🛑 [CloudSync] Engine Stopped');
  }

  // --- 📤 OUTBOUND (Local -> Cloud) ---
  void _startOutgoingSync() {
    // Watch the Drift Stream. event.table is a String (table name).
    _outgoingSyncSub = _localDb.tableUpdates().listen((events) async {
      for (final event in events) {
        await _handleTableUpdate(event.table);
      }
    });
  }

  /// Process a specific table change (Matched by Name)
  Future<void> _handleTableUpdate(String tableName) async {
    print('🔎 [CloudSync] Detected change in table: $tableName'); // 👈 ADD THIS DEBUG LOG
    
    List<Map<String, dynamic>> rowsToPush = [];

    // 🛡️ NAME MATCHING:
    // Compare String name against actual table names.
    if (tableName == _localDb.transactions.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.transactions);
    } else if (tableName == _localDb.products.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.products);
    } else if (tableName == _localDb.accounts.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.accounts);
    } else if (tableName == _localDb.transactionEntries.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.transactionEntries);
    } else if (tableName == _localDb.orders.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.orders);
    } else if (tableName == _localDb.orderItems.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.orderItems);
    } else if (tableName == _localDb.categories.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.categories);
    } else if (tableName == _localDb.inventoryCostLayers.actualTableName) {
      rowsToPush = await _fetchUpdates(_localDb.inventoryCostLayers);
    }

    if (rowsToPush.isNotEmpty) {
      await _pushToFirestore(tableName, rowsToPush);
      _lastPushTime = DateTime.now();
    }
  }

  /// 🛡️ THE GENERIC HELPER (FIXED FOR EXTENSIONS)
  Future<List<Map<String, dynamic>>> _fetchUpdates(dynamic table) async {
    
    // 1. Runtime Cast: Convert to what Drift needs for select()
    final driftTable = table as ResultSetImplementation<HasResultSet, dynamic>;

    final query = _localDb.select(driftTable)
      ..where((tbl) {
        // 2. Dynamic Access to MizanTable columns
        final mizanTbl = tbl as dynamic;
        final tenantIdVal = _currentTenantId ?? '';

        // 3. 🛠️ THE FIX IS HERE: Explicit Type Casting
        // We cast the columns back to 'Expression' types.
        // This allows Dart to "see" the Extension Methods (isBiggerThan, equals).
        final lastUpdatedExpr = mizanTbl.lastUpdated as Expression<DateTime>;
        final tenantIdExpr = mizanTbl.tenantId as Expression<String>;

        // Now we can safely call the extensions
        return lastUpdatedExpr.isBiggerThan(Variable(_lastPushTime)) &
               tenantIdExpr.equals(tenantIdVal);
      });

    final results = await query.get();
    
    // 4. Convert to JSON
    return results.map((row) => (row as dynamic).toJson()).cast<Map<String, dynamic>>().toList();
  }

  Future<void> _pushToFirestore(
      String collectionName, List<Map<String, dynamic>> rows) async {
    
    final batch = _firestore.batch();
    
    for (final row in rows) {
      final docId = row['id'];
      if (docId == null) continue;

      final docRef = _firestore
          .collection('tenants')
          .doc(_currentTenantId)
          .collection(collectionName)
          .doc(docId);

      batch.set(docRef, row, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      print('☁️ [CloudSync] Pushed ${rows.length} items to $collectionName');
    } catch (e) {
      print('❌ [CloudSync] Push Failed: $e');
    }
  }
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider); 
  final firestore = FirebaseFirestore.instance;
  
  // Hardcoded tenant for testing
  final String? fakeTenantId = "test_tenant_123";

  final service = CloudSyncService(
    localDb: db, 
    firestore: firestore,
    tenantId: fakeTenantId, 
  );

  service.startSync();

  ref.onDispose(() {
    service.stopSync();
  });

  return service;
});
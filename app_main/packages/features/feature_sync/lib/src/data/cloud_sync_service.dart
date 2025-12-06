// FILE: packages/features/feature_sync/lib/src/data/cloud_sync_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order, Transaction;
import 'package:core_data/core_data.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_auth/feature_auth.dart'; // 👈 Import Auth
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

/// 🔄 THE HYBRID SYNC ENGINE (Engine B - Phase 4.3 Billing Enforcer)
class CloudSyncService {
  final AppDatabase _localDb;
  final FirebaseFirestore _firestore;
  final PreferencesRepository _prefs;
  final String? _currentTenantId; // If null, Sync is DISABLED (Free Tier)

  StreamSubscription? _outgoingSyncSub;
  final List<StreamSubscription> _incomingSyncSubs = [];
  Timer? _debounceTimer;
  bool _isSyncing = false;

  CloudSyncService({
    required AppDatabase localDb,
    required FirebaseFirestore firestore,
    required PreferencesRepository prefs,
    String? tenantId,
  })  : _localDb = localDb,
        _firestore = firestore,
        _prefs = prefs,
        _currentTenantId = tenantId;

  List<String> get _allSyncableTables => [
    _localDb.transactions.actualTableName,
    _localDb.products.actualTableName,
    _localDb.accounts.actualTableName,
    _localDb.transactionEntries.actualTableName,
    _localDb.orders.actualTableName,
    _localDb.orderItems.actualTableName,
    _localDb.categories.actualTableName,
    _localDb.inventoryCostLayers.actualTableName,
  ];

  /// 🛡️ THE ENFORCER: Only start if we have a valid Tenant ID
  void startSync() {
    if (_currentTenantId == null) {
      print('🔒 [Billing Enforcer] Cloud Sync Disabled (Free Tier / No Tenant).');
      return;
    }
    
    print('🚀 [CloudSync] Starting Engine for Tenant: $_currentTenantId');
    print('🕒 [CloudSync] Last Sync Time: ${_prefs.getLastSyncTime()}'); 
    
    _startOutgoingSync();
    _startIncomingSync();
  }

  void stopSync() {
    _outgoingSyncSub?.cancel();
    _debounceTimer?.cancel();
    for (final sub in _incomingSyncSubs) {
      sub.cancel();
    }
    _incomingSyncSubs.clear();
    print('🛑 [CloudSync] Engine Stopped');
  }

  // --- ⚡ STRICT CONSISTENCY (The Blocking Sync) ---

  Future<void> runImmediateSync() async {
    // 🛡️ ENFORCER CHECK
    if (_currentTenantId == null) {
      print('⚠️ [CloudSync] Skipping Immediate Sync (No Tenant ID)');
      return;
    }

    if (_isSyncing) {
      print('⏳ [CloudSync] Sync already in progress.');
      return;
    }

    _isSyncing = true; 
    _debounceTimer?.cancel(); 

    try {
      print('⚡ [CloudSync] Executing Bundled Sync...');
      final syncStartTime = DateTime.now();
      bool anyDataPushed = false;

      for (final table in _allSyncableTables) {
        final pushed = await _processTable(table, updatePrefs: false);
        if (pushed) anyDataPushed = true;
      }

      if (anyDataPushed) {
        await _prefs.setLastSyncTime(syncStartTime);
        print('💾 [CloudSync] Sync Cycle Complete.');
      } else {
        print('✅ [CloudSync] Sync Cycle Verified.');
      }
    } catch (e) {
      print('❌ [CloudSync] Sync Cycle Failed: $e');
      rethrow; 
    } finally {
      _isSyncing = false;
    }
  }

  // --- 📤 OUTBOUND (Local -> Cloud) ---
  
  void _startOutgoingSync() {
    _outgoingSyncSub = _localDb.tableUpdates().listen((events) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () async {
        print('📦 [CloudSync] Debounce finished. Sending Bundle.');
        await runImmediateSync();
      });
    });
  }

  Future<bool> _processTable(String tableName, {required bool updatePrefs}) async {
    // 🛡️ ENFORCER CHECK
    if (_currentTenantId == null) return false;

    List<Map<String, dynamic>> rowsToPush = [];

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
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> _fetchUpdates(dynamic table) async {
    final driftTable = table as ResultSetImplementation<HasResultSet, dynamic>;

    final query = _localDb.select(driftTable)
      ..where((tbl) {
        final mizanTbl = tbl as dynamic;
        final tenantIdVal = _currentTenantId ?? '';

        final lastUpdatedExpr = mizanTbl.lastUpdated as Expression<DateTime>;
        final tenantIdExpr = mizanTbl.tenantId as Expression<String>;

        return lastUpdatedExpr.isBiggerThan(Variable(_prefs.getLastSyncTime())) &
               tenantIdExpr.equals(tenantIdVal);
      });

    final results = await query.get();
    return results.map((row) => (row as dynamic).toJson()).cast<Map<String, dynamic>>().toList();
  }

  Future<void> _pushToFirestore(
      String collectionName, List<Map<String, dynamic>> rows) async {
    
    // 🛡️ ENFORCER CHECK
    if (_currentTenantId == null) return;

    const int batchSize = 500;
    int chunks = (rows.length / batchSize).ceil();

    for (int i = 0; i < chunks; i++) {
      final start = i * batchSize;
      final end = (start + batchSize < rows.length) ? start + batchSize : rows.length;
      final chunk = rows.sublist(start, end);

      final batch = _firestore.batch();

      for (final row in chunk) {
        final docId = row['id'];
        if (docId == null) continue;

        final docRef = _firestore
            .collection('tenants')
            .doc(_currentTenantId)
            .collection(collectionName)
            .doc(docId);

        final data = Map<String, dynamic>.from(row);
        batch.set(docRef, data, SetOptions(merge: true));
      }

      try {
        await batch.commit();
        print('☁️ [CloudSync] Pushed Batch ${i + 1}/$chunks (${chunk.length} items)');
      } catch (e) {
        print('❌ [CloudSync] Batch Push Failed: $e');
        rethrow;
      }
    }
  }

  // --- 📥 INBOUND (Cloud -> Local) ---
  
  void _startIncomingSync() {
    for (final tableName in _allSyncableTables) {
      _monitorRemoteCollection(tableName);
    }
  }

  void _monitorRemoteCollection(String tableName) {
    // 🛡️ ENFORCER CHECK
    if (_currentTenantId == null) return;

    final lastSync = _prefs.getLastSyncTime();
    
    final stream = _firestore
        .collection('tenants')
        .doc(_currentTenantId)
        .collection(tableName)
        .where('lastUpdated', isGreaterThan: lastSync.toIso8601String())
        .snapshots();

    final sub = stream.listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        print('📥 [CloudSync] Received ${snapshot.docs.length} updates for $tableName');
        await _upsertLocal(tableName, snapshot.docs);
        await _prefs.setLastSyncTime(DateTime.now());
      }
    });

    _incomingSyncSubs.add(sub);
  }

  Future<void> _upsertLocal(String tableName, List<QueryDocumentSnapshot> docs) async {
    await _localDb.transaction(() async {
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        try {
          if (tableName == _localDb.transactions.actualTableName) {
             await _localDb.into(_localDb.transactions).insertOnConflictUpdate(Transaction.fromJson(data));
          } else if (tableName == _localDb.products.actualTableName) {
             await _localDb.into(_localDb.products).insertOnConflictUpdate(Product.fromJson(data));
          } else if (tableName == _localDb.accounts.actualTableName) {
             await _localDb.into(_localDb.accounts).insertOnConflictUpdate(Account.fromJson(data));
          } else if (tableName == _localDb.transactionEntries.actualTableName) {
             await _localDb.into(_localDb.transactionEntries).insertOnConflictUpdate(TransactionEntry.fromJson(data));
          } else if (tableName == _localDb.orders.actualTableName) {
             await _localDb.into(_localDb.orders).insertOnConflictUpdate(Order.fromJson(data));
          } else if (tableName == _localDb.orderItems.actualTableName) {
             await _localDb.into(_localDb.orderItems).insertOnConflictUpdate(OrderItem.fromJson(data));
          } else if (tableName == _localDb.categories.actualTableName) {
             await _localDb.into(_localDb.categories).insertOnConflictUpdate(Category.fromJson(data));
          } else if (tableName == _localDb.inventoryCostLayers.actualTableName) {
             await _localDb.into(_localDb.inventoryCostLayers).insertOnConflictUpdate(InventoryCostLayer.fromJson(data));
          }
        } catch (e) {
          print('❌ [CloudSync] Upsert Error for $tableName: $e');
        }
      }
    });
  }
}

// 💉 REVISED PROVIDER
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider); 
  final firestore = FirebaseFirestore.instance;
  final prefs = ref.watch(preferencesRepositoryProvider);
  
  // 🛡️ REACTION: Watch the User Stream!
  // This causes the Provider to re-build (and restart the service) whenever:
  // 1. User logs in/out
  // 2. User upgrades to Enterprise (tenantId appears)
  final userAsync = ref.watch(currentUserStreamProvider);
  final user = userAsync.value;

  // Determine Tenant ID
  final String? tenantId = (user?.hasCloudAccess == true) ? user?.tenantId : null;

  final service = CloudSyncService(
    localDb: db, 
    firestore: firestore,
    prefs: prefs, 
    tenantId: tenantId, 
  );

  // Auto-Start (Service internal logic will abort if tenantId is null)
  service.startSync();

  ref.onDispose(() {
    service.stopSync();
  });

  return service;
});
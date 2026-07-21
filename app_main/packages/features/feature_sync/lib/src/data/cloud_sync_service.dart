import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_auth/feature_auth.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

/// 🔄 THE HYBRID SYNC ENGINE (Engine B - Phase 4.3 Billing Enforcer)
class CloudSyncService {
  final AppDatabase _localDb;
  final SupabaseClient _supabase;
  final PreferencesRepository _prefs;
  final String? _currentTenantId;

  StreamSubscription? _outgoingSyncSub;
  final List<RealtimeChannel> _incomingChannels = [];
  Timer? _debounceTimer;
  bool _isSyncing = false;

  CloudSyncService({
    required AppDatabase localDb,
    required SupabaseClient supabase,
    required PreferencesRepository prefs,
    String? tenantId,
  })  : _localDb = localDb,
        _supabase = supabase,
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
    for (final channel in _incomingChannels) {
      _supabase.removeChannel(channel);
    }
    _incomingChannels.clear();
    print('🛑 [CloudSync] Engine Stopped');
  }

  Future<void> runImmediateSync() async {
    if (_currentTenantId == null) return;
    if (_isSyncing) return;

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
      await _pushToSupabase(tableName, rowsToPush);
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

  String _getRemoteTableName(String localTableName) {
    return 'synced_$localTableName';
  }

  Future<void> _pushToSupabase(String tableName, List<Map<String, dynamic>> rows) async {
    if (_currentTenantId == null) return;

    final remoteName = _getRemoteTableName(tableName);
    const int batchSize = 500;
    int chunks = (rows.length / batchSize).ceil();

    for (int i = 0; i < chunks; i++) {
      final start = i * batchSize;
      final end = (start + batchSize < rows.length) ? start + batchSize : rows.length;
      final chunk = rows.sublist(start, end);

      try {
        await _supabase.from(remoteName).upsert(chunk);
        print('☁️ [CloudSync] Pushed Batch ${i + 1}/$chunks (${chunk.length} items)');
      } catch (e) {
        print('❌ [CloudSync] Batch Push Failed: $e');
        rethrow;
      }
    }
  }

  void _startIncomingSync() async {
    if (_currentTenantId == null) return;
    
    // 1. Initial catch-up
    final lastSync = _prefs.getLastSyncTime();
    for (final tableName in _allSyncableTables) {
      final remoteName = _getRemoteTableName(tableName);
      try {
        final missedData = await _supabase
          .from(remoteName)
          .select()
          .eq('tenant_id', _currentTenantId!)
          .gte('last_updated', lastSync.toIso8601String());
          
        if (missedData.isNotEmpty) {
           await _upsertLocal(tableName, missedData);
        }
      } catch (e) {
        print('Catch-up sync failed for $tableName: $e');
      }
    }
    await _prefs.setLastSyncTime(DateTime.now());

    // 2. Realtime listener
    for (final tableName in _allSyncableTables) {
      _monitorRemoteCollection(tableName);
    }
  }

  void _monitorRemoteCollection(String tableName) {
    if (_currentTenantId == null) return;

    final remoteName = _getRemoteTableName(tableName);
    final channel = _supabase.channel('public:$remoteName').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: remoteName,
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'tenant_id', value: _currentTenantId),
      callback: (payload) async {
        if (payload.newRecord != null) {
          print('📥 [CloudSync] Received realtime update for $remoteName');
          await _upsertLocal(tableName, [payload.newRecord!]);
          await _prefs.setLastSyncTime(DateTime.now());
        }
      }
    ).subscribe();

    _incomingChannels.add(channel);
  }

  Future<void> _upsertLocal(String tableName, List<Map<String, dynamic>> docs) async {
    await _localDb.transaction(() async {
      for (final data in docs) {
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
  final supabase = Supabase.instance.client;
  final prefs = ref.watch(preferencesRepositoryProvider);
  
  final userAsync = ref.watch(currentUserStreamProvider);
  final user = userAsync.value;

  final String? tenantId = (user?.hasCloudAccess == true) ? user?.tenantId : null;

  final service = CloudSyncService(
    localDb: db, 
    supabase: supabase,
    prefs: prefs, 
    tenantId: tenantId, 
  );

  service.startSync();

  ref.onDispose(() {
    service.stopSync();
  });

  return service;
});
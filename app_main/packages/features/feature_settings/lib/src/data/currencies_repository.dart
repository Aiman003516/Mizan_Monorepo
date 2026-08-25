import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:core_data/core_data.dart';

final currenciesRepositoryProvider = Provider<CurrenciesRepository>((ref) {
  return CurrenciesRepository(
    ref.watch(appDatabaseProvider),
    Supabase.instance.client,
    cloudMode: EnvConfig.isProd || EnvConfig.supabaseUrl.isNotEmpty,
  );
});

final currenciesStreamProvider = StreamProvider<List<Currency>>((ref) {
  return ref.watch(currenciesRepositoryProvider).watchCurrencies();
});

class CurrenciesRepository {
  CurrenciesRepository(this._db, this._supabase, {this.cloudMode = false});

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final bool cloudMode;

  Future<String> _tenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Authentication is required.');
    final row = await _supabase
        .from('staff_members')
        .select('tenant_id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('created_at')
        .limit(1)
        .maybeSingle();
    final tenantId = row?['tenant_id'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PostgrestException(
        message: 'Tenant membership was not found.',
        code: 'MIZAN_TENANT_NOT_FOUND',
      );
    }
    return tenantId;
  }

  Currency _fromRemote(Map<String, dynamic> row) {
    final created =
        DateTime.tryParse('${row['created_at']}') ?? DateTime.now().toUtc();
    final updated =
        DateTime.tryParse('${row['updated_at'] ?? row['created_at']}') ??
        created;
    return Currency(
      id: row['id'] as String,
      createdAt: created.toUtc(),
      lastUpdated: updated.toUtc(),
      tenantId: row['tenant_id'] as String?,
      isDeleted: false,
      code: (row['code'] as String).toUpperCase(),
      name: row['name'] as String,
      symbol: row['symbol'] as String?,
    );
  }

  bool _retryable(Object error) {
    if (error is TimeoutException) return true;
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed host lookup');
  }

  Stream<List<Currency>> watchCurrencies() async* {
    if (!cloudMode) {
      yield* (_db.select(_db.currencies)
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => OrderingTerm.asc(table.code)]))
          .watch();
      return;
    }

    final tenantId = await _tenantId();
    final remote = _supabase
        .from('currencies')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('code');
    try {
      await for (final rows in remote) {
        final currencies = rows
            .map((row) => _fromRemote(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _db.transaction(() async {
          for (final currency in currencies) {
            await _db.into(_db.currencies).insertOnConflictUpdate(currency);
          }
        });
        yield currencies;
      }
    } catch (error) {
      if (!_retryable(error)) rethrow;
      yield await (_db.select(_db.currencies)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => OrderingTerm.asc(table.code)]))
          .get();
    }
  }

  Future<void> createCurrency({
    required String code,
    required String name,
    String? symbol,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3,5}$').hasMatch(normalizedCode)) {
      throw const FormatException(
        'Currency codes must contain 3 to 5 uppercase letters.',
      );
    }
    if (name.trim().isEmpty) {
      throw const FormatException('Currency name is required.');
    }
    if (!cloudMode) {
      await _db
          .into(_db.currencies)
          .insert(
            CurrenciesCompanion.insert(
              code: normalizedCode,
              name: name.trim(),
              symbol: Value(
                symbol?.trim().isEmpty == true ? null : symbol?.trim(),
              ),
            ),
          );
      return;
    }
    final tenantId = await _tenantId();
    final row = await _supabase
        .from('currencies')
        .insert({
          'tenant_id': tenantId,
          'code': normalizedCode,
          'name': name.trim(),
          'symbol': symbol?.trim().isEmpty == true ? null : symbol?.trim(),
        })
        .select()
        .single();
    await _db
        .into(_db.currencies)
        .insertOnConflictUpdate(_fromRemote(Map<String, dynamic>.from(row)));
  }

  Future<void> updateCurrency(Currency currency) async {
    if (!cloudMode) {
      await _db
          .update(_db.currencies)
          .replace(
            currency
                .toCompanion(false)
                .copyWith(lastUpdated: Value(DateTime.now().toUtc())),
          );
      return;
    }
    final tenantId = await _tenantId();
    final row = await _supabase
        .from('currencies')
        .update({
          'code': currency.code.toUpperCase(),
          'name': currency.name.trim(),
          'symbol': currency.symbol,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', currency.id)
        .eq('tenant_id', tenantId)
        .select()
        .single();
    await _db
        .into(_db.currencies)
        .insertOnConflictUpdate(_fromRemote(Map<String, dynamic>.from(row)));
  }

  Future<void> deleteCurrency(String id) async {
    if (!cloudMode) {
      await (_db.delete(
        _db.currencies,
      )..where((table) => table.id.equals(id))).go();
      return;
    }
    final tenantId = await _tenantId();
    await _supabase
        .from('currencies')
        .delete()
        .eq('id', id)
        .eq('tenant_id', tenantId);
    await (_db.delete(_db.currencies)
          ..where((table) => table.id.equals(id))
          ..where((table) => table.tenantId.equals(tenantId)))
        .go();
  }
}

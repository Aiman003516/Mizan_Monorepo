import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart'; // For Variable
import 'package:feature_reports/src/data/report_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportTemplatesRepository {
  final SupabaseClient _supabase;
  final AppDatabase _localDb;

  ReportTemplatesRepository(this._supabase, this._localDb);

  /// 📥 FETCH MARKETPLACE (From Cloud)
  Stream<List<ReportTemplate>> watchStandardReports() {
    return _supabase
        .from('report_templates')
        .stream(primaryKey: ['id'])
        .eq('is_public', true)
        .map((snapshot) {
          return snapshot
              .map(
                (doc) => ReportTemplate.fromJson({
                  'title': doc['title'],
                  'description': doc['description'],
                  'sqlQuery': doc['sql_query'],
                  'isPremium': doc['is_premium'],
                  'columns': doc['columns'] ?? [],
                  'parameters': doc['parameters'] ?? [],
                }, doc['id']),
              )
              .toList();
        });
  }

  /// 💿 FETCH INSTALLED (From Local SQLite)
  Stream<List<ReportTemplate>> watchInstalledReports() {
    return _localDb.select(_localDb.localReportTemplates).watch().map((rows) {
      return rows.map((row) {
        return ReportTemplate(
          id: row.id,
          title: row.title,
          description: row.description,
          sqlQuery: row.sqlQuery,
          isPremium: row.isPremium,
          columns: (jsonDecode(row.columnsJson) as List)
              .map((e) => ReportColumn.fromJson(e))
              .toList(),
          parameters: (jsonDecode(row.parametersJson) as List)
              .map((e) => ReportParameter.fromJson(e))
              .toList(),
        );
      }).toList();
    });
  }

  /// 💾 INSTALL ACTION (Cloud -> Local)
  Future<void> installReport(ReportTemplate template) async {
    await _localDb
        .into(_localDb.localReportTemplates)
        .insertOnConflictUpdate(
          LocalReportTemplatesCompanion.insert(
            id: Value(template.id),
            title: template.title,
            description: template.description,
            sqlQuery: template.sqlQuery,
            columnsJson: jsonEncode(
              template.columns.map((e) => e.toJson()).toList(),
            ),
            parametersJson: jsonEncode(
              template.parameters.map((e) => e.toJson()).toList(),
            ),
            isPremium: Value(template.isPremium),
            createdAt: Value(DateTime.now()),
            lastUpdated: Value(DateTime.now()),
          ),
        );
  }

  /// 🗑️ UNINSTALL ACTION
  Future<void> deleteReport(String id) async {
    await (_localDb.delete(
      _localDb.localReportTemplates,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// ⚙️ EXECUTE ENGINE (Local SQLite)
  Future<List<Map<String, dynamic>>> runReportQuery(
    String sql,
    Map<String, dynamic> params,
  ) async {
    String finalSql = sql;

    // Sort keys by length desc to avoid replacing @start before @startDate
    final keys = params.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in keys) {
      final placeholder = '@$key';
      if (finalSql.contains(placeholder)) {
        final val = params[key];
        String sqlVal;
        if (val is DateTime) {
          sqlVal = '${val.millisecondsSinceEpoch}';
        } else if (val is String) {
          sqlVal = "'${val.replaceAll("'", "''")}'";
        } else {
          sqlVal = '$val';
        }
        finalSql = finalSql.replaceAll(placeholder, sqlVal);
      }
    }

    try {
      final result = await _localDb.customSelect(finalSql).get();
      return result.map((row) => row.data).toList();
    } catch (e) {
      print('❌ Report Engine Error: $e\nSQL: $finalSql');
      throw Exception('Failed to generate report: $e');
    }
  }
}

final reportTemplatesRepositoryProvider = Provider<ReportTemplatesRepository>((
  ref,
) {
  return ReportTemplatesRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
});

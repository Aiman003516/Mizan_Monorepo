import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchemaHealthScreen extends ConsumerStatefulWidget {
  const SchemaHealthScreen({super.key});

  @override
  ConsumerState<SchemaHealthScreen> createState() => _SchemaHealthScreenState();
}

class _SchemaHealthScreenState extends ConsumerState<SchemaHealthScreen> {
  late Future<SchemaHealthReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _run();
  }

  Future<SchemaHealthReport> _run() {
    return ref.read(schemaHealthRepositoryProvider).run();
  }

  Future<void> _refresh() async {
    setState(() => _future = _run());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schemaHealth),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
          ),
        ],
      ),
      body: FutureBuilder<SchemaHealthReport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      l10n.schemaHealthLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final report = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      report.hasCriticalFailure
                          ? Icons.warning_amber_rounded
                          : Icons.verified_outlined,
                      color: report.hasCriticalFailure
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      report.hasCriticalFailure
                          ? l10n.schemaHealthNeedsAttention
                          : l10n.schemaHealthHealthy,
                    ),
                    subtitle: Text(
                      '${report.passedCount}/${report.checks.length} ${l10n.schemaHealthChecksPassed}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final check in report.checks)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        check.passed
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: check.passed
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                      title: Text(_readableCode(check.code, l10n)),
                      subtitle: Text(check.details),
                      trailing: check.observedCount == 0
                          ? null
                          : Chip(label: Text('${check.observedCount}')),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _readableCode(String code, AppLocalizations l10n) {
    if (code.startsWith('required_table.')) {
      return '${l10n.requiredTable}: ${code.substring('required_table.'.length)}';
    }
    if (code.startsWith('rls_enabled.')) {
      return '${l10n.rowLevelSecurity}: ${code.substring('rls_enabled.'.length)}';
    }
    if (code.startsWith('orphan_tenant_reference.')) {
      return '${l10n.tenantReferences}: ${code.substring('orphan_tenant_reference.'.length)}';
    }
    if (code.startsWith('tenant_leading_index.')) {
      return '${l10n.tenantIndex}: ${code.substring('tenant_leading_index.'.length)}';
    }
    return switch (code) {
      'tenant_context' => l10n.tenantContext,
      'posted_journal_balance' => l10n.postedJournalBalance,
      'currency_code_format' => l10n.currencyCodeFormat,
      'preflight_complete' => l10n.preflightComplete,
      _ => l10n.schemaHealthCheck,
    };
  }
}

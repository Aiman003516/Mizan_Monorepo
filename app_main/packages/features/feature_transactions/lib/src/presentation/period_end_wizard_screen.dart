import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:core_data/core_data.dart'; // For prefs

class PeriodEndWizardScreen extends ConsumerStatefulWidget {
  const PeriodEndWizardScreen({super.key});

  @override
  ConsumerState<PeriodEndWizardScreen> createState() =>
      _PeriodEndWizardScreenState();
}

class _PeriodEndWizardScreenState extends ConsumerState<PeriodEndWizardScreen> {
  DateTime _closingDate = DateTime.now();
  String? _selectedEquityAccountId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final prefs = ref.watch(preferencesRepositoryProvider);
    final currentLock = prefs.getPeriodLockDate();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closeBooks),
        backgroundColor: context.appColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            _buildInfoCard(
              context,
              title: l10n.currentLockDate,
              value: currentLock == null
                  ? l10n.booksAreOpen
                  : DateFormat.yMMMd().format(currentLock),
              icon: currentLock == null ? Icons.lock_open : Icons.lock,
              color: currentLock == null
                  ? context.appColors.primary
                  : context.appColors.primary,
            ),
            const SizedBox(height: 24),

            Text(
              l10n.closingInstructionsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.closingInstructionsBody,
              style: const TextStyle(height: 1.5),
            ),
            const Divider(height: 32),

            // --- STEP 1: DATE ---
            Text(
              l10n.stepSelectDate,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isProcessing
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _closingDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _closingDate = picked);
                      }
                    },
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat.yMMMd().format(_closingDate)),
              ),
            ),
            const SizedBox(height: 24),

            // --- STEP 2: EQUITY ACCOUNT ---
            Text(
              l10n.stepSelectEquityAccount,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) {
                // Filter for Equity accounts only
                final equityAccounts = accounts
                    .where((a) => a.type == 'equity')
                    .toList();

                if (equityAccounts.isEmpty) {
                  return Card(
                    color: context.appColors.error,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        l10n.errorNoEquityAccount,
                        style: TextStyle(color: context.appColors.onPrimary),
                      ),
                    ),
                  );
                }

                // Auto-select if only one
                if (_selectedEquityAccountId == null &&
                    equityAccounts.isNotEmpty) {
                  Future.microtask(
                    () => setState(
                      () => _selectedEquityAccountId = equityAccounts.first.id,
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedEquityAccountId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: equityAccounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: _isProcessing
                      ? null
                      : (v) => setState(() => _selectedEquityAccountId = v),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text("Error loading accounts: $e"),
            ),
            const SizedBox(height: 48),

            // --- THE BIG RED BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  foregroundColor: context.appColors.onPrimary,
                ),
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: context.appColors.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.lock_clock),
                label: Text(
                  l10n.closePeriodAndLock,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: (_isProcessing || _selectedEquityAccountId == null)
                    ? null
                    : () => _executeClose(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: context.appColors.subtleText),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _executeClose(BuildContext context, WidgetRef ref) async {
    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Period Close"),
        content: const Text(
          "Are you sure? This will lock all transactions on or before this date. "
          "This action cannot be easily undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm", style: TextStyle(color: context.appColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(transactionsRepositoryProvider)
          .closePeriod(
            closingDate: _closingDate,
            retainedEarningsAccountId: _selectedEquityAccountId!,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Period Closed Successfully.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: context.appColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

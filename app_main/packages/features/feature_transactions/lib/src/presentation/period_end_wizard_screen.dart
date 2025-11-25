import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:core_data/core_data.dart'; // For prefs

class PeriodEndWizardScreen extends ConsumerStatefulWidget {
  const PeriodEndWizardScreen({super.key});

  @override
  ConsumerState<PeriodEndWizardScreen> createState() => _PeriodEndWizardScreenState();
}

class _PeriodEndWizardScreenState extends ConsumerState<PeriodEndWizardScreen> {
  DateTime _closingDate = DateTime.now();
  String? _selectedEquityAccountId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Note: We use hardcoded strings here to avoid l10n errors.
    // In Phase 4 (Polish), we will move these to ARB files.
    final accountsAsync = ref.watch(accountsStreamProvider);
    final prefs = ref.watch(preferencesRepositoryProvider);
    final currentLock = prefs.getPeriodLockDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Close Books"),
        backgroundColor: Colors.red.shade50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            _buildInfoCard(
              context, 
              title: "Current Lock Date", 
              value: currentLock == null 
                  ? "Books are OPEN" 
                  : DateFormat.yMMMd().format(currentLock),
              icon: currentLock == null ? Icons.lock_open : Icons.lock,
              color: currentLock == null ? Colors.orange.shade100 : Colors.green.shade100,
            ),
            const SizedBox(height: 24),
            
            Text("Closing Instructions", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              "This action will:\n"
              "1. Zero out all Revenue & Expenses for the period.\n"
              "2. Transfer Net Income to Retained Earnings.\n"
              "3. LOCK the period from future edits.",
              style: TextStyle(height: 1.5),
            ),
            const Divider(height: 32),

            // --- STEP 1: DATE ---
            Text("Step 1: Select Closing Date", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isProcessing ? null : () async {
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
            Text("Step 2: Select Retained Earnings Account", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) {
                // Filter for Equity accounts only
                final equityAccounts = accounts.where((a) => a.type == 'equity').toList();
                
                if (equityAccounts.isEmpty) {
                  return const Card(
                    color: Colors.redAccent, 
                    child: Padding(
                      padding: EdgeInsets.all(8.0), 
                      child: Text("Error: No Equity accounts found. Please create one in Accounts.", style: TextStyle(color: Colors.white)),
                    )
                  );
                }

                // Auto-select if only one
                if (_selectedEquityAccountId == null && equityAccounts.isNotEmpty) {
                   Future.microtask(() => setState(() => _selectedEquityAccountId = equityAccounts.first.id));
                }

                return DropdownButtonFormField<String>(
                  value: _selectedEquityAccountId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: equityAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: _isProcessing ? null : (v) => setState(() => _selectedEquityAccountId = v),
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
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.lock_clock),
                label: const Text("CLOSE PERIOD & LOCK", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildInfoCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.black54),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await ref.read(transactionsRepositoryProvider).closePeriod(
        closingDate: _closingDate,
        retainedEarningsAccountId: _selectedEquityAccountId!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Period Closed Successfully.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
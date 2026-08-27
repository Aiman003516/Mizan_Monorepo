import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThreeWayMatchScreen extends ConsumerStatefulWidget {
  const ThreeWayMatchScreen({super.key});

  @override
  ConsumerState<ThreeWayMatchScreen> createState() =>
      _ThreeWayMatchScreenState();
}

class _ThreeWayMatchScreenState extends ConsumerState<ThreeWayMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billIdController = TextEditingController();
  AsyncValue<List<ThreeWayMatchResult>>? _result;

  @override
  void dispose() {
    _billIdController.dispose();
    super.dispose();
  }

  Future<void> _runMatch() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _result = const AsyncLoading());
    try {
      final rows = await ref
          .read(procurementRepositoryProvider)
          .matchBill(_billIdController.text.trim());
      if (mounted) setState(() => _result = AsyncData(rows));
    } catch (error, stackTrace) {
      if (mounted) setState(() => _result = AsyncError(error, stackTrace));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.threeWayMatching)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billIdController,
                    decoration: InputDecoration(labelText: l10n.billId),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: result is AsyncLoading ? null : _runMatch,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.runMatch),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (result is AsyncLoading)
            const Center(child: CircularProgressIndicator())
          else if (result is AsyncError)
            _Message(icon: Icons.error_outline, text: l10n.matchLoadFailed)
          else if (result is AsyncData<List<ThreeWayMatchResult>> &&
              result.value.isEmpty)
            _Message(icon: Icons.receipt_long_outlined, text: l10n.matchNoLines)
          else if (result is AsyncData<List<ThreeWayMatchResult>>)
            ...result.value.map((row) => _MatchCard(result: row)),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.result});

  final ThreeWayMatchResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final matched = result.isMatched;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  matched ? Icons.check_circle : Icons.block,
                  color: matched ? colors.primary : colors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.billLineId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(matched ? l10n.matchPassed : l10n.matchBlocked),
                ),
              ],
            ),
            const Divider(),
            _Metric(
              label: l10n.orderedQuantity,
              value: result.orderedQuantity.toString(),
            ),
            _Metric(
              label: l10n.receivedQuantity,
              value: result.receivedQuantity.toString(),
            ),
            _Metric(
              label: l10n.returnedQuantity,
              value: result.returnedQuantity.toString(),
            ),
            _Metric(
              label: l10n.availableQuantity,
              value: result.availableQuantity.toString(),
            ),
            _Metric(
              label: l10n.billedQuantity,
              value: result.billedQuantity.toString(),
            ),
            _Metric(
              label: l10n.priceVariance,
              value: result.priceVarianceMinor?.toString() ?? '—',
            ),
            if (result.blockingReason != null &&
                result.blockingReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.blockingReason}: ${result.blockingReason}',
                style: TextStyle(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

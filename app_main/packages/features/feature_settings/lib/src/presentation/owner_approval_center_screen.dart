import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../data/owner_approval_repository.dart';

class OwnerApprovalCenterScreen extends ConsumerWidget {
  const OwnerApprovalCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCloudMode = ref.watch(cloudDataModeProvider);
    final requestsAsync = ref.watch(serverApprovalRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.approvalCenter)),
      body: !isCloudMode
          ? _LocalModeNotice(l10n: l10n)
          : requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _ErrorState(l10n: l10n),
              data: (requests) => requests.isEmpty
                  ? _EmptyState(l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _ApprovalCard(
                        request: requests[index],
                        onDecision: (decision) =>
                            _decide(context, ref, requests[index], decision),
                      ),
                    ),
            ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest request,
    ApprovalStatus decision,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(approvalRepositoryProvider)
          .decideRequest(requestId: request.id, decision: decision);
      ref.invalidate(serverApprovalRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.approvalDecisionSaved)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.approvalDecisionFailed)));
      }
    }
  }
}

class _LocalModeNotice extends StatelessWidget {
  const _LocalModeNotice({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.cloud_off,
                  color: context.appColors.primary,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noPendingApprovals,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(l10n.approvalActionLocalOnly),
                const SizedBox(height: 12),
                Text(l10n.approvalRequestDemo),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.approvalLoadError,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appColors.error),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.fact_check,
                  color: context.appColors.primary,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noPendingApprovals,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(l10n.approvalServerOnly),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.request, required this.onDecision});

  final ApprovalRequest request;
  final Future<void> Function(ApprovalStatus decision) onDecision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = request.status == ApprovalStatus.pending;
    final amount = CurrencyFormatter.formatAmount(
      request.amountMinor,
      request.currencyCode,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _typeLabel(l10n, request.requestType),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_statusLabel(l10n, request.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.labelValue(l10n.requester, request.requesterId)),
            Text(l10n.labelValue(l10n.approvalAmount, amount)),
            Text(l10n.labelValue(l10n.approvalReason, request.reason)),
            if (request.branchId != null)
              Text(l10n.labelValue(l10n.activeBranch, request.branchId!)),
            if (isPending) ...[
              const SizedBox(height: 12),
              Text(
                l10n.approvalServerOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => onDecision(ApprovalStatus.rejected),
                    child: Text(l10n.rejectRequest),
                  ),
                  FilledButton(
                    onPressed: () => onDecision(ApprovalStatus.approved),
                    child: Text(l10n.approveRequest),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, ApprovalRequestType type) =>
      switch (type) {
        ApprovalRequestType.expense => l10n.approvalRequestTypeExpense,
        ApprovalRequestType.invoice => l10n.approvalRequestTypeInvoice,
        ApprovalRequestType.bill => l10n.approvalRequestTypeBill,
        ApprovalRequestType.journal => l10n.approvalRequestTypeJournal,
        ApprovalRequestType.balanceAdjustment =>
          l10n.approvalRequestTypeBalanceAdjustment,
        ApprovalRequestType.refund => l10n.approvalRequestTypeRefund,
        ApprovalRequestType.discount => l10n.approvalRequestTypeDiscount,
        ApprovalRequestType.periodReopen =>
          l10n.approvalRequestTypePeriodReopen,
      };

  String _statusLabel(AppLocalizations l10n, ApprovalStatus status) =>
      switch (status) {
        ApprovalStatus.approved => l10n.approvalStatusApproved,
        ApprovalStatus.rejected => l10n.approvalStatusRejected,
        ApprovalStatus.pending => l10n.approvalStatusPending,
      };
}

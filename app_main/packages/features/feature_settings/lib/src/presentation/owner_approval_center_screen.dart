import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_approval_repository.dart';

class OwnerApprovalCenterScreen extends ConsumerWidget {
  const OwnerApprovalCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final requests = ref.watch(ownerApprovalRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.approvalCenter)),
      body: requests.isEmpty
          ? ListView(
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
                        Text(l10n.approvalActionLocalOnly),
                        const SizedBox(height: 12),
                        Text(
                          l10n.approvalRequestDemo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _ApprovalCard(request: requests[index]),
            ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.request});

  final OwnerApprovalRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = request.status == 'pending';
    final amount = '${request.amountMinor / 100} ${request.currencyCode}';
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
                    request.type,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_statusLabel(l10n, request.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text('${l10n.requester}: ${request.requester}'),
            Text('${l10n.approvalAmount}: $amount'),
            Text('${l10n.approvalReason}: ${request.reason}'),
            if (isPending) ...[
              const SizedBox(height: 12),
              Text(
                l10n.approvalActionLocalOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => ref
                        .read(ownerApprovalRequestsProvider.notifier)
                        .decide(request.id, 'rejected'),
                    child: Text(l10n.rejectRequest),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => ref
                        .read(ownerApprovalRequestsProvider.notifier)
                        .decide(request.id, 'approved'),
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

  String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
    'approved' => l10n.approvalStatusApproved,
    'rejected' => l10n.approvalStatusRejected,
    _ => l10n.approvalStatusPending,
  };
}

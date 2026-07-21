import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:shared_ui/shared_ui.dart';

enum ContactType { receivable, payable }

class ContactDetailBody extends StatelessWidget {
  final ContactType type;
  final String contactName;
  final String? email;
  final String phone;
  final String address;
  final String taxId;
  final String extraInfoLabel;
  final String extraInfoValue;

  final int balance;
  final String currencyCode;
  final String outstandingBalanceLabel;
  final String? quickAdjustmentLabel;

  final VoidCallback onEdit;
  final VoidCallback onNewDocument;
  final VoidCallback? onQuickAdjustment;

  final String newDocumentLabel;
  final IconData newDocumentIcon;

  final String documentsSectionTitle;
  final int documentsCount;
  final bool isLoadingDocuments;
  final Object? documentsError;
  final bool hasDocuments;
  final String noDocumentsMessage;
  final IconData noDocumentsIcon;
  final Widget Function(BuildContext context, int index) documentBuilder;

  const ContactDetailBody({
    super.key,
    required this.type,
    required this.contactName,
    this.email,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.extraInfoLabel,
    required this.extraInfoValue,
    required this.balance,
    required this.currencyCode,
    required this.outstandingBalanceLabel,
    this.quickAdjustmentLabel,
    required this.onEdit,
    required this.onNewDocument,
    this.onQuickAdjustment,
    required this.newDocumentLabel,
    required this.newDocumentIcon,
    required this.documentsSectionTitle,
    required this.documentsCount,
    required this.isLoadingDocuments,
    this.documentsError,
    required this.hasDocuments,
    required this.noDocumentsMessage,
    required this.noDocumentsIcon,
    required this.documentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine colors based on contact type
    final primaryAvatarColor = type == ContactType.payable ? colorScheme.tertiary : colorScheme.primary;
    final onPrimaryAvatarColor = type == ContactType.payable ? colorScheme.onTertiary : colorScheme.onPrimary;

    final balanceColors = balance > 0
        ? (type == ContactType.payable
            ? [colorScheme.tertiary, colorScheme.tertiaryContainer]
            : [colorScheme.error, colorScheme.errorContainer])
        : [context.appColors.success, context.appColors.primary];

    return Scaffold(
      appBar: AppBar(
        title: Text(contactName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onNewDocument,
        icon: Icon(newDocumentIcon),
        label: Text(newDocumentLabel),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contact Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: primaryAvatarColor,
                        child: Text(
                          contactName.isNotEmpty ? contactName.substring(0, 1).toUpperCase() : '?',
                          style: TextStyle(
                            color: onPrimaryAvatarColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contactName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (email != null && email!.isNotEmpty)
                              Text(
                                email!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _InfoRow(
                    icon: Icons.phone,
                    label: 'Phone', // You could pass this in as well, but keeping it simple
                    value: phone,
                  ),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: address,
                  ),
                  _InfoRow(
                    icon: Icons.receipt_long,
                    label: 'Tax ID',
                    value: taxId,
                  ),
                  _InfoRow(
                    icon: type == ContactType.payable ? Icons.schedule : Icons.credit_card,
                    label: extraInfoLabel,
                    value: extraInfoValue,
                  ),
                ],
              ),
            ),

            // Balance Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: balanceColors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    outstandingBalanceLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatAmount(balance, currencyCode),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: context.appColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onQuickAdjustment != null && quickAdjustmentLabel != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onQuickAdjustment,
                      icon: const Icon(Icons.sync_alt, color: Colors.black87),
                      label: Text(
                        quickAdjustmentLabel!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Documents Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    documentsSectionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isLoadingDocuments && documentsError == null)
                    Text(
                      '$documentsCount $documentsSectionTitle',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),

            if (isLoadingDocuments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (documentsError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $documentsError'),
              )
            else if (!hasDocuments)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      noDocumentsIcon,
                      size: 48,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      noDocumentsMessage,
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documentsCount,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: documentBuilder,
              ),

            const SizedBox(height: 120), // Extra space for extended FAB
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

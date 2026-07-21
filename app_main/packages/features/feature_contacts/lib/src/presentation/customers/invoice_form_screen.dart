import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

class InvoiceFormScreen extends ConsumerWidget {
  final String customerId;

  const InvoiceFormScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DocumentFormBody(
      type: DocumentType.invoice,
      contactId: customerId,
      title: 'New Invoice',
    );
  }
}

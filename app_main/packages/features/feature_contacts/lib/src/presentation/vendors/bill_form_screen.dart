import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

class BillFormScreen extends ConsumerWidget {
  final String vendorId;

  const BillFormScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DocumentFormBody(
      type: DocumentType.bill,
      contactId: vendorId,
      title: 'New Bill',
    );
  }
}

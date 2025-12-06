// FILE: packages/features/feature_settings/lib/src/data/custom_fields_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomFieldsRepository {
  final FirebaseFirestore _firestore;

  CustomFieldsRepository(this._firestore);

  /// Stream definitions for a specific table (e.g., 'products')
  Stream<List<CustomFieldDefinition>> watchDefinitions(String tenantId, String targetTable) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('custom_fields')
        .collection('definitions')
        .where('targetTable', isEqualTo: targetTable)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomFieldDefinition.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  /// Add or Update a Definition
  Future<void> saveDefinition(String tenantId, CustomFieldDefinition def) async {
    final ref = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('custom_fields')
        .collection('definitions');

    if (def.id.isEmpty || def.id == 'new') {
      await ref.add(def.toJson());
    } else {
      await ref.doc(def.id).update(def.toJson());
    }
  }

  /// Delete a Definition
  Future<void> deleteDefinition(String tenantId, String defId) async {
    await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('custom_fields')
        .collection('definitions')
        .doc(defId)
        .delete();
  }
}

final customFieldsRepositoryProvider = Provider<CustomFieldsRepository>((ref) {
  return CustomFieldsRepository(FirebaseFirestore.instance);
});

// Helper Stream: Get Product Fields
final productFieldsProvider = StreamProvider.family<List<CustomFieldDefinition>, String>((ref, tenantId) {
  return ref.watch(customFieldsRepositoryProvider).watchDefinitions(tenantId, 'products');
});
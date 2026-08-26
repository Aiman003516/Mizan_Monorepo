import 'dart:convert';

import 'package:core_data/core_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ownerApprovalSchemaVersion = 'mizan.owner-approval/v1';

class OwnerApprovalRequest {
  const OwnerApprovalRequest({
    required this.id,
    required this.type,
    required this.requester,
    required this.reason,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.createdAt,
    this.targetId,
    this.decisionAt,
  });

  final String id;
  final String type;
  final String requester;
  final String reason;
  final int amountMinor;
  final String currencyCode;
  final String status;
  final DateTime createdAt;
  final String? targetId;
  final DateTime? decisionAt;

  Map<String, Object?> toJson() => {
    'schema_version': ownerApprovalSchemaVersion,
    'id': id,
    'type': type,
    'requester': requester,
    'reason': reason,
    'amount_minor': amountMinor,
    'currency_code': currencyCode,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'target_id': targetId,
    'decision_at': decisionAt?.toIso8601String(),
  };

  factory OwnerApprovalRequest.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid approval request');
    final json = Map<String, Object?>.from(value);
    if (json['schema_version'] != ownerApprovalSchemaVersion ||
        json['id'] is! String ||
        json['type'] is! String ||
        json['requester'] is! String ||
        json['reason'] is! String ||
        json['amount_minor'] is! int ||
        (json['amount_minor'] as int) < 0 ||
        json['currency_code'] is! String ||
        json['status'] is! String ||
        !{'pending', 'approved', 'rejected'}.contains(json['status']) ||
        json['created_at'] is! String ||
        DateTime.tryParse(json['created_at'] as String) == null ||
        json['target_id'] != null && json['target_id'] is! String ||
        json['decision_at'] != null &&
            (json['decision_at'] is! String ||
                DateTime.tryParse(json['decision_at'] as String) == null)) {
      throw const FormatException('Approval request values are invalid');
    }
    return OwnerApprovalRequest(
      id: json['id'] as String,
      type: json['type'] as String,
      requester: json['requester'] as String,
      reason: json['reason'] as String,
      amountMinor: json['amount_minor'] as int,
      currencyCode: json['currency_code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      targetId: json['target_id'] as String?,
      decisionAt: json['decision_at'] == null
          ? null
          : DateTime.parse(json['decision_at'] as String),
    );
  }

  OwnerApprovalRequest decide(String nextStatus) {
    if (status != 'pending' || !{'approved', 'rejected'}.contains(nextStatus)) {
      throw StateError('Only pending approvals can be decided');
    }
    return OwnerApprovalRequest(
      id: id,
      type: type,
      requester: requester,
      reason: reason,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      status: nextStatus,
      createdAt: createdAt,
      targetId: targetId,
      decisionAt: DateTime.now().toUtc(),
    );
  }
}

class OwnerApprovalRepository {
  OwnerApprovalRepository(this._preferences);

  static const key = 'mizan_owner_approval_requests_v1';
  final SharedPreferences _preferences;

  List<OwnerApprovalRequest> load() {
    final encoded = _preferences.getString(key);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List)
        throw const FormatException('Invalid approvals list');
      return decoded.map(OwnerApprovalRequest.fromJson).toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<List<OwnerApprovalRequest>> save(
    List<OwnerApprovalRequest> requests,
  ) async {
    final encoded = jsonEncode(
      requests.map((request) => request.toJson()).toList(),
    );
    if (!await _preferences.setString(key, encoded)) {
      throw StateError('Approval requests could not be persisted');
    }
    return List.unmodifiable(requests);
  }

  Future<List<OwnerApprovalRequest>> decide(String id, String status) async {
    final requests = load();
    final index = requests.indexWhere((request) => request.id == id);
    if (index == -1) throw StateError('Approval request not found');
    final next = List<OwnerApprovalRequest>.from(requests);
    next[index] = next[index].decide(status);
    return save(next);
  }
}

final ownerApprovalRepositoryProvider = Provider<OwnerApprovalRepository>((
  ref,
) {
  return OwnerApprovalRepository(ref.watch(sharedPreferencesProvider));
});

final ownerApprovalRequestsProvider =
    StateNotifierProvider<OwnerApprovalController, List<OwnerApprovalRequest>>(
      (ref) =>
          OwnerApprovalController(ref.watch(ownerApprovalRepositoryProvider)),
    );

class OwnerApprovalController
    extends StateNotifier<List<OwnerApprovalRequest>> {
  OwnerApprovalController(this._repository) : super(_repository.load());

  final OwnerApprovalRepository _repository;

  Future<void> decide(String id, String status) async {
    state = await _repository.decide(id, status);
  }
}

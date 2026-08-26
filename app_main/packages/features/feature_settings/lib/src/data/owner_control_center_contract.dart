import 'dart:convert';

const ownerSettingsSchemaVersion = 'mizan.owner-settings/v1';

abstract final class OwnerSettingSections {
  static const company = 'company';
  static const branches = 'branches';
  static const accounting = 'accounting';
  static const currencies = 'currencies';
  static const taxes = 'taxes';
  static const documents = 'documents';
  static const employees = 'employees';
  static const approvals = 'approvals';
  static const crm = 'crm';
  static const inventory = 'inventory';
  static const pos = 'pos';
  static const payments = 'payments';
  static const notifications = 'notifications';
  static const sync = 'sync';
  static const privacy = 'privacy';
  static const security = 'security';
  static const localization = 'localization';
  static const integrations = 'integrations';
  static const expenses = 'expenses';
  static const banking = 'banking';
  static const reports = 'reports';
  static const close = 'close';

  static const all = <String>{
    company,
    branches,
    accounting,
    currencies,
    taxes,
    documents,
    employees,
    approvals,
    crm,
    inventory,
    pos,
    payments,
    notifications,
    sync,
    privacy,
    security,
    localization,
    integrations,
    expenses,
    banking,
    reports,
    close,
  };
}

/// Canonical keys accepted by each Owner Control Center section.
///
/// The registry prevents UI screens from inventing ad-hoc setting names. It is
/// a client contract only; authenticated writes must later be revalidated by
/// tenant-scoped server functions/RLS.
abstract final class OwnerSettingKeys {
  static const bySection = <String, Set<String>>{
    OwnerSettingSections.company: {
      'business_name',
      'legal_name',
      'logo_path',
      'address',
      'phone',
      'tax_number',
      'industry',
      'fiscal_year_start_month',
      'document_footer',
    },
    OwnerSettingSections.branches: {
      'default_branch_id',
      'default_branch_name',
      'branch_ids',
      'branch_records',
      'branch_access_mode',
    },
    OwnerSettingSections.accounting: {
      'base_currency_code',
      'rounding_mode',
      'retained_earnings_account_id',
      'default_income_account_id',
      'default_expense_account_id',
      'period_close_requires_owner',
      'opening_balance_status',
    },
    OwnerSettingSections.currencies: {
      'enabled_currency_codes',
      'exchange_rate_source',
      'manual_rate_requires_owner',
      'rate_effective_date_policy',
      'revaluation_enabled',
      'foreign_exchange_gain_account_id',
      'foreign_exchange_loss_account_id',
    },
    OwnerSettingSections.taxes: {
      'default_tax_code',
      'tax_inclusive_pricing',
      'tax_number_required',
      'tax_exempt_reasons',
      'tax_period',
      'tax_account_ids',
    },
    OwnerSettingSections.documents: {
      'invoice_prefix',
      'invoice_next_number',
      'bill_prefix',
      'bill_next_number',
      'receipt_prefix',
      'receipt_next_number',
      'quote_prefix',
      'quote_next_number',
      'credit_note_prefix',
      'credit_note_next_number',
      'debit_note_prefix',
      'debit_note_next_number',
      'payment_prefix',
      'payment_next_number',
      'journal_prefix',
      'journal_next_number',
    },
    OwnerSettingSections.employees: {
      'default_role_id',
      'invitation_expiry_hours',
      'max_active_staff',
      'require_mfa_for_staff',
      'allow_self_service_profile_edit',
      'default_branch_assignment',
      'pending_first_employee_email',
    },
    OwnerSettingSections.approvals: {
      'expense_threshold_minor',
      'invoice_threshold_minor',
      'bill_threshold_minor',
      'journal_requires_second_approver',
      'balance_adjustment_requires_owner',
      'refund_requires_approval',
      'discount_max_percent_without_approval',
      'period_reopen_requires_owner',
    },
    OwnerSettingSections.crm: {
      'lead_stages',
      'pipeline_stages',
      'interaction_types',
      'default_follow_up_days',
      'customer_categories',
      'default_customer_credit_limit_minor',
      'duplicate_match_fields',
    },
    OwnerSettingSections.inventory: {
      'warehouse_ids',
      'default_warehouse_id',
      'stock_valuation_method',
      'negative_stock_policy',
      'low_stock_notification_enabled',
      'default_reorder_point',
      'price_list_ids',
      'barcode_required_for_pos',
    },
    OwnerSettingSections.pos: {
      'terminal_ids',
      'cash_drawer_ids',
      'shift_close_requires_owner',
      'refund_requires_approval',
      'max_discount_percent',
      'receipt_template_id',
      'allow_suspend_sale',
    },
    OwnerSettingSections.payments: {
      'enabled_methods',
      'merchant_payment_instructions',
      'proof_review_required',
      'credit_terms_enabled',
      'default_payment_method',
    },
    OwnerSettingSections.notifications: {
      'invoice_due_reminders',
      'low_stock_alerts',
      'approval_alerts',
      'sync_failure_alerts',
      'invitation_alerts',
      'backup_alerts',
      'suspicious_login_alerts',
    },
    OwnerSettingSections.sync: {
      'sync_enabled',
      'wifi_only_backup',
      'backup_frequency_hours',
      'google_drive_connected',
      'retention_days',
      'restore_requires_owner',
      'conflict_policy',
    },
    OwnerSettingSections.privacy: {
      'ai_mode',
      'local_model_enabled',
      'prompt_retention',
      'allow_employee_ai_access',
      'minimize_cloud_ai_identifiers',
    },
    OwnerSettingSections.security: {
      'session_duration_hours',
      'force_sign_out_all_devices',
      'audit_retention_days',
      'export_requires_owner',
      'password_minimum_length',
      'mfa_policy',
    },
    OwnerSettingSections.localization: {
      'default_language',
      'document_language',
      'rtl_enabled',
      'date_format',
      'number_format',
      'timezone',
      'default_country',
    },
    OwnerSettingSections.integrations: {
      'email_enabled',
      'sms_enabled',
      'bank_import_format',
      'barcode_scanner_enabled',
      'printer_enabled',
      'google_drive_enabled',
      'payment_provider_status',
    },
    OwnerSettingSections.expenses: {
      'default_expense_account_id',
      'expense_categories',
      'receipt_required',
      'reimbursement_requires_approval',
      'mileage_enabled',
    },
    OwnerSettingSections.banking: {
      'bank_account_ids',
      'statement_import_format',
      'reconciliation_requires_owner',
      'auto_match_enabled',
      'banking_currency_codes',
    },
    OwnerSettingSections.reports: {
      'default_report_period',
      'report_export_requires_owner',
      'dashboard_metrics',
      'scheduled_reports',
    },
    OwnerSettingSections.close: {
      'close_checklist',
      'close_requires_reconciliation',
      'close_requires_backup',
      'reopen_requires_owner',
    },
  };
}

class OwnerSettingsValidationResult {
  const OwnerSettingsValidationResult(this.errors);

  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

class OwnerControlSettings {
  OwnerControlSettings({
    Map<String, Map<String, Object?>> sections = const {},
    this.schemaVersion = ownerSettingsSchemaVersion,
    this.revision = 0,
    DateTime? updatedAt,
    this.tenantId,
  }) : sections = _copySections(sections),
       updatedAt =
           updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final String schemaVersion;
  final int revision;
  final DateTime updatedAt;
  final String? tenantId;
  final Map<String, Map<String, Object?>> sections;

  Map<String, Object?> section(String name) =>
      Map.unmodifiable(sections[name] ?? const <String, Object?>{});

  OwnerControlSettings copyWithSection(
    String sectionName,
    Map<String, Object?> values, {
    String? tenantId,
  }) {
    final next = _copySections(sections);
    next[sectionName] = Map<String, Object?>.from(values);
    return OwnerControlSettings(
      schemaVersion: schemaVersion,
      revision: revision + 1,
      updatedAt: DateTime.now().toUtc(),
      tenantId: tenantId ?? this.tenantId,
      sections: next,
    );
  }

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'revision': revision,
    'updated_at': updatedAt.toIso8601String(),
    'tenant_id': tenantId,
    'sections': sections,
  };

  String encode() => jsonEncode(toJson());

  factory OwnerControlSettings.decode(String value) =>
      OwnerControlSettings.fromJson(jsonDecode(value));

  factory OwnerControlSettings.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid owner settings document');
    }
    final json = Map<String, Object?>.from(value);
    const required = {
      'schema_version',
      'revision',
      'updated_at',
      'tenant_id',
      'sections',
    };
    if (json.keys.length != required.length ||
        !json.keys.toSet().containsAll(required)) {
      throw const FormatException('Owner settings keys are invalid');
    }
    final schemaVersion = json['schema_version'];
    final revision = json['revision'];
    final updatedAt = json['updated_at'];
    final tenantId = json['tenant_id'];
    final sections = json['sections'];
    if (schemaVersion != ownerSettingsSchemaVersion ||
        revision is! int ||
        revision < 0 ||
        updatedAt is! String ||
        DateTime.tryParse(updatedAt) == null ||
        tenantId != null && tenantId is! String ||
        sections is! Map) {
      throw const FormatException('Owner settings values are invalid');
    }

    final parsed = <String, Map<String, Object?>>{};
    for (final entry in sections.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Owner settings section is invalid');
      }
      parsed[entry.key as String] = Map<String, Object?>.from(
        entry.value as Map,
      );
    }
    final settings = OwnerControlSettings(
      schemaVersion: schemaVersion as String,
      revision: revision,
      updatedAt: DateTime.parse(updatedAt),
      tenantId: tenantId as String?,
      sections: parsed,
    );
    final validation = validate(settings);
    if (!validation.isValid) {
      throw FormatException(validation.errors.join('; '));
    }
    return settings;
  }

  static OwnerSettingsValidationResult validate(OwnerControlSettings settings) {
    final errors = <String>[];
    if (settings.schemaVersion != ownerSettingsSchemaVersion) {
      errors.add('schema_version is unsupported');
    }
    if (settings.revision < 0) errors.add('revision must be non-negative');
    if (settings.updatedAt.isBefore(DateTime.fromMillisecondsSinceEpoch(0))) {
      errors.add('updated_at is invalid');
    }
    for (final entry in settings.sections.entries) {
      final allowed = OwnerSettingKeys.bySection[entry.key];
      if (allowed == null) {
        errors.add('unknown settings section: ${entry.key}');
        continue;
      }
      for (final key in entry.value.keys) {
        if (!allowed.contains(key)) {
          errors.add('unsupported setting key: ${entry.key}.$key');
        }
      }
    }
    return OwnerSettingsValidationResult(List.unmodifiable(errors));
  }

  static Map<String, Map<String, Object?>> _copySections(
    Map<String, Map<String, Object?>> source,
  ) {
    return {
      for (final entry in source.entries)
        entry.key: Map<String, Object?>.from(entry.value),
    };
  }
}

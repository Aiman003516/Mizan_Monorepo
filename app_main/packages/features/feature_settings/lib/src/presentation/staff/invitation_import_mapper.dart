import 'package:core_data/core_data.dart';
import 'package:feature_data_import/src/data/file_parser.dart';
import 'package:shared_ui/shared_ui.dart';

class InvitationImportRow {
  const InvitationImportRow({
    required this.rowNumber,
    this.recipient,
    this.errorCode,
  });

  final int rowNumber;
  final BulkInvitationRecipient? recipient;
  final String? errorCode;

  bool get isValid => recipient != null && errorCode == null;
}

class InvitationImportMapper {
  static String _key(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-./]+'), '');

  static String? autoDetect(List<String> headers, Set<String> aliases) {
    for (final header in headers) {
      if (aliases.contains(_key(header))) return header;
    }
    return null;
  }

  static String _value(Map<String, dynamic> row, String? column) {
    if (column == null || column.isEmpty) return '';
    return row[column]?.toString().trim() ?? '';
  }

  List<InvitationImportRow> map({
    required ParsedFileResult file,
    String? emailColumn,
    String? phoneColumn,
    String? nameColumn,
    required String deliveryChannel,
  }) {
    final seen = <String>{};
    final rows = <InvitationImportRow>[];
    for (var index = 0; index < file.rows.length; index++) {
      final row = file.rows[index];
      final email = _value(row, emailColumn).toLowerCase();
      final phone = _value(row, phoneColumn);
      final name = _value(row, nameColumn);
      String? errorCode;
      if (email.isEmpty && phone.isEmpty) {
        errorCode = 'contact_required';
      } else {
        final emailError = InputValidators.optionalEmail(
          email,
          invalidMessage: 'invalid_email',
        );
        final phoneError = InputValidators.optionalPhone(
          phone,
          invalidMessage: 'invalid_phone',
        );
        if (emailError != null) {
          errorCode = 'invalid_email';
        } else if (phoneError != null) {
          errorCode = 'invalid_phone';
        }
      }
      final identity = email.isNotEmpty ? 'email:$email' : 'phone:$phone';
      if (errorCode == null && !seen.add(identity)) errorCode = 'duplicate';
      rows.add(
        InvitationImportRow(
          rowNumber: index + 2,
          errorCode: errorCode,
          recipient: errorCode == null
              ? BulkInvitationRecipient(
                  email: email.isEmpty ? null : email,
                  phone: phone.isEmpty ? null : phone,
                  displayName: name.isEmpty ? null : name,
                  deliveryChannel: deliveryChannel,
                )
              : null,
        ),
      );
    }
    return rows;
  }
}

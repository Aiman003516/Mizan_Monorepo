import 'package:flutter_test/flutter_test.dart';
import 'package:feature_data_import/src/data/file_parser.dart';

import '../lib/src/presentation/staff/invitation_import_mapper.dart';

void main() {
  final mapper = InvitationImportMapper();

  test('auto-detects common email, phone, and name aliases', () {
    const headers = ['Full Name', 'Mobile Number', 'E-mail'];
    expect(
      InvitationImportMapper.autoDetect(headers, {'fullname', 'name'}),
      'Full Name',
    );
    expect(
      InvitationImportMapper.autoDetect(headers, {'mobile', 'mobilenumber'}),
      'Mobile Number',
    );
    expect(
      InvitationImportMapper.autoDetect(headers, {'email', 'emailaddress'}),
      'E-mail',
    );
  });

  test('maps valid rows and rejects duplicates and malformed contacts', () {
    final file = ParsedFileResult(
      headers: const ['Name', 'Email', 'Phone'],
      rows: const [
        {'Name': 'One', 'Email': 'one@example.com', 'Phone': ''},
        {'Name': 'Duplicate', 'Email': 'ONE@example.com', 'Phone': ''},
        {'Name': 'Two', 'Email': '', 'Phone': '+967 711234567'},
        {'Name': 'Bad', 'Email': 'not-an-email', 'Phone': ''},
        {'Name': 'Empty', 'Email': '', 'Phone': ''},
      ],
      fileName: 'employees.csv',
      fileType: ImportFileType.csv,
    );

    final rows = mapper.map(
      file: file,
      emailColumn: 'Email',
      phoneColumn: 'Phone',
      nameColumn: 'Name',
      deliveryChannel: 'manual',
    );

    expect(rows.where((row) => row.isValid), hasLength(2));
    expect(rows[0].recipient?.displayName, 'One');
    expect(rows[2].recipient?.phone, '+967 711234567');
    expect(rows[1].errorCode, 'duplicate');
    expect(rows[3].errorCode, 'invalid_email');
    expect(rows[4].errorCode, 'contact_required');
  });
}

/// Shared validation rules for user-entered contact and financial values.
///
/// The validators accept localized error messages from the calling screen so
/// validation logic stays language-neutral while the UI remains localized.
class InputValidators {
  InputValidators._();

  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9][0-9 ()-]{6,19}$');
  static final RegExp _decimalPattern = RegExp(
    r'^-?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)$',
  );
  static final RegExp _currencyCodePattern = RegExp(r'^[A-Z]{3,5}$');

  static String? optionalEmail(
    String? value, {
    required String invalidMessage,
  }) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    return _emailPattern.hasMatch(email) ? null : invalidMessage;
  }

  static String? optionalPhone(
    String? value, {
    required String invalidMessage,
  }) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;
    if (!_phonePattern.hasMatch(phone)) return invalidMessage;

    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 && digits.length <= 15 ? null : invalidMessage;
  }

  static String? requiredDecimal(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
    double? minimum,
    bool allowNegative = true,
    bool exclusiveMinimum = false,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return requiredMessage;
    if (!_decimalPattern.hasMatch(raw)) return invalidMessage;

    final parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite) return invalidMessage;
    if (!allowNegative && parsed < 0) return invalidMessage;
    if (minimum != null &&
        (exclusiveMinimum ? parsed <= minimum : parsed < minimum)) {
      return invalidMessage;
    }
    return null;
  }

  static String? optionalDecimal(
    String? value, {
    required String invalidMessage,
    double minimum = 0,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    return requiredDecimal(
      raw,
      requiredMessage: invalidMessage,
      invalidMessage: invalidMessage,
      minimum: minimum,
      allowNegative: minimum < 0,
    );
  }

  static String? currencyCode(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final code = value?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return requiredMessage;
    return _currencyCodePattern.hasMatch(code) ? null : invalidMessage;
  }
}

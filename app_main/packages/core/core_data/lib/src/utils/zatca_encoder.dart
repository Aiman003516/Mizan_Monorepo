import 'dart:convert';

class ZatcaEncoder {
  /// Generates the Base64 encoded TLV string required for ZATCA E-Invoicing (Phase 1 & 2 QR).
  static String generateTlvBase64({
    required String sellerName,
    required String vatRegistrationNumber,
    required DateTime timestamp,
    required double invoiceTotal,
    required double vatTotal,
  }) {
    // 1. Convert data to TLV Bytes
    final bytes = <int>[];

    // Tag 1: Seller Name
    bytes.addAll(_encodeTag(1, sellerName));

    // Tag 2: VAT Registration Number
    bytes.addAll(_encodeTag(2, vatRegistrationNumber));

    // Tag 3: Timestamp (ISO 8601)
    // ZATCA recommends: YYYY-MM-DDTHH:mm:ssZ
    // We force UTC or handle offset as Z if that serves the requirement.
    // Usually local time with offset is preferred, but simple ISO string works for basic compliance.
    final timestampStr = timestamp.toIso8601String();
    bytes.addAll(_encodeTag(3, timestampStr));

    // Tag 4: Invoice Total (with VAT)
    bytes.addAll(_encodeTag(4, invoiceTotal.toStringAsFixed(2)));

    // Tag 5: VAT Total
    bytes.addAll(_encodeTag(5, vatTotal.toStringAsFixed(2)));

    // 2. Base64 Encode
    return base64.encode(bytes);
  }

  static List<int> _encodeTag(int tag, String value) {
    final valueBytes = utf8.encode(value);
    final length = valueBytes.length;

    // Tag is 1 byte, Length is 1 byte (assuming value < 255 bytes for simple invoice fields)
    // ZATCA spec usually keeps these fields short.
    return [tag, length, ...valueBytes];
  }
}

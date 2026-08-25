import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('InputValidators.optionalEmail', () {
    test('accepts a valid address and blank optional input', () {
      expect(
        InputValidators.optionalEmail(
          'person@example.co.uk',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
      expect(
        InputValidators.optionalEmail('', invalidMessage: 'invalid'),
        isNull,
      );
    });

    test('rejects malformed addresses', () {
      for (final value in [
        'person',
        'person@',
        '@example.com',
        'a@b',
        'a b@example.com',
      ]) {
        expect(
          InputValidators.optionalEmail(value, invalidMessage: 'invalid'),
          'invalid',
          reason: 'Expected $value to be rejected',
        );
      }
    });
  });

  test(
    'optionalPhone accepts international formatting but rejects arbitrary text',
    () {
      expect(
        InputValidators.optionalPhone(
          '+966 50 123 4567',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
      expect(
        InputValidators.optionalPhone('not a phone', invalidMessage: 'invalid'),
        'invalid',
      );
    },
  );

  test('currencyCode requires three to five uppercase letters', () {
    expect(
      InputValidators.currencyCode(
        'USD',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      isNull,
    );
    expect(
      InputValidators.currencyCode(
        'usd1',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      'invalid',
    );
  });

  test('requiredDecimal enforces valid syntax and positive minimums', () {
    expect(
      InputValidators.requiredDecimal(
        '12.50',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
        minimum: 0,
        allowNegative: false,
      ),
      isNull,
    );
    expect(
      InputValidators.requiredDecimal(
        '-1',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
        minimum: 0,
        allowNegative: false,
      ),
      'invalid',
    );
    expect(
      InputValidators.requiredDecimal(
        '0',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
        minimum: 0.000001,
        allowNegative: false,
      ),
      'invalid',
    );
  });
}

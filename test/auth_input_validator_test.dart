import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/models/auth_input_validator.dart';

void main() {
  group('メールアドレス', () {
    test('未入力や不正な形式を拒否する', () {
      for (final value in [
        null,
        '',
        ' ',
        'sample',
        'a@',
        '@example.com',
        'a b@example.com',
        'a@@example.com',
      ]) {
        expect(
          AuthInputValidator.validateEmail(value),
          isNotNull,
          reason: '$value',
        );
      }
    });
    test('前後の空白を除いたメールアドレスを許可する', () {
      expect(
        AuthInputValidator.validateEmail(' sample+1@example.com '),
        isNull,
      );
    });
  });

  group('新規登録のパスワード', () {
    test('7文字は拒否し8文字から許可する', () {
      expect(
        AuthInputValidator.validatePassword('abc1234', isRegistering: true),
        isNotNull,
      );
      expect(
        AuthInputValidator.validatePassword('abc12345', isRegistering: true),
        isNull,
      );
      expect(
        AuthInputValidator.validatePassword('abc123456', isRegistering: true),
        isNull,
      );
    });
    test('英字と数字を1文字ずつ必要とし、記号を許可する', () {
      for (final value in [
        '',
        'abcdefgh',
        '12345678',
        '!!!!!!!!',
        'あいうえお123',
      ]) {
        expect(
          AuthInputValidator.validatePassword(value, isRegistering: true),
          isNotNull,
          reason: value,
        );
      }
      for (final value in ['a1234567', 'abcdefg1', 'A1!!!!!!']) {
        expect(
          AuthInputValidator.validatePassword(value, isRegistering: true),
          isNull,
          reason: value,
        );
      }
    });
  });

  test('ログインは必須チェックのみ行う', () {
    expect(
      AuthInputValidator.validatePassword(null, isRegistering: false),
      isNotNull,
    );
    expect(
      AuthInputValidator.validatePassword('', isRegistering: false),
      isNotNull,
    );
    expect(
      AuthInputValidator.validatePassword('a', isRegistering: false),
      isNull,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_vault/core/crypto/key_derivation.dart';

void main() {
  late KeyDerivation keyDerivation;

  setUp(() {
    keyDerivation = KeyDerivation();
  });

  group('PBKDF2 密钥派生', () {
    test('相同 PIN 和 salt 应生成相同密钥', () {
      final pin = '1234';
      final salt = keyDerivation.generateSalt();
      final key1 = keyDerivation.deriveKey(pin, salt);
      final key2 = keyDerivation.deriveKey(pin, salt);

      expect(key1, equals(key2));
    });

    test('不同 PIN 应生成不同密钥', () {
      final salt = keyDerivation.generateSalt();
      final key1 = keyDerivation.deriveKey('1234', salt);
      final key2 = keyDerivation.deriveKey('5678', salt);

      expect(key1, isNot(equals(key2)));
    });

    test('不同 salt 应生成不同密钥', () {
      final pin = '1234';
      final salt1 = keyDerivation.generateSalt();
      final salt2 = keyDerivation.generateSalt();
      final key1 = keyDerivation.deriveKey(pin, salt1);
      final key2 = keyDerivation.deriveKey(pin, salt2);

      expect(key1, isNot(equals(key2)));
    });

    test('派生密钥长度应为 32 字节', () {
      final key = keyDerivation.deriveKey('1234', keyDerivation.generateSalt());
      expect(key.length, equals(32));
    });

    test('salt 长度应为 32 字节', () {
      final salt = keyDerivation.generateSalt();
      expect(salt.length, equals(32));
    });
  });

  group('PIN 哈希验证', () {
    test('正确 PIN 应验证通过', () {
      final pin = '123456';
      final salt = keyDerivation.generateSalt();
      final hash = keyDerivation.hashPin(pin, salt);

      expect(keyDerivation.verifyPin(pin, salt, hash), isTrue);
    });

    test('错误 PIN 应验证失败', () {
      final salt = keyDerivation.generateSalt();
      final hash = keyDerivation.hashPin('1234', salt);

      expect(keyDerivation.verifyPin('5678', salt, hash), isFalse);
    });

    test('PIN 哈希应为固定长度', () {
      final hash = keyDerivation.hashPin('1234', keyDerivation.generateSalt());
      expect(hash.length, equals(32));
    });

    test('PIN 哈希使用不同 salt 应不同', () {
      final pin = '1234';
      final hash1 = keyDerivation.hashPin(pin, keyDerivation.generateSalt());
      final hash2 = keyDerivation.hashPin(pin, keyDerivation.generateSalt());

      expect(hash1, isNot(equals(hash2)));
    });
  });
}

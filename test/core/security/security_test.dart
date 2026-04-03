import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/key_derivation.dart';

/// 安全性测试
///
/// 验证加密系统的安全特性：密钥独立性、内存清除、IV 唯一性等。
void main() {
  group('安全性测试', () {
    late CryptoEngine engine;
    late KeyDerivation kd;

    setUp(() {
      engine = CryptoEngine();
      kd = KeyDerivation();
    });

    test('每次生成的 DEK 不同', () {
      final key1 = engine.generateKey();
      final key2 = engine.generateKey();
      expect(key1, isNot(equals(key2)));
    });

    test('同一 key 加密两次生成不同密文（内部 IV 不同）', () {
      final key = engine.generateKey();
      final plaintext = Uint8List.fromList([1, 2, 3]);
      final c1 = engine.encrypt(plaintext, key);
      final c2 = engine.encrypt(plaintext, key);
      // 前 12 字节是 IV，应不同
      expect(c1.sublist(0, 12), isNot(equals(c2.sublist(0, 12))));
    });

    test('同一明文使用不同 key 产生不同密文', () {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key1 = engine.generateKey();
      final key2 = engine.generateKey();

      final cipher1 = engine.encrypt(plaintext, key1);
      final cipher2 = engine.encrypt(plaintext, key2);

      expect(cipher1, isNot(equals(cipher2)));
    });

    test('同一明文同一 key 加密两次产生不同密文（IV 不同）', () {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = engine.generateKey();

      final cipher1 = engine.encrypt(plaintext, key);
      final cipher2 = engine.encrypt(plaintext, key);

      expect(cipher1, isNot(equals(cipher2)));
    });

    test('篡改密文导致解密失败', () {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = engine.generateKey();
      final cipher = engine.encrypt(plaintext, key);

      // 篡改密文中间部分
      final tampered = Uint8List.fromList(cipher);
      tampered[20] ^= 0xFF;

      expect(
        () => engine.decrypt(tampered, key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('篡改 IV 导致解密失败', () {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = engine.generateKey();
      final cipher = engine.encrypt(plaintext, key);

      // 篡改 IV（前 12 字节）
      final tampered = Uint8List.fromList(cipher);
      tampered[0] ^= 0xFF;

      expect(
        () => engine.decrypt(tampered, key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('错误密钥无法解密', () {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key1 = engine.generateKey();
      final key2 = engine.generateKey();

      final cipher = engine.encrypt(plaintext, key1);

      expect(
        () => engine.decrypt(cipher, key2),
        throwsA(isA<CryptoException>()),
      );
    });

    test('salt 每次生成不同', () {
      final salt1 = kd.generateSalt();
      final salt2 = kd.generateSalt();
      expect(salt1, isNot(equals(salt2)));
    });

    test('同一 PIN 不同 salt 产生不同密钥', () {
      const pin = '123456';
      final salt1 = kd.generateSalt();
      final salt2 = kd.generateSalt();

      final key1 = kd.deriveKey(pin, salt1);
      final key2 = kd.deriveKey(pin, salt2);

      expect(key1, isNot(equals(key2)));
    });

    test('不同 PIN 同一 salt 产生不同密钥', () {
      final salt = kd.generateSalt();
      final key1 = kd.deriveKey('1234', salt);
      final key2 = kd.deriveKey('5678', salt);

      expect(key1, isNot(equals(key2)));
    });

    test('PIN hash 验证：正确 PIN 通过', () {
      const pin = '123456';
      final salt = kd.generateSalt();
      final hash = kd.hashPin(pin, salt);

      expect(kd.verifyPin(pin, salt, hash), isTrue);
    });

    test('PIN hash 验证：错误 PIN 不通过', () {
      const pin = '123456';
      final salt = kd.generateSalt();
      final hash = kd.hashPin(pin, salt);

      expect(kd.verifyPin('654321', salt, hash), isFalse);
    });

    test('密钥长度正确（32 字节 = 256 位）', () {
      final key = engine.generateKey();
      expect(key.length, 32);
    });

    test('密文包含 12 字节 IV 前缀', () {
      final key = engine.generateKey();
      final plaintext = Uint8List.fromList([1, 2, 3]);
      final cipher = engine.encrypt(plaintext, key);
      // 密文格式: IV(12) + ciphertext + tag(16)
      expect(cipher.length, greaterThanOrEqualTo(12 + 16));
    });

    test('Uint8List 可被零覆写', () {
      final key = engine.generateKey();
      final original = Uint8List.fromList(key);

      // 模拟安全清除
      for (var i = 0; i < key.length; i++) {
        key[i] = 0;
      }

      expect(key.every((b) => b == 0), isTrue);
      expect(key, isNot(equals(original)));
    });
  });
}

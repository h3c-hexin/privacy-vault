import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';

void main() {
  late CryptoEngine engine;

  setUp(() {
    engine = CryptoEngine();
  });

  group('AES-256-GCM 加密/解密', () {
    test('基本加密解密：明文应完整还原', () {
      final key = engine.generateKey();
      final plaintext = utf8.encode('Hello, 隐私保险箱!');
      final encrypted = engine.encrypt(Uint8List.fromList(plaintext), key);
      final decrypted = engine.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('空数据加密解密', () {
      final key = engine.generateKey();
      final plaintext = Uint8List(0);
      final encrypted = engine.encrypt(plaintext, key);
      final decrypted = engine.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('大数据加密解密（1MB）', () {
      final key = engine.generateKey();
      final plaintext = Uint8List(1024 * 1024); // 1MB 全零
      for (var i = 0; i < plaintext.length; i++) {
        plaintext[i] = i % 256;
      }
      final encrypted = engine.encrypt(plaintext, key);
      final decrypted = engine.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('密文应包含 IV 和 Auth Tag', () {
      final key = engine.generateKey();
      final plaintext = utf8.encode('test');
      final encrypted = engine.encrypt(Uint8List.fromList(plaintext), key);

      // 密文长度 = IV(12) + ciphertext(>=plaintext长度) + tag(16)
      expect(encrypted.length, greaterThanOrEqualTo(12 + plaintext.length + 16));
    });

    test('相同明文每次加密结果不同（因为随机 IV）', () {
      final key = engine.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('same data'));
      final encrypted1 = engine.encrypt(plaintext, key);
      final encrypted2 = engine.encrypt(plaintext, key);

      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('错误密钥无法解密', () {
      final key1 = engine.generateKey();
      final key2 = engine.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('secret'));
      final encrypted = engine.encrypt(plaintext, key1);

      expect(
        () => engine.decrypt(encrypted, key2),
        throwsA(isA<CryptoException>()),
      );
    });

    test('篡改密文应导致解密失败', () {
      final key = engine.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('integrity test'));
      final encrypted = engine.encrypt(plaintext, key);

      // 篡改密文中间的一个字节
      final tampered = Uint8List.fromList(encrypted);
      tampered[20] = tampered[20] ^ 0xFF;

      expect(
        () => engine.decrypt(tampered, key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('密文过短应抛出异常', () {
      final key = engine.generateKey();
      final tooShort = Uint8List(10); // 小于 IV(12) + Tag(16)

      expect(
        () => engine.decrypt(tooShort, key),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('密钥生成', () {
    test('生成的密钥长度应为 32 字节（256 位）', () {
      final key = engine.generateKey();
      expect(key.length, equals(32));
    });

    test('每次生成的密钥应不同', () {
      final key1 = engine.generateKey();
      final key2 = engine.generateKey();
      expect(key1, isNot(equals(key2)));
    });
  });

  group('IV 生成', () {
    test('生成的 IV 长度应为 12 字节（96 位）', () {
      final iv = engine.generateIV();
      expect(iv.length, equals(12));
    });
  });
}

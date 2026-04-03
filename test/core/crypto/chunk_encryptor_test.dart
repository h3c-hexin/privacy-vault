import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/chunk_encryptor.dart';

void main() {
  late CryptoEngine engine;
  late ChunkEncryptor chunkEncryptor;

  setUp(() {
    engine = CryptoEngine();
    chunkEncryptor = ChunkEncryptor(engine: engine);
  });

  group('分块加密/解密', () {
    test('小文件（< 1 chunk）加密解密', () {
      final key = engine.generateKey();
      final plaintext = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);
      final decrypted = chunkEncryptor.decryptChunks(chunks, key);

      expect(decrypted, equals(plaintext));
    });

    test('恰好 1 chunk 大小的文件', () {
      final key = engine.generateKey();
      final plaintext = Uint8List(ChunkEncryptor.defaultChunkSize);
      for (var i = 0; i < plaintext.length; i++) {
        plaintext[i] = i % 256;
      }
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);
      final decrypted = chunkEncryptor.decryptChunks(chunks, key);

      expect(decrypted, equals(plaintext));
      expect(chunks.length, equals(1));
    });

    test('跨多个 chunk 的文件', () {
      final key = engine.generateKey();
      final size = ChunkEncryptor.defaultChunkSize * 2 + 500;
      final plaintext = Uint8List(size);
      for (var i = 0; i < plaintext.length; i++) {
        plaintext[i] = i % 256;
      }
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);
      final decrypted = chunkEncryptor.decryptChunks(chunks, key);

      expect(decrypted, equals(plaintext));
      expect(chunks.length, equals(3));
    });

    test('空数据', () {
      final key = engine.generateKey();
      final plaintext = Uint8List(0);
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);
      final decrypted = chunkEncryptor.decryptChunks(chunks, key);

      expect(decrypted, equals(plaintext));
    });

    test('每个 chunk 独立加密（不同 IV）', () {
      final key = engine.generateKey();
      final size = ChunkEncryptor.defaultChunkSize * 2;
      final plaintext = Uint8List(size); // 全零
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);

      // 两个 chunk 的密文不应相同（因为随机 IV）
      expect(chunks[0], isNot(equals(chunks[1])));
    });

    test('单个 chunk 被篡改应导致该 chunk 解密失败', () {
      final key = engine.generateKey();
      final size = ChunkEncryptor.defaultChunkSize * 2;
      final plaintext = Uint8List(size);
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);

      // 篡改第一个 chunk
      chunks[0][20] = chunks[0][20] ^ 0xFF;

      expect(
        () => chunkEncryptor.decryptChunks(chunks, key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('单个 chunk 可独立解密', () {
      final key = engine.generateKey();
      final size = ChunkEncryptor.defaultChunkSize * 3;
      final plaintext = Uint8List(size);
      for (var i = 0; i < plaintext.length; i++) {
        plaintext[i] = i % 256;
      }
      final chunks = chunkEncryptor.encryptChunks(plaintext, key);

      // 解密第二个 chunk
      final chunkPlaintext = engine.decrypt(chunks[1], key);
      final expectedStart = ChunkEncryptor.defaultChunkSize;
      final expectedEnd = ChunkEncryptor.defaultChunkSize * 2;
      final expected = plaintext.sublist(expectedStart, expectedEnd);

      expect(chunkPlaintext, equals(expected));
    });
  });
}

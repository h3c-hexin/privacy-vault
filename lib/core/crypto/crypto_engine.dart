import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// 加密操作异常
class CryptoException implements Exception {
  final String message;
  const CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}

/// AES-256-GCM 加密引擎
///
/// 密文格式: [IV (12 bytes)] [Ciphertext] [GCM Auth Tag (16 bytes)]
class CryptoEngine {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 12; // 96 bits (GCM 推荐)
  static const int _tagLength = 16; // 128 bits
  static const int _minCiphertextLength = _ivLength + _tagLength;

  final SecureRandom _secureRandom;

  CryptoEngine() : _secureRandom = _createSecureRandom();

  /// 生成 256 位随机密钥
  Uint8List generateKey() => _secureRandom.nextBytes(_keyLength);

  /// 生成 96 位随机 IV
  Uint8List generateIV() => _secureRandom.nextBytes(_ivLength);

  /// AES-256-GCM 加密
  ///
  /// [aad] 附加认证数据，绑定密文与上下文（如文件 ID、块序号），防止密文移植攻击。
  /// 返回: [IV (12B)] [Ciphertext] [Auth Tag (16B)]
  Uint8List encrypt(Uint8List plaintext, Uint8List key, {Uint8List? aad}) {
    _validateKey(key);
    final iv = generateIV();

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // forEncryption
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8, // tag length in bits
          iv,
          aad ?? Uint8List(0),
        ),
      );

    // GCM 输出 = ciphertext + tag
    final outputLength = cipher.getOutputSize(plaintext.length);
    final output = Uint8List(outputLength);
    var offset = cipher.processBytes(plaintext, 0, plaintext.length, output, 0);
    offset += cipher.doFinal(output, offset);

    // 组装: IV + ciphertext + tag
    final result = Uint8List(_ivLength + offset);
    result.setAll(0, iv);
    result.setRange(_ivLength, _ivLength + offset, output);

    return result;
  }

  /// AES-256-GCM 解密
  ///
  /// [aad] 必须与加密时使用的相同，否则 GCM tag 验证失败。
  /// 输入格式: [IV (12B)] [Ciphertext] [Auth Tag (16B)]
  Uint8List decrypt(Uint8List ciphertext, Uint8List key, {Uint8List? aad}) {
    _validateKey(key);

    if (ciphertext.length < _minCiphertextLength) {
      throw const CryptoException('密文数据过短，无法解密');
    }

    // 拆分 IV 和 密文+Tag
    final iv = ciphertext.sublist(0, _ivLength);
    final encryptedWithTag = ciphertext.sublist(_ivLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // forDecryption
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8,
          iv,
          aad ?? Uint8List(0),
        ),
      );

    try {
      final outputLength = cipher.getOutputSize(encryptedWithTag.length);
      final output = Uint8List(outputLength);
      var offset = cipher.processBytes(
        encryptedWithTag, 0, encryptedWithTag.length, output, 0,
      );
      offset += cipher.doFinal(output, offset);
      // 返回独立拷贝，确保跨 Isolate 传递安全（view 可能丢失 buffer 引用）
      return output.sublist(0, offset);
    } on InvalidCipherTextException {
      throw const CryptoException('解密失败：密钥错误或数据已被篡改');
    }
  }

  void _validateKey(Uint8List key) {
    if (key.length != _keyLength) {
      throw CryptoException('密钥长度必须为 $_keyLength 字节，实际: ${key.length}');
    }
  }

  static SecureRandom _createSecureRandom() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    // 使用 Dart 内置安全随机源作为种子
    final dartRandom = math.Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = dartRandom.nextInt(256);
    }
    random.seed(KeyParameter(seed));
    return random;
  }
}

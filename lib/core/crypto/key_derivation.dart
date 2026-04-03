import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart';

/// 密钥派生服务
///
/// 使用 PBKDF2-HMAC-SHA256 从 PIN 派生加密密钥和验证哈希。
/// 后续可升级为 Argon2id（需要 FFI 支持）。
class KeyDerivation {
  static const int _saltLength = 32;
  static const int _keyLength = 32; // 256 bits

  /// 版本化迭代次数
  /// 移动端 PBKDF2 性能远低于服务器，600K 在中端设备需 10+ 秒，不可用。
  /// 保持 100K（移动端约 1-2 秒），通过 6 位 PIN 最低长度补偿搜索空间。
  static const int iterationsV1 = 100000;
  static const int iterationsV2 = 100000; // 移动端实测后回退，与 v1 一致
  static const int currentIterations = iterationsV1;

  /// 从 PIN 派生 256 位密钥（用于 master key）
  ///
  /// [iterations] 允许指定迭代次数，用于兼容旧版本密钥。
  Uint8List deriveKey(String pin, Uint8List salt, {int? iterations}) {
    final iter = iterations ?? currentIterations;
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iter, _keyLength));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(pin)));
  }

  /// 生成 PIN 验证哈希
  Uint8List hashPin(String pin, Uint8List salt, {int? iterations}) {
    return deriveKey(pin, salt, iterations: iterations);
  }

  /// 验证 PIN 是否匹配
  bool verifyPin(String pin, Uint8List salt, Uint8List expectedHash, {int? iterations}) {
    final candidateHash = hashPin(pin, salt, iterations: iterations);
    return _constantTimeEquals(candidateHash, expectedHash);
  }

  /// 生成随机 salt
  Uint8List generateSalt() {
    final random = math.Random.secure();
    final salt = Uint8List(_saltLength);
    for (var i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// 常量时间比较，防止计时攻击
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

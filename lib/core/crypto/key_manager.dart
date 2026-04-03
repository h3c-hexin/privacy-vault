import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_engine.dart';
import 'key_derivation.dart';
import 'keystore_service.dart';

/// KEK/DEK 密钥管理器
///
/// 密钥层级:
/// PIN → PBKDF2 → MasterKey → 加密 KEK（由 Keystore 保护）
/// KEK → 加密/解密每个文件的 DEK
class KeyManager {
  final CryptoEngine _cryptoEngine;
  final KeyDerivation _keyDerivation;
  final KeystoreService _keystoreService;
  final FlutterSecureStorage _secureStorage;

  /// 内存中的 KEK（仅在会话期间存在）
  Uint8List? _kek;

  /// KEK 是否已解锁
  bool get isUnlocked => _kek != null;

  // SecureStorage keys
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';
  static const _masterSaltKey = 'master_salt';
  static const _encryptedKekKey = 'encrypted_kek';
  static const _keystoreEncryptedKekKey = 'keystore_encrypted_kek';
  static const _keystoreKekIvKey = 'keystore_kek_iv';

  KeyManager({
    required CryptoEngine cryptoEngine,
    required KeyDerivation keyDerivation,
    required KeystoreService keystoreService,
    FlutterSecureStorage? secureStorage,
  })  : _cryptoEngine = cryptoEngine,
        _keyDerivation = keyDerivation,
        _keystoreService = keystoreService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 首次设置：创建 PIN 并初始化密钥体系
  Future<void> setup(String pin) async {
    // 1. 生成 salt
    final pinSalt = _keyDerivation.generateSalt();
    final masterSalt = _keyDerivation.generateSalt();

    // 2. 生成 PIN 验证哈希
    final pinHash = _keyDerivation.hashPin(pin, pinSalt);

    // 3. 派生 master key
    final masterKey = _keyDerivation.deriveKey(pin, masterSalt);

    // 4. 生成 KEK
    final kek = _cryptoEngine.generateKey();

    // 5. 用 master key 加密 KEK
    final encryptedKek = _cryptoEngine.encrypt(kek, masterKey);

    // 6. 初始化 Keystore 并额外保护 KEK
    await _keystoreService.generateKey();
    final keystoreResult = await _keystoreService.encrypt(kek);

    // 7. 持久化存储（含 KDF 版本号）
    await Future.wait([
      _secureStorage.write(key: _pinHashKey, value: base64Encode(pinHash)),
      _secureStorage.write(key: _pinSaltKey, value: base64Encode(pinSalt)),
      _secureStorage.write(key: _masterSaltKey, value: base64Encode(masterSalt)),
      _secureStorage.write(key: _encryptedKekKey, value: base64Encode(encryptedKek)),
      _secureStorage.write(
        key: _keystoreEncryptedKekKey,
        value: base64Encode(keystoreResult.ciphertext),
      ),
      _secureStorage.write(
        key: _keystoreKekIvKey,
        value: base64Encode(keystoreResult.iv),
      ),
    ]);

    // 8. KEK 存入内存
    _kek = kek;
  }

  /// 使用 PIN 解锁
  ///
  /// PBKDF2 密钥派生在后台 Isolate 执行，不阻塞 UI 线程。
  Future<bool> unlockWithPin(String pin) async {
    // 1. 并发读取存储数据（只需 masterSalt 和 encryptedKek）
    final reads = await Future.wait([
      _secureStorage.read(key: _masterSaltKey),
      _secureStorage.read(key: _encryptedKekKey),
    ]);
    final masterSaltStr = reads[0];
    final encryptedKekStr = reads[1];

    if (masterSaltStr == null || encryptedKekStr == null) {
      return false;
    }

    final masterSalt = Uint8List.fromList(base64Decode(masterSaltStr));
    final encryptedKek = Uint8List.fromList(base64Decode(encryptedKekStr));

    // 2. 单次 PBKDF2 派生 master key（跳过 verifyPin，由 GCM tag 验证正确性）
    final masterKey = await Isolate.run(() {
      final kd = KeyDerivation();
      return kd.deriveKey(pin, masterSalt);
    });

    // 3. 用 master key 解密 KEK（GCM tag 验证：错误 PIN → 解密失败）
    try {
      _kek = _cryptoEngine.decrypt(encryptedKek, masterKey);
      return true;
    } on CryptoException {
      return false;
    }
  }

  /// 写入认证材料到 SecureStorage（供 changePin 复用）
  Future<void> _writeAuthMaterial({
    required Uint8List pinHash,
    required Uint8List pinSalt,
    required Uint8List masterSalt,
    required Uint8List encryptedKek,
  }) async {
    await _secureStorage.write(key: _encryptedKekKey, value: base64Encode(encryptedKek));
    await _secureStorage.write(key: _pinHashKey, value: base64Encode(pinHash));
    await _secureStorage.write(key: _pinSaltKey, value: base64Encode(pinSalt));
    await _secureStorage.write(key: _masterSaltKey, value: base64Encode(masterSalt));
  }

  /// 修改 PIN
  ///
  /// 崩溃安全策略：备份旧认证材料 → 写入新材料 → 成功后删除备份。
  Future<void> changePin(String oldPin, String newPin) async {
    if (_kek == null) {
      throw const KeyManagerException('必须先解锁才能修改 PIN');
    }

    final kek = _kek!;
    final newPinSalt = _keyDerivation.generateSalt();
    final newMasterSalt = _keyDerivation.generateSalt();

    // PBKDF2 在 Isolate 中执行，避免主线程卡顿
    final derived = await Isolate.run(() {
      final kd = KeyDerivation();
      return (
        pinHash: kd.hashPin(newPin, newPinSalt),
        masterKey: kd.deriveKey(newPin, newMasterSalt),
      );
    });
    final newEncryptedKek = _cryptoEngine.encrypt(kek, derived.masterKey);

    final keystoreResult = await _keystoreService.encrypt(kek);

    // 1. 并发备份旧认证材料
    final oldValues = await Future.wait([
      _secureStorage.read(key: _pinHashKey),
      _secureStorage.read(key: _pinSaltKey),
      _secureStorage.read(key: _masterSaltKey),
      _secureStorage.read(key: _encryptedKekKey),
    ]);
    await Future.wait([
      _secureStorage.write(key: '${_pinHashKey}_bak', value: oldValues[0] ?? ''),
      _secureStorage.write(key: '${_pinSaltKey}_bak', value: oldValues[1] ?? ''),
      _secureStorage.write(key: '${_masterSaltKey}_bak', value: oldValues[2] ?? ''),
      _secureStorage.write(key: '${_encryptedKekKey}_bak', value: oldValues[3] ?? ''),
    ]);

    // 2. 写入新材料
    await _writeAuthMaterial(
      pinHash: derived.pinHash,
      pinSalt: newPinSalt,
      masterSalt: newMasterSalt,
      encryptedKek: newEncryptedKek,
    );
    await _secureStorage.write(
      key: _keystoreEncryptedKekKey,
      value: base64Encode(keystoreResult.ciphertext),
    );
    await _secureStorage.write(
      key: _keystoreKekIvKey,
      value: base64Encode(keystoreResult.iv),
    );

    // 3. 成功后删除备份
    await _secureStorage.delete(key: '${_pinHashKey}_bak');
    await _secureStorage.delete(key: '${_pinSaltKey}_bak');
    await _secureStorage.delete(key: '${_masterSaltKey}_bak');
    await _secureStorage.delete(key: '${_encryptedKekKey}_bak');
  }

  /// 加密文件的 DEK
  Uint8List encryptDek(Uint8List dek) {
    if (_kek == null) throw const KeyManagerException('KEK 未解锁');
    return _cryptoEngine.encrypt(dek, _kek!);
  }

  /// 解密文件的 DEK
  Uint8List decryptDek(Uint8List encryptedDek) {
    if (_kek == null) throw const KeyManagerException('KEK 未解锁');
    return _cryptoEngine.decrypt(encryptedDek, _kek!);
  }

  /// 生成新的文件 DEK
  Uint8List generateDek() => _cryptoEngine.generateKey();

  /// 锁定（清除内存中的 KEK）
  void lock() {
    if (_kek != null) {
      // 覆写内存中的密钥
      for (var i = 0; i < _kek!.length; i++) {
        _kek![i] = 0;
      }
      _kek = null;
    }
  }

  /// 检查是否已完成首次设置
  Future<bool> isSetupComplete() async {
    final pinHash = await _secureStorage.read(key: _pinHashKey);
    return pinHash != null;
  }

  /// 紧急销毁：删除所有密钥材料
  Future<void> emergencyDestroy() async {
    lock();
    await _keystoreService.deleteKey();
    await _secureStorage.deleteAll();
  }
}

/// 密钥管理异常
class KeyManagerException implements Exception {
  final String message;
  const KeyManagerException(this.message);

  @override
  String toString() => 'KeyManagerException: $message';
}

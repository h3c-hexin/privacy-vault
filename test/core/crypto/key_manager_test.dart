import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/key_derivation.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/crypto/keystore_service.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

/// Mock KeystoreService：避免调用 Android MethodChannel
class MockKeystoreService extends Mock implements KeystoreService {}

/// Mock FlutterSecureStorage：使用内存 Map 模拟持久化存储，
/// 同时绑定一个外部 Map，让测试可以直接预填 / 检查存储内容。
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String?> _store;

  FakeSecureStorage(this._store);

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }
}

// ─── Storage key 常量（与 KeyManager 内部一致）────────────────────────────────

const _pinHashKey = 'pin_hash';
const _pinSaltKey = 'pin_salt';
const _masterSaltKey = 'master_salt';
const _encryptedKekKey = 'encrypted_kek';
const _keystoreEncryptedKekKey = 'keystore_encrypted_kek';
const _keystoreKekIvKey = 'keystore_kek_iv';

// ─── 辅助：构建 KeystoreService 的固定加密结果 ────────────────────────────────

/// 返回一个固定的 Keystore 加密结果（用于 Mock stub）
({Uint8List ciphertext, Uint8List iv}) _fakeKeystoreResult() {
  return (
    ciphertext: Uint8List(32), // 全零占位符
    iv: Uint8List(12), // 全零占位符
  );
}

// ─── 主测试入口 ───────────────────────────────────────────────────────────────

void main() {
  // 真实实例（无副作用，可直接使用）
  late CryptoEngine cryptoEngine;
  late KeyDerivation keyDerivation;

  // Mock / Fake 实例
  late MockKeystoreService mockKeystoreService;
  late Map<String, String?> storageMap;
  late FakeSecureStorage fakeStorage;

  // 被测对象
  late KeyManager keyManager;

  /// 重置所有依赖，每个测试前调用
  void resetAll() {
    cryptoEngine = CryptoEngine();
    keyDerivation = KeyDerivation();
    mockKeystoreService = MockKeystoreService();
    storageMap = {};
    fakeStorage = FakeSecureStorage(storageMap);

    // 注册 mocktail 兜底（防止未 stub 的方法调用报错）
    registerFallbackValue(Uint8List(0));

    // 默认 stub：KeystoreService.generateKey / encrypt / deleteKey
    when(() => mockKeystoreService.generateKey())
        .thenAnswer((_) async {});
    when(() => mockKeystoreService.encrypt(any()))
        .thenAnswer((_) async => _fakeKeystoreResult());
    when(() => mockKeystoreService.deleteKey())
        .thenAnswer((_) async {});

    keyManager = KeyManager(
      cryptoEngine: cryptoEngine,
      keyDerivation: keyDerivation,
      keystoreService: mockKeystoreService,
      secureStorage: fakeStorage,
    );
  }

  // ─── 1. setup() ─────────────────────────────────────────────────────────────

  group('setup()', () {
    setUp(resetAll);

    test('设置 PIN 后 isUnlocked 应为 true', () async {
      // setup() 会执行一次 PBKDF2（deriveKey + hashPin），迭代次数为 600000，
      // 在 CI/测试机上约需 1–2 秒，属于预期行为。
      await keyManager.setup('1234');

      expect(keyManager.isUnlocked, isTrue);
    });

    test('setup() 后 isSetupComplete() 应返回 true', () async {
      await keyManager.setup('1234');

      expect(await keyManager.isSetupComplete(), isTrue);
    });

    test('setup() 应将必要字段写入存储', () async {
      await keyManager.setup('1234');

      expect(storageMap.containsKey(_pinHashKey), isTrue);
      expect(storageMap.containsKey(_pinSaltKey), isTrue);
      expect(storageMap.containsKey(_masterSaltKey), isTrue);
      expect(storageMap.containsKey(_encryptedKekKey), isTrue);
    });

    test('setup() 应调用 KeystoreService.generateKey 和 encrypt', () async {
      await keyManager.setup('1234');

      verify(() => mockKeystoreService.generateKey()).called(1);
      verify(() => mockKeystoreService.encrypt(any())).called(1);
    });
  });

  // ─── 2. unlockWithPin() ──────────────────────────────────────────────────────

  group('unlockWithPin()', () {
    setUp(resetAll);

    test('正确 PIN 解锁成功，isUnlocked 变为 true', () async {
      // 先通过 setup() 完整初始化（写入真实 PBKDF2 结果到 fakeStorage）
      await keyManager.setup('1234');
      // 锁定后再用正确 PIN 解锁
      keyManager.lock();
      expect(keyManager.isUnlocked, isFalse);

      final result = await keyManager.unlockWithPin('1234');

      expect(result, isTrue);
      expect(keyManager.isUnlocked, isTrue);
    });

    test('错误 PIN 解锁失败，isUnlocked 保持 false', () async {
      await keyManager.setup('1234');
      keyManager.lock();

      final result = await keyManager.unlockWithPin('9999');

      expect(result, isFalse);
      expect(keyManager.isUnlocked, isFalse);
    });

    test('存储中无数据时 unlockWithPin 返回 false', () async {
      // 未调用 setup()，存储为空
      final result = await keyManager.unlockWithPin('1234');

      expect(result, isFalse);
    });
  });

  // ─── 3. lock() ───────────────────────────────────────────────────────────────

  group('lock()', () {
    setUp(resetAll);

    test('lock() 后 isUnlocked 应为 false', () async {
      await keyManager.setup('1234');
      expect(keyManager.isUnlocked, isTrue); // 前置条件

      keyManager.lock();

      expect(keyManager.isUnlocked, isFalse);
    });

    test('重复调用 lock() 不应抛出异常', () async {
      await keyManager.setup('1234');
      keyManager.lock();

      expect(() => keyManager.lock(), returnsNormally);
    });

    test('未解锁时调用 lock() 不应抛出异常', () {
      // keyManager 尚未 setup，直接调用 lock()
      expect(() => keyManager.lock(), returnsNormally);
    });
  });

  // ─── 4. encryptDek / decryptDek ─────────────────────────────────────────────

  group('encryptDek / decryptDek', () {
    setUp(resetAll);

    test('加密再解密 DEK 应完整还原原始数据', () async {
      await keyManager.setup('1234');
      final dek = cryptoEngine.generateKey(); // 随机 32 字节 DEK

      final encryptedDek = keyManager.encryptDek(dek);
      final decryptedDek = keyManager.decryptDek(encryptedDek);

      expect(decryptedDek, equals(dek));
    });

    test('对同一 DEK 多次加密结果应不同（随机 IV）', () async {
      await keyManager.setup('1234');
      final dek = cryptoEngine.generateKey();

      final enc1 = keyManager.encryptDek(dek);
      final enc2 = keyManager.encryptDek(dek);

      expect(enc1, isNot(equals(enc2)));
    });

    test('lock() 后调用 encryptDek 应抛出 KeyManagerException', () async {
      await keyManager.setup('1234');
      keyManager.lock();

      expect(
        () => keyManager.encryptDek(cryptoEngine.generateKey()),
        throwsA(isA<KeyManagerException>()),
      );
    });

    test('lock() 后调用 decryptDek 应抛出 KeyManagerException', () async {
      await keyManager.setup('1234');
      // 在锁定前先加密一个 DEK
      final dek = cryptoEngine.generateKey();
      final encryptedDek = keyManager.encryptDek(dek);
      keyManager.lock();

      expect(
        () => keyManager.decryptDek(encryptedDek),
        throwsA(isA<KeyManagerException>()),
      );
    });
  });

  // ─── 5. changePin() ──────────────────────────────────────────────────────────

  group('changePin()', () {
    setUp(resetAll);

    test('修改 PIN 后用新 PIN 可解锁', () async {
      await keyManager.setup('1234');
      // changePin() 需要 KEK 已在内存中（即 isUnlocked 为 true）
      await keyManager.changePin('1234', '5678');

      // 锁定后用新 PIN 解锁
      keyManager.lock();
      final result = await keyManager.unlockWithPin('5678');

      expect(result, isTrue);
      expect(keyManager.isUnlocked, isTrue);
    });

    test('修改 PIN 后旧 PIN 应无法解锁', () async {
      await keyManager.setup('1234');
      await keyManager.changePin('1234', '5678');

      keyManager.lock();
      final result = await keyManager.unlockWithPin('1234');

      expect(result, isFalse);
    });

    test('未解锁时调用 changePin 应抛出 KeyManagerException', () async {
      // keyManager 未 setup，KEK 为 null
      await expectLater(
        keyManager.changePin('1234', '5678'),
        throwsA(isA<KeyManagerException>()),
      );
    });

    test('changePin() 应更新 Keystore 侧的 KEK 副本', () async {
      await keyManager.setup('1234');
      // 重置调用记录（setup 已经调用了一次 encrypt）
      clearInteractions(mockKeystoreService);

      await keyManager.changePin('1234', '5678');

      // changePin 应再次调用 encrypt 更新 Keystore 侧副本
      verify(() => mockKeystoreService.encrypt(any())).called(1);
    });
  });

  // ─── 6. generateDek() ────────────────────────────────────────────────────────

  group('generateDek()', () {
    setUp(resetAll);

    test('生成的 DEK 长度应为 32 字节', () async {
      await keyManager.setup('1234');
      final dek = keyManager.generateDek();

      expect(dek.length, equals(32));
    });

    test('每次生成的 DEK 应不同', () async {
      await keyManager.setup('1234');
      final dek1 = keyManager.generateDek();
      final dek2 = keyManager.generateDek();

      expect(dek1, isNot(equals(dek2)));
    });
  });

  // ─── 7. isSetupComplete() ────────────────────────────────────────────────────

  group('isSetupComplete()', () {
    setUp(resetAll);

    test('未 setup 时应返回 false', () async {
      expect(await keyManager.isSetupComplete(), isFalse);
    });

    test('setup 后应返回 true', () async {
      await keyManager.setup('1234');

      expect(await keyManager.isSetupComplete(), isTrue);
    });
  });

  // ─── 8. emergencyDestroy() ───────────────────────────────────────────────────

  group('emergencyDestroy()', () {
    setUp(resetAll);

    test('紧急销毁后 isUnlocked 应为 false', () async {
      await keyManager.setup('1234');
      expect(keyManager.isUnlocked, isTrue); // 前置条件

      await keyManager.emergencyDestroy();

      expect(keyManager.isUnlocked, isFalse);
    });

    test('紧急销毁后 isSetupComplete() 应返回 false（存储已清空）', () async {
      await keyManager.setup('1234');
      await keyManager.emergencyDestroy();

      expect(await keyManager.isSetupComplete(), isFalse);
    });

    test('紧急销毁应调用 KeystoreService.deleteKey', () async {
      await keyManager.setup('1234');
      clearInteractions(mockKeystoreService);

      await keyManager.emergencyDestroy();

      verify(() => mockKeystoreService.deleteKey()).called(1);
    });
  });
}

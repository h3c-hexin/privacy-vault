/// 文件完整生命周期集成测试
///
/// 覆盖从文件导入到导出的完整数据流链路：
///   1. 加密存储链路（小文件 + PVLT magic bytes 校验）
///   2. 缩略图加密链路（生成 + 加密存在 + 可解密为有效图片）
///   3. 解密预览链路（decryptToMemory 还原一致性）
///   4. 分块加密链路（大文件 > 10MB + chunk 目录结构 + 解密还原）
///   5. 导出链路（decryptToTemp → 验证 → cleanFile → 验证已删除）
///   6. DEK 生命周期（encryptDek/decryptDek 一致性）
///   7. 向后兼容（旧格式无 PVLT magic，直接解密）
///
/// 技术约束：
///   - 纯 Dart 测试，不涉及 UI
///   - 真实 CryptoEngine、ChunkEncryptor（不 mock 加密层）
///   - 真实文件系统操作（使用 Directory.systemTemp 创建隔离临时目录）
///   - FakeKeyManager：提供固定 KEK，绕过 Android Keystore MethodChannel
///   - path_provider 通过 PathProviderPlatform mock 重定向到临时目录

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/chunk_encryptor.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';
import 'package:privacy_vault/core/storage/temp_file_manager.dart';

// ─── FakeKeyManager：固定 KEK，绕过 Android Keystore ─────────────────────────

/// 测试专用 KeyManager 替代品
///
/// 使用固定 32 字节 KEK，不依赖 Android Keystore / SecureStorage。
/// 仅实现 encryptDek / decryptDek / generateDek 供集成测试使用。
class FakeKeyManager extends Fake implements KeyManager {
  final CryptoEngine _engine;
  final Uint8List _kek;

  /// [kek] 为 null 时使用固定测试 KEK（`0x01..0x20`），
  /// 传入自定义 KEK 可用于测试跨 KeyManager 隔离场景。
  FakeKeyManager(this._engine, {Uint8List? kek})
      : _kek = kek ?? Uint8List.fromList(List.generate(32, (i) => i + 1));

  @override
  bool get isUnlocked => true;

  @override
  Uint8List generateDek() => _engine.generateKey();

  @override
  Uint8List encryptDek(Uint8List dek) => _engine.encrypt(dek, _kek);

  @override
  Uint8List decryptDek(Uint8List encryptedDek) =>
      _engine.decrypt(encryptedDek, _kek);
}

// ─── FakePathProvider：将 path_provider 重定向到临时目录 ──────────────────────

/// 将所有 path_provider 目录请求重定向到指定的临时目录
///
/// 绕过 Flutter 平台通道，使测试可在纯 Dart 环境中运行。
class FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String basePath;

  FakePathProvider(this.basePath);

  @override
  Future<String?> getApplicationDocumentsPath() async => basePath;

  @override
  Future<String?> getTemporaryPath() async => p.join(basePath, 'temp');

  @override
  Future<String?> getApplicationCachePath() async =>
      p.join(basePath, 'cache');

  @override
  Future<String?> getApplicationSupportPath() async =>
      p.join(basePath, 'support');

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      null;

  @override
  Future<String?> getDownloadsPath() async => null;
}

// ─── 辅助工具函数 ─────────────────────────────────────────────────────────────

/// 生成一张 100×100 红色测试 JPEG 图片的字节数据
Uint8List _makeTestJpegBytes({int width = 100, int height = 100}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 0, 0));
  return Uint8List.fromList(img.encodeJpg(image, quality: 80));
}

/// 生成指定大小的随机测试数据（使用规律填充，方便验证）
Uint8List _makeTestData(int size) {
  final data = Uint8List(size);
  for (var i = 0; i < size; i++) {
    data[i] = i % 256;
  }
  return data;
}

// ─── PVLT magic bytes 常量（与 EncryptedFileStorage 保持一致）──────────────
const List<int> _pvltMagic = [0x50, 0x56, 0x4C, 0x54];

/// 检查字节数组是否以 PVLT magic bytes 开头
bool _hasPvltMagic(Uint8List bytes) {
  if (bytes.length < 4) return false;
  return bytes[0] == 0x50 &&
      bytes[1] == 0x56 &&
      bytes[2] == 0x4C &&
      bytes[3] == 0x54;
}

// ─── 主测试入口 ───────────────────────────────────────────────────────────────

void main() {
  late Directory testRootDir;
  late CryptoEngine cryptoEngine;
  late ChunkEncryptor chunkEncryptor;
  late FakeKeyManager fakeKeyManager;
  late EncryptedFileStorage storage;
  late TempFileManager tempFileManager;

  // 每个测试前重建隔离环境
  setUp(() async {
    // 创建独立临时目录，确保测试间互不干扰
    testRootDir = await Directory.systemTemp
        .createTemp('pvlt_integration_test_');

    // 创建必要子目录（path_provider mock 会用到）
    await Directory(p.join(testRootDir.path, 'temp')).create(recursive: true);

    // 注册 path_provider mock，重定向到测试临时目录
    PathProviderPlatform.instance = FakePathProvider(testRootDir.path);

    // 初始化真实加密组件
    cryptoEngine = CryptoEngine();
    chunkEncryptor = ChunkEncryptor(engine: cryptoEngine);
    fakeKeyManager = FakeKeyManager(cryptoEngine);

    // 初始化存储服务（使用真实加密层 + fake KeyManager）
    storage = EncryptedFileStorage(
      cryptoEngine: cryptoEngine,
      chunkEncryptor: chunkEncryptor,
      keyManager: fakeKeyManager,
    );

    tempFileManager = TempFileManager();
  });

  // 每个测试后清理临时目录
  tearDown(() async {
    if (await testRootDir.exists()) {
      await testRootDir.delete(recursive: true);
    }
  });

  // ─── 1. 加密存储链路 ─────────────────────────────────────────────────────────

  group('加密存储链路', () {
    test('小文件加密后：加密文件存在 + 大小合理 + PVLT magic bytes 校验', () async {
      // 准备：创建 1KB 源文件
      final sourceData = _makeTestData(1024);
      final sourceFile = File(p.join(testRootDir.path, 'source.bin'));
      await sourceFile.writeAsBytes(sourceData);

      // 执行：加密并存储
      final result = await storage.encryptAndStore(sourceFile.path, 'file_001');

      // 验证：加密文件存在
      final encryptedFile = File(result.encryptedPath);
      expect(await encryptedFile.exists(), isTrue,
          reason: '加密文件应存在于磁盘');

      // 验证：加密文件大小合理（应大于原始大小，包含 IV + Tag + magic）
      expect(result.encryptedSize, greaterThan(sourceData.length),
          reason: '加密文件应比原始文件大（含 IV/Tag/magic 开销）');

      // 验证：文件头包含 PVLT magic bytes
      final encryptedBytes = await encryptedFile.readAsBytes();
      expect(_hasPvltMagic(encryptedBytes), isTrue,
          reason: '加密文件头部应以 PVLT magic bytes 开头');

      // 验证：原始大小记录正确
      expect(result.originalSize, equals(sourceData.length));

      // 验证：chunkCount 为 1（小文件不分块）
      expect(result.chunkCount, equals(1));
    });

    test('encryptDek 返回 base64 编码的加密 DEK', () async {
      final sourceFile = File(p.join(testRootDir.path, 'source.bin'));
      await sourceFile.writeAsBytes(_makeTestData(512));

      final result = await storage.encryptAndStore(sourceFile.path, 'file_002');

      // 验证：encryptedDek 是合法 base64 字符串
      expect(() => base64Decode(result.encryptedDek), returnsNormally,
          reason: 'encryptedDek 应是合法 base64 字符串');

      // 验证：解码后的加密 DEK 长度合理（AES-GCM 输出 = 32 + 12 IV + 16 Tag = 60 bytes）
      final dekBytes = base64Decode(result.encryptedDek);
      expect(dekBytes.length, greaterThanOrEqualTo(32 + 12 + 16),
          reason: '加密 DEK 应包含 IV 和 Auth Tag');
    });

    test('checksum 对相同内容保持一致', () async {
      final sourceData = _makeTestData(2048);
      final sourceFile1 = File(p.join(testRootDir.path, 'source1.bin'));
      final sourceFile2 = File(p.join(testRootDir.path, 'source2.bin'));
      await sourceFile1.writeAsBytes(sourceData);
      await sourceFile2.writeAsBytes(sourceData);

      final result1 =
          await storage.encryptAndStore(sourceFile1.path, 'file_cs1');
      final result2 =
          await storage.encryptAndStore(sourceFile2.path, 'file_cs2');

      // 相同内容 → 相同 checksum（SHA-256 确定性）
      expect(result1.checksum, equals(result2.checksum),
          reason: '相同内容的校验和应一致');
    });
  });

  // ─── 2. 缩略图链路 ──────────────────────────────────────────────────────────

  group('缩略图链路', () {
    test('图片文件 → ThumbnailService → 加密缩略图存在 + 可解密为有效图片', () async {
      // 准备：创建 JPEG 测试图片
      final jpegBytes = _makeTestJpegBytes(width: 200, height: 150);
      final sourceFile = File(p.join(testRootDir.path, 'photo.jpg'));
      await sourceFile.writeAsBytes(jpegBytes);

      // 先通过 encryptAndStore 获取 DEK
      final encResult =
          await storage.encryptAndStore(sourceFile.path, 'photo_001');
      final dek = encResult.plainDek;

      // 需要确保缩略图目录存在（thumbDir getter 会自动创建）
      final thumbDir = await storage.thumbDir;
      expect(await Directory(thumbDir).exists(), isTrue,
          reason: '缩略图目录应被自动创建');

      // 用 CryptoEngine 直接加密缩略图（模拟 ThumbnailService 行为）
      // 注意：ThumbnailService 在测试中依赖 Flutter Image codec（平台限制），
      // 此处直接测试缩略图的加密/解密链路，使用 image 包离线处理。
      final originalImage = img.decodeImage(jpegBytes)!;
      final thumbnail = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? 300 : null,
        height: originalImage.height >= originalImage.width ? 300 : null,
        interpolation: img.Interpolation.linear,
      );
      final thumbBytes = Uint8List.fromList(img.encodeJpg(thumbnail));

      // 用文件 DEK 加密缩略图并写入 thumbDir
      final encryptedThumb = cryptoEngine.encrypt(thumbBytes, dek);
      final thumbPath = p.join(thumbDir, 'photo_001_thumb.enc');
      await File(thumbPath).writeAsBytes(encryptedThumb);

      // 验证：加密缩略图文件存在
      expect(await File(thumbPath).exists(), isTrue,
          reason: '加密缩略图文件应存在');

      // 验证：加密缩略图大小 > 0
      expect(await File(thumbPath).length(), greaterThan(0),
          reason: '加密缩略图不应为空');

      // 验证：用相同 DEK 解密后为有效 JPEG
      final encryptedData = await File(thumbPath).readAsBytes();
      final decryptedThumb = cryptoEngine.decrypt(encryptedData, dek);
      final decodedImage = img.decodeJpg(decryptedThumb);
      expect(decodedImage, isNotNull,
          reason: '解密后的缩略图应是有效的 JPEG 图片');
      expect(decodedImage!.width, lessThanOrEqualTo(300),
          reason: '缩略图宽度不应超过 300px');
      expect(decodedImage.height, lessThanOrEqualTo(300),
          reason: '缩略图高度不应超过 300px');

      // 清理：零字节覆盖 DEK
      for (var i = 0; i < dek.length; i++) {
        dek[i] = 0;
      }
    });

    test('加密缩略图使用错误 DEK 解密应抛出 CryptoException', () async {
      final jpegBytes = _makeTestJpegBytes();
      final sourceFile = File(p.join(testRootDir.path, 'photo2.jpg'));
      await sourceFile.writeAsBytes(jpegBytes);

      final encResult =
          await storage.encryptAndStore(sourceFile.path, 'photo_002');
      final correctDek = encResult.plainDek;
      final wrongDek = cryptoEngine.generateKey();

      // 用正确 DEK 加密缩略图
      final encryptedThumb = cryptoEngine.encrypt(jpegBytes, correctDek);
      final thumbPath =
          p.join(await storage.thumbDir, 'photo_002_thumb.enc');
      await File(thumbPath).writeAsBytes(encryptedThumb);

      // 用错误 DEK 解密 → 应抛出 CryptoException
      final encryptedData = await File(thumbPath).readAsBytes();
      expect(
        () => cryptoEngine.decrypt(encryptedData, wrongDek),
        throwsA(isA<CryptoException>()),
        reason: '使用错误 DEK 解密缩略图应抛出 CryptoException',
      );
    });
  });

  // ─── 3. 解密预览链路 ─────────────────────────────────────────────────────────

  group('解密预览链路', () {
    test('decryptToMemory：解密数据与原始数据完全一致', () async {
      // 准备：创建 500 字节测试数据
      final originalData = _makeTestData(500);
      final sourceFile = File(p.join(testRootDir.path, 'preview.bin'));
      await sourceFile.writeAsBytes(originalData);

      // 加密存储
      final result =
          await storage.encryptAndStore(sourceFile.path, 'preview_001');

      // 解密到内存
      final decrypted = await storage.decryptToMemory(
        result.encryptedPath,
        result.encryptedDek,
        result.chunkCount,
      );

      // 验证：解密后与原始数据完全一致
      expect(decrypted, equals(originalData),
          reason: 'decryptToMemory 返回的数据应与原始文件内容完全一致');
    });

    test('decryptToMemory：文本文件内容正确还原', () async {
      const originalText = '隐私保险箱集成测试 - Hello, Privacy Vault! 🔐';
      final textBytes = utf8.encode(originalText);
      final sourceFile = File(p.join(testRootDir.path, 'text.txt'));
      await sourceFile.writeAsBytes(textBytes);

      final result =
          await storage.encryptAndStore(sourceFile.path, 'text_001');

      final decrypted = await storage.decryptToMemory(
        result.encryptedPath,
        result.encryptedDek,
        result.chunkCount,
      );

      expect(utf8.decode(decrypted), equals(originalText),
          reason: '文本内容解密后应与原始字符串完全一致');
    });

    test('decryptToMemory：使用错误 DEK 应导致解密失败', () async {
      final sourceFile = File(p.join(testRootDir.path, 'data.bin'));
      await sourceFile.writeAsBytes(_makeTestData(256));

      final result = await storage.encryptAndStore(sourceFile.path, 'err_001');

      // 生成一个假 DEK，用 fakeKeyManager 加密后传入
      final fakeDek = cryptoEngine.generateKey();
      final fakeEncryptedDek =
          base64Encode(fakeKeyManager.encryptDek(fakeDek));

      // decryptToMemory 应抛出异常（GCM tag 校验失败）
      await expectLater(
        storage.decryptToMemory(
          result.encryptedPath,
          fakeEncryptedDek,
          result.chunkCount,
        ),
        throwsA(anything),
        reason: '使用错误 DEK 解密应抛出异常',
      );
    });
  });

  // ─── 4. 分块加密链路 ─────────────────────────────────────────────────────────

  group('分块加密链路（大文件 > 10MB）', () {
    test('大文件加密：生成 chunk 目录 + header.pvlt + chunk 文件', () async {
      // 准备：创建 11MB 测试文件（超过 10MB 阈值）
      const fileSize = 11 * 1024 * 1024; // 11MB
      final bigData = _makeTestData(fileSize);
      final sourceFile = File(p.join(testRootDir.path, 'big.bin'));
      await sourceFile.writeAsBytes(bigData);

      // 执行：加密大文件
      final result =
          await storage.encryptAndStore(sourceFile.path, 'big_001');

      // 验证：encryptedPath 是目录（分块存储）
      expect(await Directory(result.encryptedPath).exists(), isTrue,
          reason: '大文件加密结果应为 chunk 目录');

      // 验证：header.pvlt 存在且含 PVLT magic bytes
      final headerFile = File(p.join(result.encryptedPath, 'header.pvlt'));
      expect(await headerFile.exists(), isTrue,
          reason: 'chunk 目录中应存在 header.pvlt 文件');
      final headerBytes = await headerFile.readAsBytes();
      expect(_hasPvltMagic(headerBytes), isTrue,
          reason: 'header.pvlt 内容应以 PVLT magic bytes 开头');

      // 验证：存在多个 chunk 文件（11MB / 1MB = 11 个 chunk）
      final chunkFiles = await Directory(result.encryptedPath)
          .list()
          .where((e) => e is File && e.path.endsWith('.enc'))
          .toList();
      expect(chunkFiles.length, greaterThan(1),
          reason: '大文件应被分为多个 chunk');

      // 验证：chunkCount > 1
      expect(result.chunkCount, greaterThan(1),
          reason: 'chunkCount 应大于 1');
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('大文件加密解密：解密数据与原始数据完全一致', () async {
      // 准备：使用较小的超阈值文件（10.5MB，节省测试时间）
      const fileSize = 10 * 1024 * 1024 + 512 * 1024; // 10.5MB
      final bigData = _makeTestData(fileSize);
      final sourceFile = File(p.join(testRootDir.path, 'big2.bin'));
      await sourceFile.writeAsBytes(bigData);

      // 加密
      final result =
          await storage.encryptAndStore(sourceFile.path, 'big_002');
      expect(result.chunkCount, greaterThan(1),
          reason: '前置条件：文件应被分块');

      // 解密
      final decrypted = await storage.decryptToMemory(
        result.encryptedPath,
        result.encryptedDek,
        result.chunkCount,
      );

      // 验证：解密结果与原始数据完全一致
      expect(decrypted.length, equals(bigData.length),
          reason: '解密后数据长度应与原始一致');
      expect(decrypted, equals(bigData),
          reason: '解密后数据内容应与原始完全一致');
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  // ─── 5. 导出链路 ──────────────────────────────────────────────────────────────

  group('导出链路', () {
    test('decryptToTemp：临时文件内容正确 → cleanFile → 文件已删除', () async {
      // 准备：创建测试数据
      final originalData = _makeTestData(1024);
      final sourceFile = File(p.join(testRootDir.path, 'export.bin'));
      await sourceFile.writeAsBytes(originalData);

      // 加密存储
      final result =
          await storage.encryptAndStore(sourceFile.path, 'export_001');

      // 导出：解密到临时文件
      final tempPath = await storage.decryptToTemp(
        result.encryptedPath,
        result.encryptedDek,
        result.chunkCount,
        'export.bin',
      );

      // 验证：临时文件存在
      final tempFile = File(tempPath);
      expect(await tempFile.exists(), isTrue,
          reason: '临时文件应存在');

      // 验证：临时文件内容正确
      final tempContent = await tempFile.readAsBytes();
      expect(tempContent, equals(originalData),
          reason: '临时文件内容应与原始数据一致');

      // 验证：清理后文件已删除
      await storage.cleanTempFile(tempPath);
      expect(await tempFile.exists(), isFalse,
          reason: 'cleanTempFile 后临时文件应被删除');
    });

    test('TempFileManager.cleanFile：安全删除后文件不存在', () async {
      // 准备：创建测试临时文件
      final originalData = _makeTestData(256);
      final sourceFile = File(p.join(testRootDir.path, 'clean_test.bin'));
      await sourceFile.writeAsBytes(originalData);

      final encResult =
          await storage.encryptAndStore(sourceFile.path, 'clean_001');

      // 导出到临时文件（使用 decryptToTemp，让文件落在 vault_temp 目录下）
      final tempPath = await storage.decryptToTemp(
        encResult.encryptedPath,
        encResult.encryptedDek,
        encResult.chunkCount,
        'clean_test.bin',
      );

      expect(await File(tempPath).exists(), isTrue,
          reason: '前置条件：临时文件应存在');

      // 使用 TempFileManager.cleanFile 删除
      await tempFileManager.cleanFile(tempPath);

      expect(await File(tempPath).exists(), isFalse,
          reason: 'TempFileManager.cleanFile 后文件应被安全删除');
    });

    test('decryptToTemp：文件扩展名被正确保留', () async {
      final jpegData = _makeTestJpegBytes();
      final sourceFile = File(p.join(testRootDir.path, 'photo.jpg'));
      await sourceFile.writeAsBytes(jpegData);

      final result =
          await storage.encryptAndStore(sourceFile.path, 'photo_export');
      final tempPath = await storage.decryptToTemp(
        result.encryptedPath,
        result.encryptedDek,
        result.chunkCount,
        'photo.jpg', // 原始文件名，用于决定临时文件扩展名
      );

      // 验证：临时文件扩展名为 .jpg
      expect(p.extension(tempPath), equals('.jpg'),
          reason: '临时文件应保留原始扩展名 .jpg');

      // 清理
      await storage.cleanTempFile(tempPath);
    });
  });

  // ─── 6. DEK 生命周期 ─────────────────────────────────────────────────────────

  group('DEK 生命周期', () {
    test('encryptDek / decryptDek 一致性：解密后与原始 DEK 完全一致', () async {
      // 生成随机 DEK
      final originalDek = cryptoEngine.generateKey();

      // 用 FakeKeyManager 加密 DEK
      final encryptedDekBytes = fakeKeyManager.encryptDek(originalDek);

      // 用 FakeKeyManager 解密 DEK
      final decryptedDek = fakeKeyManager.decryptDek(encryptedDekBytes);

      expect(decryptedDek, equals(originalDek),
          reason: 'encryptDek/decryptDek 应保持 DEK 值不变');
    });

    test('encryptDek：多次加密同一 DEK 结果不同（随机 IV）', () async {
      final dek = cryptoEngine.generateKey();

      final enc1 = fakeKeyManager.encryptDek(dek);
      final enc2 = fakeKeyManager.encryptDek(dek);

      // 由于 AES-GCM 每次使用随机 IV，加密结果应不同
      expect(enc1, isNot(equals(enc2)),
          reason: '同一 DEK 每次加密结果应不同（随机 IV）');
    });

    test('不同 KEK 无法解密对方的 DEK（跨 KeyManager 隔离）', () async {
      // 生成一个与 fakeKeyManager 默认 KEK（0x01..0x20）不同的随机 KEK
      final differentKek = cryptoEngine.generateKey();
      // 确保生成的 KEK 与默认 KEK 不同（极低概率相同，但防御性检查）
      final defaultKek = Uint8List.fromList(List.generate(32, (i) => i + 1));
      expect(differentKek, isNot(equals(defaultKek)),
          reason: '前置条件：两个 KEK 必须不同');

      // 第二个 FakeKeyManager 使用显式不同的 KEK
      final otherEngine = CryptoEngine();
      final otherKeyManager = FakeKeyManager(otherEngine, kek: differentKek);

      final dek = cryptoEngine.generateKey();
      final encryptedDek = fakeKeyManager.encryptDek(dek);

      // 用另一个 KeyManager（不同 KEK）解密 → GCM tag 校验失败 → CryptoException
      expect(
        () => otherKeyManager.decryptDek(encryptedDek),
        throwsA(isA<CryptoException>()),
        reason: '使用不同 KEK 解密 DEK 应抛出 CryptoException',
      );
    });

    test('完整文件周期中 DEK 的一致性：加密时生成的 DEK 可解密文件', () async {
      final originalData = _makeTestData(1024);
      final sourceFile = File(p.join(testRootDir.path, 'dek_test.bin'));
      await sourceFile.writeAsBytes(originalData);

      // encryptAndStore 内部生成并使用 DEK
      final result =
          await storage.encryptAndStore(sourceFile.path, 'dek_test_001');

      // 用返回的加密 DEK 解密文件
      final decrypted = await storage.decryptToMemory(
        result.encryptedPath,
        result.encryptedDek, // 这是 base64(encrypt(dek, kek))
        result.chunkCount,
      );

      expect(decrypted, equals(originalData),
          reason: 'encryptAndStore 返回的 encryptedDek 应能正确解密文件');

      // 验证：plainDek 与 encryptedDek 的一致性
      // plainDek 加密后应与 encryptedDek 解密结果一致
      final encryptedDekBytes = base64Decode(result.encryptedDek);
      final decryptedDekFromBase64 =
          fakeKeyManager.decryptDek(encryptedDekBytes);
      expect(decryptedDekFromBase64, equals(result.plainDek),
          reason: 'encryptedDek 解密后应与 plainDek 一致');
    });
  });

  // ─── 7. 向后兼容：旧格式文件（无 PVLT magic）仍可正确解密 ─────────────────────

  group('向后兼容（旧格式文件）', () {
    test('无 PVLT magic 的旧格式文件（chunkCount=1）应能正确解密', () async {
      // 模拟旧格式：直接写入密文，不添加 PVLT magic bytes
      final originalData = _makeTestData(512);
      final dek = cryptoEngine.generateKey();
      final encryptedData = cryptoEngine.encrypt(originalData, dek);

      // 直接写入加密数据（不加 PVLT magic 前缀），模拟旧格式文件
      final vaultDir = Directory(p.join(testRootDir.path, 'vault', 'files'));
      await vaultDir.create(recursive: true);
      final oldFormatFile =
          File(p.join(vaultDir.path, 'legacy_file.enc'));
      await oldFormatFile.writeAsBytes(encryptedData);

      // 用 FakeKeyManager 加密 DEK
      final encryptedDek = base64Encode(fakeKeyManager.encryptDek(dek));

      // 验证：旧格式文件不含 PVLT magic
      final fileBytes = await oldFormatFile.readAsBytes();
      expect(_hasPvltMagic(fileBytes), isFalse,
          reason: '旧格式文件不应含 PVLT magic bytes（前置条件）');

      // 执行：通过 decryptToMemory 解密旧格式文件（chunkCount=1）
      final decrypted = await storage.decryptToMemory(
        oldFormatFile.path,
        encryptedDek,
        1, // chunkCount = 1 → 走单文件分支
      );

      // 验证：解密结果与原始数据一致
      expect(decrypted, equals(originalData),
          reason: '旧格式文件（无 PVLT magic）应能正确解密，保持向后兼容');
    });

    test('新格式文件（含 PVLT magic）与旧格式解密结果一致', () async {
      // 准备相同的原始数据
      final originalData = _makeTestData(256);

      // 方式 1：通过 encryptAndStore 生成新格式
      final sourceFile = File(p.join(testRootDir.path, 'compat.bin'));
      await sourceFile.writeAsBytes(originalData);
      final newFmtResult =
          await storage.encryptAndStore(sourceFile.path, 'compat_new');

      // 验证新格式含 PVLT magic
      final newFmtBytes =
          await File(newFmtResult.encryptedPath).readAsBytes();
      expect(_hasPvltMagic(newFmtBytes), isTrue,
          reason: '新格式文件应含 PVLT magic');

      // 解密新格式
      final newFmtDecrypted = await storage.decryptToMemory(
        newFmtResult.encryptedPath,
        newFmtResult.encryptedDek,
        newFmtResult.chunkCount,
      );

      // 方式 2：模拟旧格式（用相同 DEK 直接加密，不加 magic）
      final dek = base64Decode(newFmtResult.encryptedDek);
      final plainDek = fakeKeyManager.decryptDek(dek);
      final oldFmtData = cryptoEngine.encrypt(originalData, plainDek);

      final vaultDir = Directory(p.join(testRootDir.path, 'vault', 'files'));
      final oldFile = File(p.join(vaultDir.path, 'compat_old.enc'));
      await oldFile.writeAsBytes(oldFmtData);

      final oldFmtDecrypted = await storage.decryptToMemory(
        oldFile.path,
        newFmtResult.encryptedDek, // 相同的加密 DEK
        1,
      );

      // 验证：两种格式解密结果均与原始数据一致
      expect(newFmtDecrypted, equals(originalData),
          reason: '新格式解密结果应与原始数据一致');
      expect(oldFmtDecrypted, equals(originalData),
          reason: '旧格式解密结果应与原始数据一致');
    });
  });
}

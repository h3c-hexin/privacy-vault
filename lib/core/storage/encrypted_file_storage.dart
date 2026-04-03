import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:uuid/uuid.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/chunk_encryptor.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';

/// 加密文件存储结果
class EncryptedFileResult {
  final String encryptedPath;
  final String? thumbnailPath;
  final int originalSize;
  final int encryptedSize;
  final String encryptedDek; // Base64
  final Uint8List plainDek;  // 明文 DEK（用于缩略图加密，调用方用后需清零）
  final int chunkCount;
  final String checksum;

  const EncryptedFileResult({
    required this.encryptedPath,
    this.thumbnailPath,
    required this.originalSize,
    required this.encryptedSize,
    required this.encryptedDek,
    required this.plainDek,
    required this.chunkCount,
    required this.checksum,
  });
}

/// 加密文件存储服务
///
/// 负责文件的加密存储和解密读取，大文件使用分块加密。
/// 加密文件使用 PVLT 魔数标识格式，前 4 字节为 [0x50, 0x56, 0x4C, 0x54]。
class EncryptedFileStorage {
  final CryptoEngine _cryptoEngine;
  final ChunkEncryptor _chunkEncryptor;
  final KeyManager _keyManager;

  static const int _chunkThreshold = 10 * 1024 * 1024; // 10MB
  static const _uuid = Uuid();

  /// PVLT 魔数：用于标识隐私保险箱加密文件格式
  static const List<int> _magicBytes = [0x50, 0x56, 0x4C, 0x54]; // "PVLT"

  /// 魔数长度（字节数）
  static const int _magicLength = 4;

  EncryptedFileStorage({
    required CryptoEngine cryptoEngine,
    required ChunkEncryptor chunkEncryptor,
    required KeyManager keyManager,
  })  : _cryptoEngine = cryptoEngine,
        _chunkEncryptor = chunkEncryptor,
        _keyManager = keyManager;

  /// 获取加密文件存储根目录
  Future<String> get _vaultDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'vault', 'files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// 获取缩略图存储目录
  Future<String> get thumbDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'vault', 'thumbnails'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// 获取临时文件目录（使用系统缓存目录，不被媒体扫描）
  Future<String> get _tempDir async {
    final cacheDir = await getTemporaryDirectory();
    final dir = Directory(p.join(cacheDir.path, 'vault_temp'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// 加密并存储文件
  ///
  /// 加密运算在后台 Isolate 中执行，不阻塞 UI 线程。
  /// 返回加密结果（路径、大小、DEK 等元数据）
  Future<EncryptedFileResult> encryptAndStore(
    String sourceFilePath,
    String fileId,
  ) async {
    final sourceFile = File(sourceFilePath);
    final originalSize = await sourceFile.length();

    // 生成文件专属 DEK
    final dek = _keyManager.generateDek();

    String encryptedPath;
    int encryptedSize;
    int chunkCount;

    String checksum;

    if (originalSize > _chunkThreshold) {
      // 大文件：读取+分块加密+校验和一次性完成（避免重复读取）
      final result = await Isolate.run(() {
        final bytes = File(sourceFilePath).readAsBytesSync();
        final engine = CryptoEngine();
        final chunker = ChunkEncryptor(engine: engine);
        final chunks = chunker.encryptChunks(bytes, dek);
        final cs = _computeChecksumStatic(bytes);
        return (chunks: chunks, checksum: cs);
      });
      final chunks = result.chunks;
      checksum = result.checksum;
      chunkCount = chunks.length;

      final chunkDir = Directory(p.join(await _vaultDir, fileId));
      await chunkDir.create(recursive: true);

      // 写入 header.pvlt 文件，包含 PVLT 魔数，标识此目录为加密文件集
      final headerFile = File(p.join(chunkDir.path, 'header.pvlt'));
      await headerFile.writeAsBytes(Uint8List.fromList(_magicBytes));

      encryptedSize = 0;
      for (var i = 0; i < chunks.length; i++) {
        final chunkFile = File(
          p.join(chunkDir.path, 'chunk_${i.toString().padLeft(3, '0')}.enc'),
        );
        await chunkFile.writeAsBytes(chunks[i]);
        encryptedSize += chunks[i].length;
      }
      encryptedPath = chunkDir.path;
    } else {
      // 小文件：读取+加密+校验和一次性完成
      final result = await Isolate.run(() {
        final bytes = File(sourceFilePath).readAsBytesSync();
        final engine = CryptoEngine();
        final enc = engine.encrypt(bytes, dek);
        final cs = _computeChecksumStatic(bytes);
        return (encrypted: enc, checksum: cs);
      });
      final encrypted = result.encrypted;
      checksum = result.checksum;
      chunkCount = 1;
      encryptedSize = encrypted.length + _magicLength;

      // 拼接 PVLT 魔数 + 密文，写入文件
      final fileBytes = Uint8List(_magicLength + encrypted.length);
      fileBytes.setAll(0, _magicBytes);
      fileBytes.setRange(_magicLength, fileBytes.length, encrypted);

      encryptedPath = p.join(await _vaultDir, '$fileId.enc');
      await File(encryptedPath).writeAsBytes(fileBytes);
    }

    // 用 KEK 加密 DEK
    final encryptedDek = _keyManager.encryptDek(dek);

    // 注意：不清零 dek，由调用方在缩略图生成后负责清零
    return EncryptedFileResult(
      encryptedPath: encryptedPath,
      originalSize: originalSize,
      encryptedSize: encryptedSize,
      encryptedDek: _bytesToBase64(encryptedDek),
      plainDek: dek,
      chunkCount: chunkCount,
      checksum: checksum,
    );
  }

  /// 静态版本的校验和计算（可在 Isolate 中调用）
  static String _computeChecksumStatic(Uint8List data) {
    final digest = pc.SHA256Digest();
    final hash = digest.process(data);
    return base64Encode(hash);
  }

  /// 解密文件到内存
  ///
  /// 解密运算在后台 Isolate 中执行，不阻塞 UI 线程。
  Future<Uint8List> decryptToMemory(
    String encryptedPath,
    String encryptedDekBase64,
    int chunkCount,
  ) async {
    // 解密 DEK（需要内存中的 KEK，必须在主 Isolate）
    final encryptedDek = _base64ToBytes(encryptedDekBase64);
    final dek = _keyManager.decryptDek(encryptedDek);

    try {
      if (chunkCount > 1) {
        // 分块加密目录：检查 header.pvlt 判断格式版本
        // 有 header.pvlt = 新格式（使用序号 AAD），无 = 旧格式（空 AAD，向后兼容）
        final headerFile = File(p.join(encryptedPath, 'header.pvlt'));
        final isNewFormat = await headerFile.exists();
        if (isNewFormat) {
          final headerBytes = await headerFile.readAsBytes();
          if (!_hasMagicBytes(headerBytes)) {
            throw const FormatException('PVLT 魔数校验失败：文件格式不正确或已损坏');
          }
        }

        // 读取所有 chunk 文件
        final dir = Directory(encryptedPath);
        final chunkFiles = await dir.list().toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        final chunks = <Uint8List>[];
        for (final entity in chunkFiles) {
          if (entity is File && entity.path.endsWith('.enc')) {
            chunks.add(await entity.readAsBytes());
          }
        }
        // 在 Isolate 中解密（新格式用序号 AAD，旧格式用空 AAD）
        final useAad = isNewFormat;
        return await Isolate.run(() {
          final engine = CryptoEngine();
          final chunker = ChunkEncryptor(engine: engine);
          return chunker.decryptChunks(chunks, dek, useAad: useAad);
        });
      } else {
        // 单文件：读取后检查魔数，兼容旧格式（无魔数直接解密）
        final rawBytes = await File(encryptedPath).readAsBytes();
        final Uint8List encrypted;
        if (_hasMagicBytes(rawBytes)) {
          // 新格式：跳过前 4 字节魔数
          encrypted = rawBytes.sublist(_magicLength);
        } else {
          // 旧格式：整体作为密文（向后兼容）
          encrypted = rawBytes;
        }
        return await Isolate.run(() {
          final engine = CryptoEngine();
          return engine.decrypt(encrypted, dek);
        });
      }
    } finally {
      // 覆写 DEK
      for (var i = 0; i < dek.length; i++) {
        dek[i] = 0;
      }
    }
  }

  /// 解密文件到临时目录（用于分享/导出）
  ///
  /// 返回临时文件路径，使用后应调用 cleanTempFile 清理
  Future<String> decryptToTemp(
    String encryptedPath,
    String encryptedDekBase64,
    int chunkCount,
    String fileName,
  ) async {
    final bytes = await decryptToMemory(encryptedPath, encryptedDekBase64, chunkCount);
    final ext = p.extension(fileName);
    final tempPath = p.join(await _tempDir, '${_uuid.v4()}$ext');
    await File(tempPath).writeAsBytes(bytes);
    return tempPath;
  }

  /// 清理临时文件
  Future<void> cleanTempFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 清理所有临时文件
  Future<void> cleanAllTemp() async {
    final dir = Directory(await _tempDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  /// 删除加密文件
  Future<void> deleteEncryptedFile(String encryptedPath, int chunkCount) async {
    if (chunkCount > 1) {
      final dir = Directory(encryptedPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } else {
      final file = File(encryptedPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// 删除加密缩略图
  Future<void> deleteThumbnail(String? thumbnailPath) async {
    if (thumbnailPath == null) return;
    final file = File(thumbnailPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _computeChecksum(Uint8List data) {
    final digest = pc.SHA256Digest();
    final hash = digest.process(data);
    return base64Encode(hash);
  }

  String _bytesToBase64(Uint8List bytes) => base64Encode(bytes);

  Uint8List _base64ToBytes(String b64) => base64Decode(b64);

  /// 检查字节数组是否以 PVLT 魔数开头
  ///
  /// 用于区分新格式（带魔数）与旧格式（无魔数），实现向后兼容。
  bool _hasMagicBytes(Uint8List data) {
    if (data.length < _magicLength) return false;
    for (var i = 0; i < _magicLength; i++) {
      if (data[i] != _magicBytes[i]) return false;
    }
    return true;
  }
}

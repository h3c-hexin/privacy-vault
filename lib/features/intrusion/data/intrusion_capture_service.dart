import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';

/// 入侵拍照服务
///
/// 在 PIN 错误达到阈值时，静默使用前置摄像头拍照，
/// 加密存储照片并记录到数据库。
class IntrusionCaptureService {
  final CryptoEngine _cryptoEngine;
  final KeyManager _keyManager;
  final EncryptedFileStorage _fileStorage;
  final AppDatabase _db;
  static const _uuid = Uuid();

  /// 触发拍照的错误次数阈值
  static const int captureThreshold = 3;

  CameraController? _controller;

  IntrusionCaptureService({
    required CryptoEngine cryptoEngine,
    required KeyManager keyManager,
    required EncryptedFileStorage fileStorage,
    required AppDatabase database,
  })  : _cryptoEngine = cryptoEngine,
        _keyManager = keyManager,
        _fileStorage = fileStorage,
        _db = database;

  /// 静默拍照并加密存储
  ///
  /// 返回 true 表示成功拍照并存储。
  /// 失败时静默降级（无相机权限等场景）。
  Future<bool> captureAndStore(int attemptCount) async {
    try {
      // 获取前置摄像头
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // 初始化相机（低分辨率，快速拍照）
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _controller!.initialize();

      // 拍照
      final xFile = await _controller!.takePicture();
      final photoBytes = await xFile.readAsBytes();

      // 释放相机
      await _controller!.dispose();
      _controller = null;

      // 删除原始临时文件
      final tempFile = File(xFile.path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // 加密照片
      final dek = _keyManager.generateDek();
      final encrypted = _cryptoEngine.encrypt(photoBytes, dek);
      final encryptedDek = _keyManager.encryptDek(dek);

      // 存储加密文件
      final recordId = _uuid.v4();
      final thumbDir = await _fileStorage.thumbDir;
      final photoPath = p.join(thumbDir, '${recordId}_intrusion.enc');
      await File(photoPath).writeAsBytes(encrypted);

      // 清零 DEK
      for (var i = 0; i < dek.length; i++) {
        dek[i] = 0;
      }

      // 写入数据库
      await _db.insertIntrusionRecord(IntrusionRecordsCompanion(
        id: drift.Value(recordId),
        photoPath: drift.Value(photoPath),
        encryptedDek: drift.Value(_bytesToBase64(encryptedDek)),
        dekIv: const drift.Value(''),
        photoIv: const drift.Value(''),
        timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
        attemptCount: drift.Value(attemptCount),
      ));

      return true;
    } catch (e, stack) {
      developer.log(
        '入侵拍照失败',
        error: e,
        stackTrace: stack,
        name: 'IntrusionCapture',
      );
      // 确保相机被释放
      await _controller?.dispose();
      _controller = null;
      return false;
    }
  }

  /// 解密入侵照片到内存
  Future<Uint8List?> decryptPhoto(IntrusionRecord record) async {
    try {
      final encryptedDek = _base64ToBytes(record.encryptedDek);
      final dek = _keyManager.decryptDek(encryptedDek);

      try {
        final encrypted = await File(record.photoPath).readAsBytes();
        return _cryptoEngine.decrypt(encrypted, dek);
      } finally {
        for (var i = 0; i < dek.length; i++) {
          dek[i] = 0;
        }
      }
    } catch (e) {
      developer.log('入侵照片解密失败: $e', name: 'IntrusionCapture');
      return null;
    }
  }

  String _bytesToBase64(Uint8List bytes) => base64Encode(bytes);

  Uint8List _base64ToBytes(String b64) => base64Decode(b64);
}

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';

/// 缩略图生成服务
///
/// 负责为导入的图片生成缩略图，并加密存储。
/// 图片解码、缩放、编码、加密全部在 Isolate 中执行，不阻塞 UI。
class ThumbnailService {
  final CryptoEngine _cryptoEngine;
  final KeyManager _keyManager;
  final EncryptedFileStorage _fileStorage;

  static const int thumbSize = 300; // 缩略图最大边长

  ThumbnailService({
    required CryptoEngine cryptoEngine,
    required KeyManager keyManager,
    required EncryptedFileStorage fileStorage,
  })  : _cryptoEngine = cryptoEngine,
        _keyManager = keyManager,
        _fileStorage = fileStorage;

  /// 一次性生成加密缩略图并返回尺寸
  ///
  /// 合并了原来的 generateImageThumbnail + getImageDimensions，
  /// 只读取和解码图片一次，所有 CPU 密集操作在 Isolate 中执行。
  /// 返回 Record 类型（非自定义类），确保跨 Isolate 传递安全。
  Future<({String? thumbnailPath, int? width, int? height})>
      generateThumbnailAndGetDimensions(
    String sourceImagePath,
    String fileId,
    Uint8List fileDek,
  ) async {
    try {
      // 文件读取 + 图片解码 + 缩放 + 编码 + 加密，全部在 Isolate 中执行
      // 传路径而非字节，避免大文件跨 Isolate 复制开销
      final result = await Isolate.run(() {
        final bytes = File(sourceImagePath).readAsBytesSync();
        final image = img.decodeImage(bytes);
        if (image == null) return null;

        // 等比缩放
        final thumbnail = img.copyResize(
          image,
          width: image.width > image.height ? thumbSize : null,
          height: image.height >= image.width ? thumbSize : null,
          interpolation: img.Interpolation.linear,
        );

        // 编码为 JPEG
        final thumbBytes =
            Uint8List.fromList(img.encodeJpg(thumbnail, quality: 75));

        // 加密缩略图
        final engine = CryptoEngine();
        final encrypted = engine.encrypt(thumbBytes, fileDek);

        // 返回 Record（基础类型组合），确保跨 Isolate 安全
        return (encrypted, image.width, image.height);
      });

      if (result == null) {
        developer.log('缩略图生成: 图片解码失败', name: 'ThumbnailService');
        return (thumbnailPath: null, width: null, height: null);
      }

      final (encryptedThumb, width, height) = result;

      // IO 写入在主 Isolate 执行
      final thumbDir = await _fileStorage.thumbDir;
      final thumbPath = p.join(thumbDir, '${fileId}_thumb.enc');
      await File(thumbPath).writeAsBytes(encryptedThumb);

      developer.log(
        '缩略图生成成功: $thumbPath (${encryptedThumb.length} 字节, ${width}x$height)',
        name: 'ThumbnailService',
      );

      return (thumbnailPath: thumbPath, width: width, height: height);
    } catch (e, stack) {
      developer.log(
        '缩略图生成异常',
        error: e,
        stackTrace: stack,
        name: 'ThumbnailService',
      );
      return (thumbnailPath: null, width: null, height: null);
    }
  }
}

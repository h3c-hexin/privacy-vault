import 'dart:typed_data';
import 'crypto_engine.dart';

/// 分块加密器
///
/// 将大文件按固定大小分块，每块独立使用 AES-256-GCM 加密。
/// 每块有独立的 IV，共享同一个 DEK。
class ChunkEncryptor {
  /// 默认分块大小: 1MB
  static const int defaultChunkSize = 1024 * 1024;

  final CryptoEngine engine;
  final int chunkSize;

  ChunkEncryptor({
    required this.engine,
    this.chunkSize = defaultChunkSize,
  });

  /// 生成块序号 AAD（4 字节大端序），防止块重排序攻击
  static Uint8List _chunkAad(int index) {
    return Uint8List(4)
      ..[0] = (index >> 24) & 0xFF
      ..[1] = (index >> 16) & 0xFF
      ..[2] = (index >> 8) & 0xFF
      ..[3] = index & 0xFF;
  }

  /// 将明文分块加密
  ///
  /// 每块携带序号 AAD，防止块重排序攻击。
  /// 返回加密后的 chunk 列表，每个 chunk 格式: [IV][Ciphertext][Tag]
  List<Uint8List> encryptChunks(Uint8List plaintext, Uint8List key) {
    if (plaintext.isEmpty) return [];

    final chunks = <Uint8List>[];
    var offset = 0;
    var index = 0;

    while (offset < plaintext.length) {
      final end = (offset + chunkSize).clamp(0, plaintext.length);
      final chunk = plaintext.sublist(offset, end);
      chunks.add(engine.encrypt(chunk, key, aad: _chunkAad(index)));
      offset = end;
      index++;
    }

    return chunks;
  }

  /// 将加密的 chunk 列表解密并拼接
  ///
  /// [useAad] 为 true 时使用序号 AAD 解密（新格式），
  /// 为 false 时使用空 AAD 解密（旧格式，向后兼容）。
  Uint8List decryptChunks(List<Uint8List> encryptedChunks, Uint8List key, {bool useAad = true}) {
    if (encryptedChunks.isEmpty) return Uint8List(0);

    final decryptedParts = <Uint8List>[];
    var totalLength = 0;

    for (var i = 0; i < encryptedChunks.length; i++) {
      final aad = useAad ? _chunkAad(i) : null;
      final decrypted = engine.decrypt(encryptedChunks[i], key, aad: aad);
      decryptedParts.add(decrypted);
      totalLength += decrypted.length;
    }

    final result = Uint8List(totalLength);
    var offset = 0;
    for (final part in decryptedParts) {
      result.setAll(offset, part);
      offset += part.length;
    }

    return result;
  }

  /// 计算给定数据大小需要多少个 chunk
  int chunkCount(int dataSize) {
    if (dataSize <= 0) return 0;
    return (dataSize + chunkSize - 1) ~/ chunkSize;
  }
}

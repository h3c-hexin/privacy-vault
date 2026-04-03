import 'package:flutter/services.dart';

/// Android Keystore 服务
///
/// 通过 MethodChannel 调用 Android Keystore，
/// 提供硬件级密钥保护。
class KeystoreService {
  static const _channel = MethodChannel('com.privacyvault/keystore');

  /// 在 Keystore 中生成 AES-256 密钥
  Future<void> generateKey() async {
    await _channel.invokeMethod('generateKey');
  }

  /// 检查 Keystore 中是否已有密钥
  Future<bool> hasKey() async {
    final result = await _channel.invokeMethod<bool>('hasKey');
    return result ?? false;
  }

  /// 使用 Keystore 密钥加密数据
  ///
  /// 返回 (密文, IV)
  Future<({Uint8List ciphertext, Uint8List iv})> encrypt(
    Uint8List plaintext,
  ) async {
    final result = await _channel.invokeMethod<Map>('encrypt', {
      'plaintext': plaintext,
    });
    if (result == null) throw const KeystoreException('加密返回空结果');

    return (
      ciphertext: Uint8List.fromList(result['ciphertext'] as List<int>),
      iv: Uint8List.fromList(result['iv'] as List<int>),
    );
  }

  /// 使用 Keystore 密钥解密数据
  Future<Uint8List> decrypt(Uint8List ciphertext, Uint8List iv) async {
    final result = await _channel.invokeMethod<Uint8List>('decrypt', {
      'ciphertext': ciphertext,
      'iv': iv,
    });
    if (result == null) throw const KeystoreException('解密返回空结果');
    return result;
  }

  /// 删除 Keystore 中的密钥（紧急销毁用）
  Future<void> deleteKey() async {
    await _channel.invokeMethod('deleteKey');
  }
}

/// Keystore 操作异常
class KeystoreException implements Exception {
  final String message;
  const KeystoreException(this.message);

  @override
  String toString() => 'KeystoreException: $message';
}

import 'package:local_auth/local_auth.dart';

/// 生物识别辅助
class BiometricHelper {
  final LocalAuthentication _auth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// 执行生物识别认证
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: '使用指纹或面部识别解锁',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

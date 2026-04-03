import 'package:equatable/equatable.dart';

/// 设置模块加载状态
enum SettingsStatus {
  initial,  // 初始状态
  loading,  // 正在加载
  loaded,   // 加载完成
  saving,   // 正在保存单项设置
  error,    // 发生错误
}

/// 设置模块状态（Equatable 不可变）
class SettingsState extends Equatable {
  final SettingsStatus status;

  /// 生物识别硬件是否可用
  final bool biometricAvailable;

  /// 生物识别开关
  final bool biometricEnabled;

  /// 入侵检测开关
  final bool intrusionEnabled;

  /// 自动锁定时间（秒），0 表示立即锁定
  final int autoLockSeconds;

  /// 已加密文件占用字节数
  final int usedBytes;

  /// 设备可用磁盘空间（字节），0 表示未能获取
  final int availableBytes;

  /// 错误信息（可为 null）
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.intrusionEnabled = false,
    this.autoLockSeconds = 30,
    this.usedBytes = 0,
    this.availableBytes = 0,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    bool? biometricAvailable,
    bool? biometricEnabled,
    bool? intrusionEnabled,
    int? autoLockSeconds,
    int? usedBytes,
    int? availableBytes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      intrusionEnabled: intrusionEnabled ?? this.intrusionEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      usedBytes: usedBytes ?? this.usedBytes,
      availableBytes: availableBytes ?? this.availableBytes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        biometricAvailable,
        biometricEnabled,
        intrusionEnabled,
        autoLockSeconds,
        usedBytes,
        availableBytes,
        errorMessage,
      ];
}

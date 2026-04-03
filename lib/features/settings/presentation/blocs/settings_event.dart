import 'package:equatable/equatable.dart';

/// 设置模块事件基类
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// 加载所有设置项及存储空间信息
class SettingsLoad extends SettingsEvent {}

/// 修改生物识别开关
class SettingsToggleBiometric extends SettingsEvent {
  final bool enabled;
  const SettingsToggleBiometric(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// 修改入侵检测开关
class SettingsToggleIntrusion extends SettingsEvent {
  final bool enabled;
  const SettingsToggleIntrusion(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// 修改自动锁定时间（秒）
class SettingsChangeAutoLock extends SettingsEvent {
  final int seconds;
  const SettingsChangeAutoLock(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/security/session_manager.dart';
import 'package:privacy_vault/features/auth/presentation/pages/biometric_helper.dart';
import 'package:privacy_vault/features/settings/presentation/blocs/settings_event.dart';
import 'package:privacy_vault/features/settings/presentation/blocs/settings_state.dart';

/// 设置模块 BLoC
///
/// 负责读写所有设置项（生物识别、入侵检测、自动锁定时间）
/// 以及获取存储空间使用情况，所有副作用集中于此，UI 保持纯展示。
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AppDatabase _db;
  final SessionManager _sessionManager;
  final BiometricHelper _biometric;

  // 数据库中的设置键名
  static const _keyBiometric = 'biometric_enabled';
  static const _keyIntrusion = 'intrusion_enabled';
  static const _keyAutoLock = 'auto_lock_seconds';

  SettingsBloc({
    required AppDatabase database,
    required SessionManager sessionManager,
    BiometricHelper? biometric,
  })  : _db = database,
        _sessionManager = sessionManager,
        _biometric = biometric ?? BiometricHelper(),
        super(const SettingsState()) {
    on<SettingsLoad>(_onLoad);
    on<SettingsToggleBiometric>(_onToggleBiometric);
    on<SettingsToggleIntrusion>(_onToggleIntrusion);
    on<SettingsChangeAutoLock>(_onChangeAutoLock);
  }

  /// 加载全部设置并获取存储空间信息
  Future<void> _onLoad(
    SettingsLoad event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      // 并发读取所有设置（避免串行等待）
      final results = await Future.wait([
        _biometric.isAvailable(),
        _db.getSetting(_keyBiometric),
        _db.getSetting(_keyIntrusion),
        _db.getSetting(_keyAutoLock),
        _db.getTotalEncryptedSize(),
        _fetchAvailableBytes(),
      ]);
      final biometricAvailable = results[0] as bool;
      final biometricStr = results[1] as String?;
      final intrusionStr = results[2] as String?;
      final autoLockStr = results[3] as String?;
      final usedBytes = results[4] as int;
      final availableBytes = results[5] as int;

      emit(state.copyWith(
        status: SettingsStatus.loaded,
        biometricAvailable: biometricAvailable,
        biometricEnabled: biometricStr == 'true',
        intrusionEnabled: intrusionStr == 'true',
        autoLockSeconds: int.tryParse(autoLockStr ?? '') ?? 30,
        usedBytes: usedBytes,
        availableBytes: availableBytes,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: '加载设置失败',
      ));
    }
  }

  /// 切换生物识别开关
  ///
  /// 开启时需先完成一次生物识别验证，验证失败则取消操作。
  Future<void> _onToggleBiometric(
    SettingsToggleBiometric event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.enabled) {
      // 开启前先验证一次生物识别，确认设备已注册
      final success = await _biometric.authenticate();
      if (!success) return; // 验证失败，不做任何修改
    }
    emit(state.copyWith(status: SettingsStatus.saving));
    await _db.setSetting(_keyBiometric, event.enabled.toString());
    emit(state.copyWith(
      status: SettingsStatus.loaded,
      biometricEnabled: event.enabled,
    ));
  }

  /// 切换入侵检测开关
  Future<void> _onToggleIntrusion(
    SettingsToggleIntrusion event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.saving));
    await _db.setSetting(_keyIntrusion, event.enabled.toString());
    emit(state.copyWith(
      status: SettingsStatus.loaded,
      intrusionEnabled: event.enabled,
    ));
  }

  /// 修改自动锁定时间，同时实时更新 SessionManager
  Future<void> _onChangeAutoLock(
    SettingsChangeAutoLock event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.saving));
    await _db.setSetting(_keyAutoLock, event.seconds.toString());
    // 实时生效，无需重启
    _sessionManager.setAutoLockDelay(Duration(seconds: event.seconds));
    emit(state.copyWith(
      status: SettingsStatus.loaded,
      autoLockSeconds: event.seconds,
    ));
  }

  /// 通过 `df` 命令获取应用数据目录的可用磁盘空间（字节）
  ///
  /// 失败时返回 0，不抛出异常，存储空间展示为可选信息。
  Future<int> _fetchAvailableBytes() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final process = await Process.run('df', [appDir.path]);
      if (process.exitCode == 0) {
        // df 输出第二行包含可用空间，第 4 列为 1K-blocks 单位的可用量
        final lines = process.stdout.toString().trim().split('\n');
        if (lines.length >= 2) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            return (int.tryParse(parts[3]) ?? 0) * 1024;
          }
        }
      }
    } catch (_) {
      // 获取失败时静默处理，返回 0
    }
    return 0;
  }
}

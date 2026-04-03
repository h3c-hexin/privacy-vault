import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_state.dart';
import 'package:privacy_vault/features/auth/presentation/widgets/pin_input.dart';

/// 密码修改页 - 3 步骤流程
///
/// 步骤 1: 输入当前密码
/// 步骤 2: 输入新密码
/// 步骤 3: 确认新密码
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  int _step = 0; // 0=验证旧密码, 1=输入新密码, 2=确认新密码
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;
  bool _isProcessing = false;

  final _titles = ['输入当前密码', '设置新密码', '确认新密码'];
  final _subtitles = ['验证身份', '请输入 6-8 位新密码', '再次输入新密码确认'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            // 步骤指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => _StepDot(active: i <= _step)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _titles[_step],
              style: AppTypography.h3.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _subtitles[_step],
              style: AppTypography.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            PinInput(pin: _currentStepPin, maxLength: 8),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: TextStyle(color: AppColors.errorMain),
              ),
            ],
            // 确认按钮（所有步骤都需手动确认）
            if (_currentStepPin.length >= (_step == 0 ? 4 : 6)) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _onConfirmStep,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('确认 (${_currentStepPin.length} 位)'),
                ),
              ),
            ],
            const Spacer(),
            if (!_isProcessing)
              PinKeyboard(
                onKeyPressed: (key) {
                  if (key == 'delete') {
                    _onDelete();
                  } else {
                    _onDigit(key);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String get _currentStepPin {
    switch (_step) {
      case 0:
        return _currentPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  void _onDigit(String digit) {
    if (_isProcessing) return;

    setState(() {
      _errorMessage = null;
      switch (_step) {
        case 0:
          if (_currentPin.length < 8) _currentPin += digit;
        case 1:
          if (_newPin.length < 8) _newPin += digit;
        case 2:
          if (_confirmPin.length < 8) _confirmPin += digit;
      }
    });

    // 步骤 2 不自动提交，由确认按钮触发
  }

  /// 确认按钮回调（三个步骤）
  void _onConfirmStep() {
    if (_step == 0) {
      _verifyCurrentPin();
    } else if (_step == 1) {
      setState(() {
        _step = 2;
        _errorMessage = null;
      });
    } else if (_step == 2) {
      _confirmAndChange();
    }
  }

  void _onDelete() {
    setState(() {
      _errorMessage = null;
      switch (_step) {
        case 0:
          if (_currentPin.isNotEmpty) {
            _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          }
        case 1:
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
          }
        case 2:
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
      }
    });
  }

  Future<void> _verifyCurrentPin() async {
    // 通过 AuthBloc 验证，遵循冷却期保护
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state.isInCooldown) {
      setState(() {
        _errorMessage = '错误次数过多，请稍后再试';
        _currentPin = '';
      });
      return;
    }

    setState(() => _isProcessing = true);

    final keyManager = getIt<KeyManager>();
    final success = await keyManager.unlockWithPin(_currentPin);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isProcessing = false;
        _step = 1;
        _errorMessage = null;
      });
    } else {
      // 通知 AuthBloc 记录失败次数
      authBloc.add(AuthUnlockWithPin(_currentPin));
      setState(() {
        _isProcessing = false;
        _errorMessage = '密码错误';
        _currentPin = '';
      });
    }
  }

  Future<void> _confirmAndChange() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = '两次输入不一致';
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final keyManager = getIt<KeyManager>();
      await keyManager.changePin(_currentPin, _newPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('密码修改成功'),
            backgroundColor: AppColors.successMain,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = '修改失败';
        _confirmPin = '';
      });
    }
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

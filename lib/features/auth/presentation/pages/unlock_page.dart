import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_state.dart';
import 'package:privacy_vault/features/auth/presentation/widgets/pin_input.dart';

/// PIN 解锁页面
class UnlockPage extends StatefulWidget {
  const UnlockPage({super.key});

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  String _pin = '';
  bool _isVerifying = false;

  void _onPinChanged(String pin) {
    if (_isVerifying) return; // 验证中禁止输入
    setState(() => _pin = pin);

    // >= 4 兼容旧版 PIN，新用户设置时已强制 >= 6 位
    if (pin.length >= 4) {
      setState(() => _isVerifying = true);
      context.read<AuthBloc>().add(AuthUnlockWithPin(pin));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          // 验证失败，清空 PIN 并恢复输入
          setState(() { _pin = ''; _isVerifying = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isInCooldown
                    ? '错误次数过多，请稍后再试'
                    : '${state.errorMessage}（${state.errorCount} 次）',
              ),
              backgroundColor: AppColors.errorMain,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '输入密码',
                  style: AppTypography.h2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return PinInput(
                      pin: _pin,
                      maxLength: 8,
                    );
                  },
                ),
                const Spacer(),
                PinKeyboard(
                  onKeyPressed: (key) {
                    if (key == 'delete') {
                      if (_pin.isNotEmpty) {
                        _onPinChanged(_pin.substring(0, _pin.length - 1));
                      }
                    } else if (_pin.length < 8) {
                      _onPinChanged(_pin + key);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/auth/presentation/widgets/pin_input.dart';

/// 首次设置页面
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _pin = '';
  String? _firstPin;
  bool _isConfirming = false;

  void _onPinChanged(String pin) {
    setState(() => _pin = pin);

    // PIN 最小长度为 6 位
    if (pin.length >= 6) {
      if (!_isConfirming) {
        // 第一次输入
        setState(() {
          _firstPin = pin;
          _isConfirming = true;
          _pin = '';
        });
      } else {
        // 确认输入
        if (pin == _firstPin) {
          context.read<AuthBloc>().add(AuthSetupPin(pin));
        } else {
          setState(() {
            _isConfirming = false;
            _firstPin = null;
            _pin = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('两次输入不一致，请重新设置')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _isConfirming ? '请再次输入密码' : '设置密码',
                style: AppTypography.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isConfirming ? '确认你的 6 位数字密码' : '设置 6 位数字密码保护你的隐私文件',
                style: AppTypography.bodyMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PinInput(
                pin: _pin,
                maxLength: 6,
              ),
              const Spacer(),
              PinKeyboard(
                onKeyPressed: (key) {
                  if (key == 'delete') {
                    if (_pin.isNotEmpty) {
                      _onPinChanged(_pin.substring(0, _pin.length - 1));
                    }
                  } else if (_pin.length < 6) {
                    _onPinChanged(_pin + key);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

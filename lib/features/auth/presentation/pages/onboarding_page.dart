import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/auth/presentation/widgets/pin_input.dart';

/// 新手引导页 - 4 步骤流程
///
/// 步骤 1: 欢迎 + 功能介绍
/// 步骤 2: 设置 PIN（输入 + 确认）
/// 步骤 3: 安全提示（记住密码、无法找回）
/// 步骤 4: 使用引导（计算器入口说明）
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // PIN 设置相关
  String _pin = '';
  String? _firstPin;
  bool _isConfirming = false;
  bool _pinSetupDone = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 步骤指示器
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                )),
              ),
            ),
            // 页面内容
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onNext: _nextStep),
                  _PinSetupStep(
                    pin: _pin,
                    isConfirming: _isConfirming,
                    onPinChanged: _onPinChanged,
                    onPinConfirmed: _onPinConfirmed,
                  ),
                  _SecurityTipStep(onNext: _nextStep),
                  _GuideStep(onComplete: _onComplete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPinChanged(String pin) {
    setState(() => _pin = pin);
  }

  /// 用户点击"确认"按钮后提交 PIN（PIN 最小长度为 6 位）
  void _onPinConfirmed() {
    if (_pin.length < 6) return;

    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _isConfirming = true;
        _pin = '';
      });
    } else {
      if (_pin == _firstPin) {
        setState(() => _pinSetupDone = true);
        _nextStep();
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

  void _onComplete() {
    if (_pinSetupDone && _firstPin != null) {
      context.read<AuthBloc>().add(AuthSetupPin(_firstPin!));
    }
  }
}

/// 步骤 1: 欢迎
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.gradientCardFor(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '欢迎使用隐私保险箱',
            style: AppTypography.h2.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '你的私密文件，只有你能看到',
            style: AppTypography.bodyLg.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _FeatureItem(
            icon: Icons.lock_outline,
            title: '军事级加密',
            subtitle: 'AES-256-GCM 保护每一个文件',
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.calculate_outlined,
            title: '计算器伪装',
            subtitle: '外观就是一个普通计算器',
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.cloud_off_outlined,
            title: '纯本地存储',
            subtitle: '不联网，不上传，数据只在你的手机',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('开始设置'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 步骤 2: PIN 设置
class _PinSetupStep extends StatelessWidget {
  final String pin;
  final bool isConfirming;
  final void Function(String) onPinChanged;
  final VoidCallback onPinConfirmed;

  const _PinSetupStep({
    required this.pin,
    required this.isConfirming,
    required this.onPinChanged,
    required this.onPinConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    // PIN 最小长度为 6 位
    final canConfirm = pin.length >= 6;

    return Padding(
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
            isConfirming ? '请再次输入密码' : '设置密码',
            style: AppTypography.h2.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isConfirming ? '确认你的数字密码' : '设置 6-8 位数字密码',
            style: AppTypography.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PinInput(pin: pin, maxLength: 8),
          const SizedBox(height: AppSpacing.xl),
          // 确认按钮，输入 >= 6 位后显示
          AnimatedOpacity(
            opacity: canConfirm ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: 200,
              child: FilledButton(
                onPressed: canConfirm ? onPinConfirmed : null,
                child: Text('确认 (${pin.length} 位)'),
              ),
            ),
          ),
          const Spacer(),
          PinKeyboard(
            onKeyPressed: (key) {
              if (key == 'delete') {
                if (pin.isNotEmpty) {
                  onPinChanged(pin.substring(0, pin.length - 1));
                }
              } else if (pin.length < 8) {
                onPinChanged(pin + key);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// 步骤 3: 安全提示
class _SecurityTipStep extends StatelessWidget {
  final VoidCallback onNext;
  const _SecurityTipStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.warning_amber_outlined,
            size: 64,
            color: AppColors.warningMain,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '重要安全提示',
            style: AppTypography.h2.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _TipItem(
            icon: Icons.key_outlined,
            text: '请牢记你的密码，忘记密码将无法恢复数据',
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipItem(
            icon: Icons.delete_forever_outlined,
            text: '卸载 App 将永久删除所有加密文件',
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipItem(
            icon: Icons.cloud_off_outlined,
            text: '数据仅存储在本地，不提供云备份',
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipItem(
            icon: Icons.screenshot_outlined,
            text: 'App 已启用防截屏保护',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('我已了解'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 步骤 4: 使用引导
class _GuideStep extends StatelessWidget {
  final VoidCallback onComplete;
  const _GuideStep({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.calculate_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '如何进入保险箱',
            style: AppTypography.h2.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.gradientCardFor(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _GuideItem(step: '1', text: '打开 App，看到的是计算器界面'),
                const SizedBox(height: AppSpacing.md),
                _GuideItem(step: '2', text: '在计算器中输入你的密码'),
                const SizedBox(height: AppSpacing.md),
                _GuideItem(step: '3', text: '按下 "=" 键即可进入保险箱'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '对其他人来说，这只是一个普通的计算器',
            style: AppTypography.bodySm.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onComplete,
              child: const Text('开始使用'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMd.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySm.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.warningMain, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String step;
  final String text;

  const _GuideItem({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}

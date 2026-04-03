import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_bloc.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_event.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_state.dart';

/// 计算器伪装页
///
/// 模仿系统计算器，输入 PIN + "=" 进入保险箱。
class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalculatorBloc, CalculatorState>(
      listenWhen: (prev, curr) => !prev.pinDetected && curr.pinDetected,
      listener: (context, state) {
        // PIN 检测成功，KeyManager 已完成解锁，直接通知 AuthBloc
        context.read<AuthBloc>().add(AuthDirectUnlock());
        // 路由守卫检测到 AuthStatus.unlocked 后自动跳转到 /home
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // 显示区域
              const Expanded(flex: 2, child: _DisplayArea()),
              // 按键区域
              const Expanded(flex: 5, child: _KeypadArea()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示区域
class _DisplayArea extends StatelessWidget {
  const _DisplayArea();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (state.expression.isNotEmpty)
                Text(
                  state.expression,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.neutral500,
                  ),
                  maxLines: 1,
                ),
              // PIN 验证中：显示区底部微妙的加载指示（不破坏计算器伪装）
              if (state.verifying)
                const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: AppColors.neutral500,
                  ),
                ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  state.display,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 按键区域
class _KeypadArea extends StatelessWidget {
  const _KeypadArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, [
          _CalcButton(label: 'C', type: _ButtonType.function, onTap: () =>
              context.read<CalculatorBloc>().add(CalcClearPressed())),
          _CalcButton(label: '±', type: _ButtonType.function, onTap: () =>
              context.read<CalculatorBloc>().add(CalcToggleSign())),
          _CalcButton(label: '%', type: _ButtonType.function, onTap: () =>
              context.read<CalculatorBloc>().add(CalcPercentPressed())),
          _CalcButton(label: '÷', type: _ButtonType.operator, onTap: () =>
              context.read<CalculatorBloc>().add(const CalcOperatorPressed('÷'))),
        ]),
        _buildRow(context, [
          _CalcButton(label: '7', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('7'))),
          _CalcButton(label: '8', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('8'))),
          _CalcButton(label: '9', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('9'))),
          _CalcButton(label: '×', type: _ButtonType.operator, onTap: () =>
              context.read<CalculatorBloc>().add(const CalcOperatorPressed('×'))),
        ]),
        _buildRow(context, [
          _CalcButton(label: '4', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('4'))),
          _CalcButton(label: '5', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('5'))),
          _CalcButton(label: '6', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('6'))),
          _CalcButton(label: '-', type: _ButtonType.operator, onTap: () =>
              context.read<CalculatorBloc>().add(const CalcOperatorPressed('-'))),
        ]),
        _buildRow(context, [
          _CalcButton(label: '1', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('1'))),
          _CalcButton(label: '2', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('2'))),
          _CalcButton(label: '3', onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('3'))),
          _CalcButton(label: '+', type: _ButtonType.operator, onTap: () =>
              context.read<CalculatorBloc>().add(const CalcOperatorPressed('+'))),
        ]),
        _buildRow(context, [
          _CalcButton(label: '0', flex: 2, onTap: () =>
              context.read<CalculatorBloc>().add(const CalcDigitPressed('0'))),
          _CalcButton(label: '.', onTap: () =>
              context.read<CalculatorBloc>().add(CalcDotPressed())),
          _CalcButton(label: '=', type: _ButtonType.equals, onTap: () =>
              context.read<CalculatorBloc>().add(CalcEqualsPressed())),
        ]),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<_CalcButton> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map((btn) => Expanded(
                  flex: btn.flex,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _CalcButtonWidget(button: btn),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

enum _ButtonType { digit, operator, function, equals }

class _CalcButton {
  final String label;
  final _ButtonType type;
  final int flex;
  final VoidCallback onTap;

  const _CalcButton({
    required this.label,
    this.type = _ButtonType.digit,
    this.flex = 1,
    required this.onTap,
  });
}

class _CalcButtonWidget extends StatelessWidget {
  final _CalcButton button;

  const _CalcButtonWidget({required this.button});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (button.type) {
      case _ButtonType.function:
        bgColor = AppColors.neutral700;
        textColor = Colors.white;
      case _ButtonType.operator:
        bgColor = AppColors.primary500;
        textColor = Colors.white;
      case _ButtonType.equals:
        bgColor = AppColors.primary500;
        textColor = Colors.white;
      case _ButtonType.digit:
        bgColor = AppColors.neutral800;
        textColor = Colors.white;
    }

    return MaterialButton(
      onPressed: button.onTap,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Text(
        button.label,
        style: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

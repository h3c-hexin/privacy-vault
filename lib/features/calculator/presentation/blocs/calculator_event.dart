import 'package:equatable/equatable.dart';

abstract class CalculatorEvent extends Equatable {
  const CalculatorEvent();
  @override
  List<Object?> get props => [];
}

/// 输入数字
class CalcDigitPressed extends CalculatorEvent {
  final String digit;
  const CalcDigitPressed(this.digit);
  @override
  List<Object?> get props => [digit];
}

/// 输入运算符
class CalcOperatorPressed extends CalculatorEvent {
  final String operator;
  const CalcOperatorPressed(this.operator);
  @override
  List<Object?> get props => [operator];
}

/// 等号（同时检测 PIN）
class CalcEqualsPressed extends CalculatorEvent {}

/// 小数点
class CalcDotPressed extends CalculatorEvent {}

/// 清除
class CalcClearPressed extends CalculatorEvent {}

/// 退格
class CalcBackspacePressed extends CalculatorEvent {}

/// 正负切换
class CalcToggleSign extends CalculatorEvent {}

/// 百分号
class CalcPercentPressed extends CalculatorEvent {}

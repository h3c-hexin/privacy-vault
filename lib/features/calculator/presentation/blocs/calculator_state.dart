import 'package:equatable/equatable.dart';

class CalculatorState extends Equatable {
  final String display;         // 当前显示内容
  final String expression;     // 完整表达式（用于上方小字显示）
  final double? firstOperand;
  final String? operator;
  final bool waitingForSecond;
  final bool pinDetected;       // 是否检测到 PIN 序列
  final bool verifying;         // PIN 验证进行中（PBKDF2 运算中）
  final String inputSequence;   // 记录输入序列（用于 PIN 检测）

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.firstOperand,
    this.operator,
    this.waitingForSecond = false,
    this.pinDetected = false,
    this.verifying = false,
    this.inputSequence = '',
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    double? firstOperand,
    String? operator,
    bool? waitingForSecond,
    bool? pinDetected,
    bool? verifying,
    String? inputSequence,
    bool clearOperator = false,
    bool clearFirstOperand = false,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      firstOperand: clearFirstOperand ? null : (firstOperand ?? this.firstOperand),
      operator: clearOperator ? null : (operator ?? this.operator),
      waitingForSecond: waitingForSecond ?? this.waitingForSecond,
      pinDetected: pinDetected ?? this.pinDetected,
      verifying: verifying ?? this.verifying,
      inputSequence: inputSequence ?? this.inputSequence,
    );
  }

  @override
  List<Object?> get props => [
        display, expression, firstOperand, operator,
        waitingForSecond, pinDetected, verifying, inputSequence,
      ];
}

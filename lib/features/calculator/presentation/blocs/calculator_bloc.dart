import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

/// 计算器 BLoC
///
/// 实现四则运算逻辑，同时暗中追踪输入序列用于 PIN 检测。
/// 当用户输入 PIN + "=" 时，通过 KeyManager 验证 PIN。
/// 为防止通过计算器路径绕过暴力破解防护，验证前会检查冷却状态，
/// 验证失败时同样更新持久化的错误计数。
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final KeyManager _keyManager;
  final FlutterSecureStorage _secureStorage;

  // 与 AuthBloc 共用相同的 SecureStorage 键名，保证状态同步
  static const String _errorCountKey = 'auth_error_count';
  static const String _cooldownUntilKey = 'auth_cooldown_until';

  // 冷却阈值（与 AuthBloc 保持一致）
  static const int _cooldown1Threshold = 5;
  static const int _cooldown2Threshold = 10;
  static const Duration _cooldown1Duration = Duration(seconds: 30);
  static const Duration _cooldown2Duration = Duration(minutes: 5);

  CalculatorBloc({
    required KeyManager keyManager,
    FlutterSecureStorage? secureStorage,
  })  : _keyManager = keyManager,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const CalculatorState()) {
    on<CalcDigitPressed>(_onDigitPressed);
    on<CalcOperatorPressed>(_onOperatorPressed);
    on<CalcEqualsPressed>(_onEqualsPressed);
    on<CalcDotPressed>(_onDotPressed);
    on<CalcClearPressed>(_onClearPressed);
    on<CalcBackspacePressed>(_onBackspacePressed);
    on<CalcToggleSign>(_onToggleSign);
    on<CalcPercentPressed>(_onPercentPressed);
  }

  /// 检查当前是否处于冷却期
  ///
  /// 从 SecureStorage 读取 cooldownUntil，与 AuthBloc 共享同一份数据。
  Future<bool> _isInCooldown() async {
    final cooldownUntilStr = await _secureStorage.read(key: _cooldownUntilKey);
    if (cooldownUntilStr == null) return false;
    final cooldownUntil = DateTime.tryParse(cooldownUntilStr);
    if (cooldownUntil == null) return false;
    return DateTime.now().isBefore(cooldownUntil);
  }

  /// PIN 验证失败时更新持久化的错误计数和冷却时间
  Future<void> _onPinVerifyFailed() async {
    final errorCountStr = await _secureStorage.read(key: _errorCountKey);
    final newErrorCount = (int.tryParse(errorCountStr ?? '') ?? 0) + 1;

    DateTime? cooldownUntil;
    if (newErrorCount >= _cooldown2Threshold) {
      cooldownUntil = DateTime.now().add(_cooldown2Duration);
    } else if (newErrorCount >= _cooldown1Threshold) {
      cooldownUntil = DateTime.now().add(_cooldown1Duration);
    }

    await _secureStorage.write(
      key: _errorCountKey,
      value: newErrorCount.toString(),
    );
    if (cooldownUntil != null) {
      await _secureStorage.write(
        key: _cooldownUntilKey,
        value: cooldownUntil.toIso8601String(),
      );
    }
  }

  void _onDigitPressed(
    CalcDigitPressed event,
    Emitter<CalculatorState> emit,
  ) {
    final newSequence = state.inputSequence + event.digit;

    if (state.waitingForSecond || state.display == '0') {
      emit(state.copyWith(
        display: event.digit,
        waitingForSecond: false,
        inputSequence: newSequence,
      ));
    } else {
      // 限制显示长度
      if (state.display.length >= 15) return;
      emit(state.copyWith(
        display: state.display + event.digit,
        inputSequence: newSequence,
      ));
    }
  }

  void _onOperatorPressed(
    CalcOperatorPressed event,
    Emitter<CalculatorState> emit,
  ) {
    final current = double.tryParse(state.display) ?? 0;

    if (state.firstOperand != null && !state.waitingForSecond) {
      // 链式运算
      final result = _calculate(state.firstOperand!, current, state.operator!);
      final displayResult = _formatResult(result);
      emit(state.copyWith(
        display: displayResult,
        expression: '$displayResult ${event.operator}',
        firstOperand: result,
        operator: event.operator,
        waitingForSecond: true,
        inputSequence: '', // 运算符重置序列
      ));
    } else {
      emit(state.copyWith(
        expression: '${state.display} ${event.operator}',
        firstOperand: current,
        operator: event.operator,
        waitingForSecond: true,
        inputSequence: '', // 运算符重置序列
      ));
    }
  }

  Future<void> _onEqualsPressed(
    CalcEqualsPressed event,
    Emitter<CalculatorState> emit,
  ) async {
    // 检测 PIN：>= 4 位且当前无验证进行中
    if (state.inputSequence.length >= 4 && !state.verifying) {
      final inCooldown = await _isInCooldown();
      if (!inCooldown) {
        emit(state.copyWith(verifying: true));
        final success = await _keyManager.unlockWithPin(state.inputSequence);
        if (success) {
          await Future.wait([
            _secureStorage.write(key: _errorCountKey, value: '0'),
            _secureStorage.delete(key: _cooldownUntilKey),
          ]);
          emit(state.copyWith(pinDetected: true, verifying: false));
          return;
        } else {
          await _onPinVerifyFailed();
          emit(state.copyWith(verifying: false));
        }
      }
    }

    if (state.firstOperand == null || state.operator == null) {
      emit(state.copyWith(inputSequence: ''));
      return;
    }

    final current = double.tryParse(state.display) ?? 0;
    final result = _calculate(state.firstOperand!, current, state.operator!);
    final displayResult = _formatResult(result);

    emit(state.copyWith(
      display: displayResult,
      expression: '',
      clearFirstOperand: true,
      clearOperator: true,
      waitingForSecond: false,
      inputSequence: '',
    ));
  }

  void _onDotPressed(
    CalcDotPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.display.contains('.')) return;

    if (state.waitingForSecond) {
      emit(state.copyWith(
        display: '0.',
        waitingForSecond: false,
      ));
    } else {
      emit(state.copyWith(display: '${state.display}.'));
    }
  }

  void _onClearPressed(
    CalcClearPressed event,
    Emitter<CalculatorState> emit,
  ) {
    emit(const CalculatorState());
  }

  void _onBackspacePressed(
    CalcBackspacePressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.display.length <= 1 || state.display == '0') {
      emit(state.copyWith(display: '0'));
    } else {
      final newDisplay = state.display.substring(0, state.display.length - 1);
      final newSequence = state.inputSequence.isNotEmpty
          ? state.inputSequence.substring(0, state.inputSequence.length - 1)
          : '';
      emit(state.copyWith(display: newDisplay, inputSequence: newSequence));
    }
  }

  void _onToggleSign(
    CalcToggleSign event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.display == '0') return;
    if (state.display.startsWith('-')) {
      emit(state.copyWith(display: state.display.substring(1)));
    } else {
      emit(state.copyWith(display: '-${state.display}'));
    }
  }

  void _onPercentPressed(
    CalcPercentPressed event,
    Emitter<CalculatorState> emit,
  ) {
    final current = double.tryParse(state.display) ?? 0;
    final result = current / 100;
    emit(state.copyWith(display: _formatResult(result)));
  }

  double _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return double.infinity;
        return a / b;
      default:
        return b;
    }
  }

  String _formatResult(double value) {
    if (value == double.infinity || value == double.negativeInfinity) {
      return '错误';
    }
    if (value.isNaN) return '错误';

    // 整数不显示小数点
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    // 最多 10 位小数
    final formatted = value.toStringAsFixed(10);
    // 去除末尾零
    return formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

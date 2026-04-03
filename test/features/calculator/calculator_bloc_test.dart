import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/security/brute_force_guard.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_bloc.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_event.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_state.dart';

class MockKeyManager extends Mock implements KeyManager {}

class MockBruteForceGuard extends Mock implements BruteForceGuard {}

void main() {
  group('CalculatorBloc', () {
    late CalculatorBloc bloc;
    late MockKeyManager mockKeyManager;
    late MockBruteForceGuard mockGuard;

    setUp(() {
      mockKeyManager = MockKeyManager();
      mockGuard = MockBruteForceGuard();
      when(() => mockKeyManager.unlockWithPin(any()))
          .thenAnswer((_) async => false);
      when(() => mockGuard.isInCooldown()).thenAnswer((_) async => false);
      when(() => mockGuard.reset()).thenAnswer((_) async {});
      when(() => mockGuard.recordFailure()).thenAnswer(
        (_) async => (errorCount: 1, cooldownUntil: null),
      );
      bloc = CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,);
    });

    tearDown(() => bloc.close());

    test('初始状态', () {
      expect(bloc.state.display, '0');
      expect(bloc.state.expression, '');
      expect(bloc.state.pinDetected, false);
    });

    blocTest<CalculatorBloc, CalculatorState>(
      '输入数字',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(const CalcDigitPressed('3'));
      },
      verify: (bloc) {
        expect(bloc.state.display, '53');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '加法运算',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(const CalcOperatorPressed('+'));
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(CalcEqualsPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '8');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '减法运算',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('9'));
        bloc.add(const CalcOperatorPressed('-'));
        bloc.add(const CalcDigitPressed('4'));
        bloc.add(CalcEqualsPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '5');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '乘法运算',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('6'));
        bloc.add(const CalcOperatorPressed('×'));
        bloc.add(const CalcDigitPressed('7'));
        bloc.add(CalcEqualsPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '42');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '除法运算',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('8'));
        bloc.add(const CalcOperatorPressed('÷'));
        bloc.add(const CalcDigitPressed('4'));
        bloc.add(CalcEqualsPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '2');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '除以零显示错误',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(const CalcOperatorPressed('÷'));
        bloc.add(const CalcDigitPressed('0'));
        bloc.add(CalcEqualsPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '错误');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '清除重置状态',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(CalcClearPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '0');
        expect(bloc.state.expression, '');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '退格删除最后一位',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('1'));
        bloc.add(const CalcDigitPressed('2'));
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(CalcBackspacePressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '12');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '退格到空显示0',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(CalcBackspacePressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '0');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '小数点输入',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(CalcDotPressed());
        bloc.add(const CalcDigitPressed('5'));
      },
      verify: (bloc) {
        expect(bloc.state.display, '3.5');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '不允许重复小数点',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(CalcDotPressed());
        bloc.add(CalcDotPressed());
        bloc.add(const CalcDigitPressed('5'));
      },
      verify: (bloc) {
        expect(bloc.state.display, '3.5');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '正负切换',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(CalcToggleSign());
      },
      verify: (bloc) {
        expect(bloc.state.display, '-5');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '百分号',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(const CalcDigitPressed('0'));
        bloc.add(CalcPercentPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '0.5');
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      'PIN 检测：正确 PIN + = 触发',
      build: () {
        when(() => mockKeyManager.unlockWithPin('1234'))
            .thenAnswer((_) async => true);
        return CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,);
      },
      act: (bloc) {
        bloc.add(const CalcDigitPressed('1'));
        bloc.add(const CalcDigitPressed('2'));
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(const CalcDigitPressed('4'));
        bloc.add(CalcEqualsPressed());
      },
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        expect(bloc.state.pinDetected, true);
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      'PIN 检测：错误 PIN 不触发',
      build: () {
        when(() => mockKeyManager.unlockWithPin('5678'))
            .thenAnswer((_) async => false);
        return CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,);
      },
      act: (bloc) {
        bloc.add(const CalcDigitPressed('5'));
        bloc.add(const CalcDigitPressed('6'));
        bloc.add(const CalcDigitPressed('7'));
        bloc.add(const CalcDigitPressed('8'));
        bloc.add(CalcEqualsPressed());
      },
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        expect(bloc.state.pinDetected, false);
      },
    );

    blocTest<CalculatorBloc, CalculatorState>(
      '链式运算',
      build: () => CalculatorBloc(keyManager: mockKeyManager, guard: mockGuard,),
      act: (bloc) {
        bloc.add(const CalcDigitPressed('2'));
        bloc.add(const CalcOperatorPressed('+'));
        bloc.add(const CalcDigitPressed('3'));
        bloc.add(const CalcOperatorPressed('×'));
        bloc.add(const CalcDigitPressed('4'));
        bloc.add(CalcEqualsPressed());
      },
      verify: (bloc) {
        expect(bloc.state.display, '20');
      },
    );
  });
}

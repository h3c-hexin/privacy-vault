import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_state.dart';

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockKeyManager mockKeyManager;

  setUp(() {
    mockKeyManager = MockKeyManager();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      '初始状态应为 initial',
      build: () => AuthBloc(keyManager: mockKeyManager),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.initial);
        expect(bloc.state.errorCount, 0);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'CheckSetup: 未设置 → needsSetup',
      setUp: () {
        when(() => mockKeyManager.isSetupComplete()).thenAnswer((_) async => false);
      },
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(AuthCheckSetup()),
      expect: () => [
        const AuthState(status: AuthStatus.needsSetup),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'CheckSetup: 已设置 → locked',
      setUp: () {
        when(() => mockKeyManager.isSetupComplete()).thenAnswer((_) async => true);
      },
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(AuthCheckSetup()),
      expect: () => [
        const AuthState(status: AuthStatus.locked),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'SetupPin: 成功 → unlocked',
      setUp: () {
        when(() => mockKeyManager.setup(any())).thenAnswer((_) async {});
      },
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(const AuthSetupPin('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.unlocked),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'UnlockWithPin: 正确 PIN → unlocked，错误计数重置',
      setUp: () {
        when(() => mockKeyManager.unlockWithPin(any())).thenAnswer((_) async => true);
      },
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(const AuthUnlockWithPin('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.unlocked),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'UnlockWithPin: 错误 PIN → 错误计数+1',
      setUp: () {
        when(() => mockKeyManager.unlockWithPin(any())).thenAnswer((_) async => false);
      },
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(const AuthUnlockWithPin('9999')),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.errorCount, 'errorCount', 1)
            .having((s) => s.errorMessage, 'errorMessage', '密码错误'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'UnlockWithPin: 连续 5 次错误 → 30 秒冷却',
      setUp: () {
        when(() => mockKeyManager.unlockWithPin(any())).thenAnswer((_) async => false);
      },
      seed: () => const AuthState(errorCount: 4),
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(const AuthUnlockWithPin('9999')),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.errorCount, 'errorCount', 5)
            .having((s) => s.cooldownUntil, 'cooldownUntil', isNotNull),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Lock: unlocked → locked',
      setUp: () {
        when(() => mockKeyManager.lock()).thenReturn(null);
      },
      seed: () => const AuthState(status: AuthStatus.unlocked),
      build: () => AuthBloc(keyManager: mockKeyManager),
      act: (bloc) => bloc.add(AuthLock()),
      expect: () => [
        const AuthState(status: AuthStatus.locked),
      ],
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_vault/core/security/brute_force_guard.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late BruteForceGuard guard;

  setUp(() {
    mockStorage = MockSecureStorage();
    guard = BruteForceGuard(secureStorage: mockStorage);
  });

  group('loadErrorCount', () {
    test('无记录时返回 0', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => null);
      expect(await guard.loadErrorCount(), 0);
    });

    test('有记录时返回正确值', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => '3');
      expect(await guard.loadErrorCount(), 3);
    });

    test('非法值时返回 0', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => 'abc');
      expect(await guard.loadErrorCount(), 0);
    });
  });

  group('loadCooldownUntil', () {
    test('无记录时返回 null', () async {
      when(() => mockStorage.read(key: 'auth_cooldown_until'))
          .thenAnswer((_) async => null);
      expect(await guard.loadCooldownUntil(), isNull);
    });

    test('有记录时返回正确时间', () async {
      final time = DateTime(2026, 4, 3, 12, 0, 0);
      when(() => mockStorage.read(key: 'auth_cooldown_until'))
          .thenAnswer((_) async => time.toIso8601String());
      expect(await guard.loadCooldownUntil(), time);
    });

    test('非法值时返回 null', () async {
      when(() => mockStorage.read(key: 'auth_cooldown_until'))
          .thenAnswer((_) async => 'not-a-date');
      expect(await guard.loadCooldownUntil(), isNull);
    });
  });

  group('isInCooldown', () {
    test('无冷却记录时返回 false', () async {
      when(() => mockStorage.read(key: 'auth_cooldown_until'))
          .thenAnswer((_) async => null);
      expect(await guard.isInCooldown(), false);
    });

    test('冷却已过期时返回 false', () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
      when(() => mockStorage.read(key: 'auth_cooldown_until'))
          .thenAnswer((_) async => pastTime.toIso8601String());
      expect(await guard.isInCooldown(), false);
    });

    test('冷却未过期时返回 true', () async {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      when(() => mockStorage.read(key: 'auth_cooldown_until'))
          .thenAnswer((_) async => futureTime.toIso8601String());
      expect(await guard.isInCooldown(), true);
    });
  });

  group('recordFailure', () {
    setUp(() {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
    });

    test('首次失败：errorCount=1，无冷却', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => null);

      final result = await guard.recordFailure();

      expect(result.errorCount, 1);
      expect(result.cooldownUntil, isNull);
      verify(() => mockStorage.write(key: 'auth_error_count', value: '1')).called(1);
    });

    test('第 5 次失败：触发 30 秒冷却', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => '4');

      final before = DateTime.now();
      final result = await guard.recordFailure();
      final after = DateTime.now();

      expect(result.errorCount, 5);
      expect(result.cooldownUntil, isNotNull);
      // 冷却时间应约为 30 秒后
      expect(
        result.cooldownUntil!.isAfter(before.add(const Duration(seconds: 29))),
        true,
      );
      expect(
        result.cooldownUntil!.isBefore(after.add(const Duration(seconds: 31))),
        true,
      );
      verify(() => mockStorage.write(key: 'auth_cooldown_until', value: any(named: 'value')))
          .called(1);
    });

    test('第 10 次失败：触发 5 分钟冷却', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => '9');

      final before = DateTime.now();
      final result = await guard.recordFailure();

      expect(result.errorCount, 10);
      expect(result.cooldownUntil, isNotNull);
      expect(
        result.cooldownUntil!.isAfter(before.add(const Duration(minutes: 4, seconds: 59))),
        true,
      );
    });

    test('未达阈值时不写入冷却时间', () async {
      when(() => mockStorage.read(key: 'auth_error_count'))
          .thenAnswer((_) async => '2');

      await guard.recordFailure();

      verify(() => mockStorage.write(key: 'auth_error_count', value: '3')).called(1);
      verifyNever(() => mockStorage.write(key: 'auth_cooldown_until', value: any(named: 'value')));
    });
  });

  group('reset', () {
    test('清除错误计数并删除冷却记录', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await guard.reset();

      verify(() => mockStorage.write(key: 'auth_error_count', value: '0')).called(1);
      verify(() => mockStorage.delete(key: 'auth_cooldown_until')).called(1);
    });
  });
}

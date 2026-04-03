import 'dart:ffi';
import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_bloc.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_event.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_state.dart';

void main() {
  // 确保测试环境能找到 sqlite3 动态库
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () {
      return DynamicLibrary.open('libsqlite3.so.0');
    });
  });

  group('VaultBloc', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    blocTest<VaultBloc, VaultState>(
      '加载空文件夹列表',
      build: () => VaultBloc(database: db),
      act: (bloc) => bloc.add(VaultLoadFolders()),
      expect: () => [
        isA<VaultState>().having((s) => s.status, 'status', VaultStatus.loading),
        isA<VaultState>()
            .having((s) => s.status, 'status', VaultStatus.loaded)
            .having((s) => s.folders, 'folders', isEmpty),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      '创建文件夹后加载',
      build: () => VaultBloc(database: db),
      act: (bloc) async {
        bloc.add(const VaultCreateFolder('测试文件夹'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        expect(bloc.state.folders.length, 1);
        expect(bloc.state.folders.first.name, '测试文件夹');
      },
    );

    blocTest<VaultBloc, VaultState>(
      '重命名文件夹',
      build: () => VaultBloc(database: db),
      seed: () => const VaultState(status: VaultStatus.loaded),
      act: (bloc) async {
        bloc.add(const VaultCreateFolder('原名称'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final folderId = bloc.state.folders.first.id;
        bloc.add(VaultRenameFolder(folderId, '新名称'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      wait: const Duration(milliseconds: 600),
      verify: (bloc) {
        expect(bloc.state.folders.length, 1);
        expect(bloc.state.folders.first.name, '新名称');
      },
    );

    blocTest<VaultBloc, VaultState>(
      '删除文件夹',
      build: () => VaultBloc(database: db),
      act: (bloc) async {
        bloc.add(const VaultCreateFolder('待删除'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final folderId = bloc.state.folders.first.id;
        bloc.add(VaultDeleteFolder(folderId));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      wait: const Duration(milliseconds: 600),
      verify: (bloc) {
        expect(bloc.state.folders, isEmpty);
      },
    );

    blocTest<VaultBloc, VaultState>(
      '加载文件夹内文件（空）',
      build: () => VaultBloc(database: db),
      act: (bloc) async {
        bloc.add(const VaultCreateFolder('文件夹'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final folderId = bloc.state.folders.first.id;
        bloc.add(VaultLoadFiles(folderId));
      },
      wait: const Duration(milliseconds: 400),
      verify: (bloc) {
        expect(bloc.state.files, isEmpty);
        expect(bloc.state.currentFolderId, isNotNull);
      },
    );

    test('创建多个文件夹保持排序', () async {
      final bloc = VaultBloc(database: db);
      bloc.add(const VaultCreateFolder('A'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      bloc.add(const VaultCreateFolder('B'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      bloc.add(const VaultCreateFolder('C'));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(bloc.state.folders.length, 3);
      await bloc.close();
    });
  });
}

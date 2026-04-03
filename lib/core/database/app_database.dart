import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

part 'app_database.g.dart';

/// 文件夹表
class VaultFolders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get iconName => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 文件表
class VaultFiles extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().references(VaultFolders, #id)();
  TextColumn get originalName => text()();
  TextColumn get fileType => text()(); // image, video, document, other
  TextColumn get mimeType => text()();
  TextColumn get encryptedPath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get fileSize => integer()();
  IntColumn get encryptedSize => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get encryptedDek => text()();
  TextColumn get dekIv => text()();
  TextColumn get fileIv => text()();
  IntColumn get chunkCount => integer().withDefault(const Constant(1))();
  TextColumn get checksum => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get originalFolderId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 入侵记录表
class IntrusionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get photoPath => text()();
  TextColumn get encryptedDek => text()();
  TextColumn get dekIv => text()();
  TextColumn get photoIv => text()();
  IntColumn get timestamp => integer()();
  IntColumn get attemptCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 设置表
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [VaultFolders, VaultFiles, IntrusionRecords, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String dbKey) : super(_openConnection(dbKey));

  // 测试用构造函数（内存数据库，无加密）
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ============================================================
  // Folder 操作
  // ============================================================
  Future<List<VaultFolder>> getAllFolders() =>
      (select(vaultFolders)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Stream<List<VaultFolder>> watchAllFolders() =>
      (select(vaultFolders)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<void> insertFolder(VaultFoldersCompanion folder) =>
      into(vaultFolders).insert(folder);

  Future<void> updateFolder(VaultFoldersCompanion folder) =>
      (update(vaultFolders)..where((t) => t.id.equals(folder.id.value)))
          .write(folder);

  Future<VaultFolder?> getFolderById(String id) =>
      (select(vaultFolders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteFolder(String id) =>
      (delete(vaultFolders)..where((t) => t.id.equals(id))).go();

  // ============================================================
  // File 操作
  // ============================================================
  Future<List<VaultFile>> getFilesByFolder(String folderId) =>
      (select(vaultFiles)
            ..where((t) => t.folderId.equals(folderId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<VaultFile>> watchFilesByFolder(String folderId) =>
      (select(vaultFiles)
            ..where((t) => t.folderId.equals(folderId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<VaultFile>> getFilesByType(String fileType) =>
      (select(vaultFiles)
            ..where((t) => t.fileType.equals(fileType) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<VaultFile?> getFileById(String id) =>
      (select(vaultFiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertFile(VaultFilesCompanion file) =>
      into(vaultFiles).insert(file);

  Future<void> updateFile(VaultFilesCompanion file) =>
      (update(vaultFiles)..where((t) => t.id.equals(file.id.value))).write(file);

  /// 软删除（移入回收站）
  Future<void> softDeleteFile(String id, String originalFolderId) =>
      (update(vaultFiles)..where((t) => t.id.equals(id))).write(
        VaultFilesCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
          originalFolderId: Value(originalFolderId),
        ),
      );

  /// 恢复文件
  ///
  /// 如果原文件夹已被删除，自动创建"已恢复文件"文件夹。
  Future<void> restoreFile(String id) async {
    final file = await getFileById(id);
    if (file == null) return;

    final targetFolderId = file.originalFolderId ?? file.folderId;

    // 检查目标文件夹是否仍然存在
    final folder = await getFolderById(targetFolderId);
    String restoreTo = targetFolderId;

    if (folder == null) {
      // 原文件夹已删除，查找或创建"已恢复文件"文件夹
      restoreTo = await _getOrCreateRecoveryFolder();
    }

    await (update(vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(
        isDeleted: const Value(false),
        deletedAt: const Value(null),
        folderId: Value(restoreTo),
        originalFolderId: const Value(null),
      ),
    );
  }

  /// 查找或创建"已恢复文件"默认文件夹
  static const _recoveryFolderName = '已恢复文件';

  Future<String> _getOrCreateRecoveryFolder() async {
    // 先查找是否已存在
    final existing = await (select(vaultFolders)
          ..where((t) => t.name.equals(_recoveryFolderName)))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    // 创建新的
    final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(vaultFolders).insert(VaultFoldersCompanion(
      id: Value(id),
      name: const Value(_recoveryFolderName),
      sortOrder: const Value(9999),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    return id;
  }

  /// 获取回收站文件
  Future<List<VaultFile>> getDeletedFiles() =>
      (select(vaultFiles)
            ..where((t) => t.isDeleted.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
          .get();

  /// 彻底删除
  Future<void> permanentDeleteFile(String id) =>
      (delete(vaultFiles)..where((t) => t.id.equals(id))).go();

  /// 清理过期回收站文件（30 天）
  Future<List<VaultFile>> getExpiredDeletedFiles() {
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    return (select(vaultFiles)
          ..where(
            (t) => t.isDeleted.equals(true) & t.deletedAt.isSmallerThanValue(thirtyDaysAgo),
          ))
        .get();
  }

  /// 修复孤儿文件（folderId 指向已删除文件夹的文件）→ 移入回收站
  Future<int> fixOrphanedFiles() async {
    final allFiles = await (select(vaultFiles)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final allFolderIds =
        (await getAllFolders()).map((f) => f.id).toSet();

    var count = 0;
    for (final file in allFiles) {
      if (!allFolderIds.contains(file.folderId)) {
        await softDeleteFile(file.id, file.folderId);
        count++;
      }
    }
    return count;
  }

  /// 统计文件总大小
  Future<int> getTotalEncryptedSize() async {
    final query = selectOnly(vaultFiles)
      ..addColumns([vaultFiles.encryptedSize.sum()])
      ..where(vaultFiles.isDeleted.equals(false));
    final result = await query.getSingle();
    return result.read(vaultFiles.encryptedSize.sum()) ?? 0;
  }

  /// 统计文件夹内文件数
  Future<int> getFileCountInFolder(String folderId) async {
    final query = selectOnly(vaultFiles)
      ..addColumns([vaultFiles.id.count()])
      ..where(vaultFiles.folderId.equals(folderId) & vaultFiles.isDeleted.equals(false));
    final result = await query.getSingle();
    return result.read(vaultFiles.id.count()) ?? 0;
  }

  // ============================================================
  // Intrusion 操作
  // ============================================================
  Future<List<IntrusionRecord>> getAllIntrusionRecords() =>
      (select(intrusionRecords)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).get();

  Future<void> insertIntrusionRecord(IntrusionRecordsCompanion record) =>
      into(intrusionRecords).insert(record);

  Future<void> deleteIntrusionRecord(String id) =>
      (delete(intrusionRecords)..where((t) => t.id.equals(id))).go();

  // ============================================================
  // Settings 操作
  // ============================================================
  Future<String?> getSetting(String key) async {
    final result =
        await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion(
          key: Value(key),
          value: Value(value),
        ),
      );
}

/// 将 Base64 密钥转为 SQLCipher 原始密钥格式 "x'<hex>'"
String _toRawKeyPragma(String base64Key) {
  final bytes = base64Decode(base64Key);
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return "x'$hex'";
}

LazyDatabase _openConnection(String dbKey) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'privacy_vault.db'));

    // 使用原始密钥格式，避免字符串插值注入 + 跳过 PBKDF2 直接使用完整熵
    final rawKey = _toRawKeyPragma(dbKey);

    return NativeDatabase.createInBackground(
      file,
      // isolateSetup 在后台 isolate 中执行，确保 SQLCipher 库正确加载
      isolateSetup: () {
        sqlite_open.open.overrideFor(
          sqlite_open.OperatingSystem.android,
          openCipherOnAndroid,
        );
      },
      setup: (db) {
        db.execute('PRAGMA key = "$rawKey"');

        // 验证 SQLCipher 已正确加载
        final result = db.select('PRAGMA cipher_version');
        if (result.isEmpty) {
          throw StateError(
            '数据库加密验证失败：SQLCipher 未正确加载，数据可能以明文存储',
          );
        }
      },
    );
  });
}

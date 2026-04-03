import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// 临时文件管理器
///
/// 管理解密后的临时文件生命周期，确保预览/分享后及时清理。
/// 使用系统缓存目录（不被媒体扫描），文件名使用 UUID 防止路径预测。
/// 所有删除操作均先零字节覆写再删除，降低磁盘残留取证风险。
class TempFileManager {
  static const _tempDirName = 'vault_temp';
  static const _uuid = Uuid();

  /// 获取临时目录（使用系统缓存目录）
  Future<Directory> get tempDir async {
    final cacheDir = await getTemporaryDirectory();
    final dir = Directory(p.join(cacheDir.path, _tempDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 创建随机临时文件路径（防止路径预测）
  Future<String> getTempPath(String originalFileName) async {
    final dir = await tempDir;
    final ext = p.extension(originalFileName);
    return p.join(dir.path, '${_uuid.v4()}$ext');
  }

  /// 安全清理单个临时文件
  Future<void> cleanFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await _secureDelete(file);
    }
  }

  /// 清理所有临时文件（并发执行）
  Future<void> cleanAll() async {
    final dir = await tempDir;
    if (await dir.exists()) {
      final entities = await dir.list().toList();
      await Future.wait(entities.map((e) =>
        e is File ? _secureDelete(e) : e.delete(recursive: true),
      ));
    }
  }

  /// 清理超过指定时间的临时文件
  Future<int> cleanExpired({Duration maxAge = const Duration(hours: 1)}) async {
    final dir = await tempDir;
    if (!await dir.exists()) return 0;

    int cleaned = 0;
    final cutoff = DateTime.now().subtract(maxAge);
    final entities = await dir.list().toList();

    for (final entity in entities) {
      final stat = await entity.stat();
      if (stat.modified.isBefore(cutoff)) {
        if (entity is File) {
          await _secureDelete(entity);
        } else {
          await entity.delete(recursive: true);
        }
        cleaned++;
      }
    }
    return cleaned;
  }

  /// 零字节覆写后删除，降低取证恢复风险
  Future<void> _secureDelete(File file) async {
    try {
      final length = await file.length();
      await file.writeAsBytes(Uint8List(length));
    } catch (_) {}
    try {
      await file.delete();
    } catch (_) {}
  }
}

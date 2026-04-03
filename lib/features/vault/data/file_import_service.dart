import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// 待导入文件信息
class ImportFileInfo {
  final String path;
  final String name;
  final String mimeType;
  final String fileType; // image, video, other
  final int size;

  const ImportFileInfo({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.fileType,
    required this.size,
  });
}

/// 文件导入服务
///
/// 负责从相册/文件系统选择文件，并提供删除原文件的能力。
class FileImportService {
  static const _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif',
  };
  static const _videoExtensions = {
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp', '.flv',
  };

  /// 从文件系统选择文件（图片和视频）
  Future<List<ImportFileInfo>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
        'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'flv',
      ],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    return result.files
        .where((f) => f.path != null)
        .map((f) => _toImportFileInfo(f.path!, f.name, f.size))
        .toList();
  }

  /// 仅选择图片
  Future<List<ImportFileInfo>> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    return result.files
        .where((f) => f.path != null)
        .map((f) => _toImportFileInfo(f.path!, f.name, f.size))
        .toList();
  }

  /// 仅选择视频
  Future<List<ImportFileInfo>> pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    return result.files
        .where((f) => f.path != null)
        .map((f) => _toImportFileInfo(f.path!, f.name, f.size))
        .toList();
  }

  /// 删除原文件
  ///
  /// 导入完成后调用，删除原始文件。
  /// 注意：仅能删除应用缓存目录中的文件（file_picker 复制到缓存的文件）。
  /// 对于 SAF 选择的原始文件，需要用户手动删除。
  Future<bool> deleteSourceFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 批量删除缓存中的源文件
  Future<void> cleanPickerCache() async {
    await FilePicker.platform.clearTemporaryFiles();
  }

  /// 判断文件类型
  static String classifyFileType(String path) {
    final ext = p.extension(path).toLowerCase();
    if (_imageExtensions.contains(ext)) return 'image';
    if (_videoExtensions.contains(ext)) return 'video';
    return 'other';
  }

  ImportFileInfo _toImportFileInfo(String path, String name, int size) {
    final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
    final fileType = classifyFileType(path);
    return ImportFileInfo(
      path: path,
      name: name,
      mimeType: mimeType,
      fileType: fileType,
      size: size,
    );
  }
}

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/di/injection.dart';

/// 加密缩略图 LRU 缓存（按内存大小淘汰）
///
/// 全局单例，缓存解密后的缩略图字节，避免重复解密。
/// 内存上限 50MB，按实际字节数淘汰最久未使用的条目。
class ThumbnailCache {
  ThumbnailCache._();
  static final instance = ThumbnailCache._();

  static const int _maxBytes = 50 * 1024 * 1024; // 50MB
  final _cache = LinkedHashMap<String, Uint8List>();
  int _currentBytes = 0;

  Uint8List? get(String key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // 移到末尾（最近使用）
    }
    return value;
  }

  void put(String key, Uint8List value) {
    // 如果已存在，先减去旧值大小
    final old = _cache.remove(key);
    if (old != null) _currentBytes -= old.length;

    // 淘汰最久未使用的条目直到有足够空间
    while (_currentBytes + value.length > _maxBytes && _cache.isNotEmpty) {
      final evicted = _cache.remove(_cache.keys.first);
      if (evicted != null) _currentBytes -= evicted.length;
    }

    _cache[key] = value;
    _currentBytes += value.length;
  }

  void clear() {
    _cache.clear();
    _currentBytes = 0;
  }
}

/// 全局解密并发限制
///
/// 限制同时进行的缩略图解密操作数量，避免快速滚动时
/// 大量并发 I/O + 解密导致 CPU/IO 饱和。
class _DecryptSemaphore {
  _DecryptSemaphore._();
  static final instance = _DecryptSemaphore._();

  static const int _maxConcurrent = 4;
  int _running = 0;
  final _queue = <Completer<void>>[];

  Future<void> acquire() async {
    if (_running < _maxConcurrent) {
      _running++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    } else {
      _running--;
    }
  }
}

/// 加密缩略图组件
///
/// 异步解密缩略图并显示，支持 LRU 内存缓存。
/// 缩略图体积小（~30KB），直接在主 Isolate 解密，避免跨 Isolate 传输开销。
class EncryptedThumbnail extends StatefulWidget {
  final String? thumbnailPath;
  final String encryptedDek;
  final String fileType;

  const EncryptedThumbnail({
    super.key,
    required this.thumbnailPath,
    required this.encryptedDek,
    required this.fileType,
  });

  @override
  State<EncryptedThumbnail> createState() => _EncryptedThumbnailState();
}

class _EncryptedThumbnailState extends State<EncryptedThumbnail> {
  Uint8List? _bytes;
  bool _loading = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(EncryptedThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailPath != widget.thumbnailPath) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.thumbnailPath == null || widget.thumbnailPath!.isEmpty) return;

    final generation = ++_loadGeneration;
    final cacheKey = widget.thumbnailPath!;

    // 查缓存（命中则跳过解密）
    final cached = ThumbnailCache.instance.get(cacheKey);
    if (cached != null) {
      if (mounted) setState(() { _bytes = cached; _loading = false; });
      return;
    }

    if (mounted) setState(() => _loading = true);

    // 获取信号量许可，限制并发解密数
    await _DecryptSemaphore.instance.acquire();
    try {
      // 检查是否已过期（widget dispose 或路径变更触发了新的加载）
      if (!mounted || generation != _loadGeneration) return;

      // 再次检查缓存（可能在排队期间被其他实例解密）
      final rechecked = ThumbnailCache.instance.get(cacheKey);
      if (rechecked != null) {
        if (mounted) setState(() { _bytes = rechecked; _loading = false; });
        return;
      }

      final file = File(cacheKey);
      if (!await file.exists()) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (generation != _loadGeneration) return;

      final keyManager = getIt<KeyManager>();
      if (!keyManager.isUnlocked) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final encryptedDekBytes = base64Decode(widget.encryptedDek);
      final dek = keyManager.decryptDek(encryptedDekBytes);

      final encryptedBytes = await file.readAsBytes();
      if (generation != _loadGeneration) {
        for (var i = 0; i < dek.length; i++) dek[i] = 0;
        return;
      }

      final engine = CryptoEngine();
      final decrypted = engine.decrypt(encryptedBytes, dek);

      // 覆写 DEK
      for (var i = 0; i < dek.length; i++) {
        dek[i] = 0;
      }

      // 即使 generation 过期，也存入缓存（其他 widget 可能需要）
      ThumbnailCache.instance.put(cacheKey, decrypted);

      if (mounted && generation == _loadGeneration) {
        setState(() {
          _bytes = decrypted;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    } finally {
      _DecryptSemaphore.instance.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        cacheWidth: 300,
        gaplessPlayback: true,
      );
    }

    if (_loading) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    // 无缩略图或解密失败，显示占位图标
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          widget.fileType == 'video'
              ? Icons.videocam_outlined
              : Icons.image_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

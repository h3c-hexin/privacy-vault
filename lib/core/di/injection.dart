import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_vault/core/crypto/crypto_engine.dart';
import 'package:privacy_vault/core/crypto/chunk_encryptor.dart';
import 'package:privacy_vault/core/crypto/key_derivation.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/crypto/keystore_service.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/security/brute_force_guard.dart';
import 'package:privacy_vault/core/security/session_manager.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';
import 'package:privacy_vault/core/storage/temp_file_manager.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_bloc.dart';
import 'package:privacy_vault/features/intrusion/data/intrusion_capture_service.dart';
import 'package:privacy_vault/features/intrusion/presentation/blocs/intrusion_bloc.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_bloc.dart';
import 'package:privacy_vault/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:privacy_vault/features/trash/presentation/blocs/trash_bloc.dart';
import 'package:privacy_vault/features/vault/data/file_import_service.dart';
import 'package:privacy_vault/features/vault/data/thumbnail_service.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_bloc.dart';

final getIt = GetIt.instance;

const _dbKeyStorageKey = 'db_encryption_key';

/// 初始化依赖注入（异步，需要读取/生成数据库密钥）
Future<void> configureDependencies() async {
  // Crypto
  getIt.registerLazySingleton<CryptoEngine>(() => CryptoEngine());
  getIt.registerLazySingleton<ChunkEncryptor>(
    () => ChunkEncryptor(engine: getIt<CryptoEngine>()),
  );
  getIt.registerLazySingleton<KeyDerivation>(() => KeyDerivation());
  getIt.registerLazySingleton<KeystoreService>(() => KeystoreService());
  getIt.registerLazySingleton<KeyManager>(
    () => KeyManager(
      cryptoEngine: getIt<CryptoEngine>(),
      keyDerivation: getIt<KeyDerivation>(),
      keystoreService: getIt<KeystoreService>(),
    ),
  );

  // Database（SQLCipher 加密）
  final dbKey = await _getOrCreateDbKey();
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase(dbKey));

  // Storage
  getIt.registerLazySingleton<EncryptedFileStorage>(
    () => EncryptedFileStorage(
      cryptoEngine: getIt<CryptoEngine>(),
      chunkEncryptor: getIt<ChunkEncryptor>(),
      keyManager: getIt<KeyManager>(),
    ),
  );

  // Import
  getIt.registerLazySingleton<FileImportService>(() => FileImportService());
  getIt.registerLazySingleton<ThumbnailService>(
    () => ThumbnailService(
      cryptoEngine: getIt<CryptoEngine>(),
      keyManager: getIt<KeyManager>(),
      fileStorage: getIt<EncryptedFileStorage>(),
    ),
  );

  // Temp File Manager
  getIt.registerLazySingleton<TempFileManager>(() => TempFileManager());

  // Intrusion Capture
  getIt.registerLazySingleton<IntrusionCaptureService>(
    () => IntrusionCaptureService(
      cryptoEngine: getIt<CryptoEngine>(),
      keyManager: getIt<KeyManager>(),
      fileStorage: getIt<EncryptedFileStorage>(),
      database: getIt<AppDatabase>(),
    ),
  );

  // Security
  getIt.registerLazySingleton<BruteForceGuard>(() => BruteForceGuard());
  getIt.registerLazySingleton<SessionManager>(
    () => SessionManager(keyManager: getIt<KeyManager>()),
  );

  // --- BLoC（factory：每次从路由或 BlocProvider 创建时生成新实例）---

  /// AuthBloc：管理解锁/锁定状态，应用生命周期内只有一个实例，
  /// 由 app.dart 手动创建并通过 BlocProvider.value 注入，此处仅注册
  /// factory 供需要时获取（如测试或未来的懒加载场景）。
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      keyManager: getIt<KeyManager>(),
      intrusionCapture: getIt<IntrusionCaptureService>(),
      database: getIt<AppDatabase>(),
      guard: getIt<BruteForceGuard>(),
    ),
  );

  /// VaultBloc：管理文件夹列表与文件操作，每次进入主页时创建。
  getIt.registerFactory<VaultBloc>(
    () => VaultBloc(database: getIt<AppDatabase>()),
  );

  /// TrashBloc：管理回收站文件列表，每次进入回收站页面时创建。
  getIt.registerFactory<TrashBloc>(
    () => TrashBloc(
      database: getIt<AppDatabase>(),
      fileStorage: getIt<EncryptedFileStorage>(),
    ),
  );

  /// PreviewBloc：管理加密文件解密预览，每次打开预览页面时创建。
  /// fileId 通过事件（PreviewLoadFile）传入，无需构造参数。
  getIt.registerFactory<PreviewBloc>(
    () => PreviewBloc(
      database: getIt<AppDatabase>(),
      fileStorage: getIt<EncryptedFileStorage>(),
      tempManager: getIt<TempFileManager>(),
    ),
  );

  /// SettingsBloc：管理应用设置，每次进入设置页面时创建。
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      database: getIt<AppDatabase>(),
      sessionManager: getIt<SessionManager>(),
    ),
  );

  /// CalculatorBloc：管理计算器界面及 PIN 隐藏入口，每次进入计算器页面时创建。
  getIt.registerFactory<CalculatorBloc>(
    () => CalculatorBloc(
      keyManager: getIt<KeyManager>(),
      guard: getIt<BruteForceGuard>(),
    ),
  );

  /// IntrusionBloc：管理入侵拍照记录，每次进入入侵记录页面时创建。
  getIt.registerFactory<IntrusionBloc>(
    () => IntrusionBloc(database: getIt<AppDatabase>()),
  );
}

/// 获取或生成数据库加密密钥
///
/// 密钥存储在 flutter_secure_storage（Android Keystore 保护）中，
/// 首次启动时随机生成 32 字节密钥。
Future<String> _getOrCreateDbKey() async {
  const storage = FlutterSecureStorage();
  var key = await storage.read(key: _dbKeyStorageKey);
  if (key == null) {
    // 首次启动，生成随机密钥
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    key = base64Encode(bytes);
    await storage.write(key: _dbKeyStorageKey, value: key);
  }
  return key;
}

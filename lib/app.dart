import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/security/session_manager.dart';
import 'package:privacy_vault/core/theme/app_theme.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_event.dart';
import 'package:privacy_vault/features/auth/presentation/blocs/auth_state.dart';
import 'package:privacy_vault/features/auth/presentation/pages/onboarding_page.dart';
import 'package:privacy_vault/features/auth/presentation/pages/unlock_page.dart';
import 'package:privacy_vault/features/vault/presentation/pages/home_page.dart';
import 'package:privacy_vault/features/vault/presentation/pages/folder_detail_page.dart';
import 'package:privacy_vault/features/vault/presentation/pages/import_page.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/import_bloc.dart';
import 'package:privacy_vault/features/vault/data/file_import_service.dart';
import 'package:privacy_vault/features/vault/data/thumbnail_service.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_bloc.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_event.dart';
import 'package:privacy_vault/features/preview/presentation/pages/image_preview_page.dart';
import 'package:privacy_vault/features/preview/presentation/pages/video_player_page.dart';
import 'package:privacy_vault/features/trash/presentation/blocs/trash_bloc.dart';
import 'package:privacy_vault/features/trash/presentation/blocs/trash_event.dart';
import 'package:privacy_vault/features/trash/presentation/pages/trash_page.dart';
import 'package:privacy_vault/features/calculator/presentation/blocs/calculator_bloc.dart';
import 'package:privacy_vault/features/calculator/presentation/pages/calculator_page.dart';
import 'package:privacy_vault/features/settings/presentation/pages/settings_page.dart';
import 'package:privacy_vault/features/settings/presentation/pages/change_password_page.dart';
import 'package:privacy_vault/features/settings/presentation/pages/donate_page.dart';
// ScreenSecureMixin 在各敏感页面中直接使用，无需在路由层引入
import 'package:privacy_vault/features/settings/presentation/pages/about_page.dart';
import 'package:privacy_vault/features/settings/presentation/pages/legal_page.dart';
import 'package:privacy_vault/features/intrusion/data/intrusion_capture_service.dart';
import 'package:privacy_vault/features/intrusion/presentation/blocs/intrusion_bloc.dart';
import 'package:privacy_vault/features/intrusion/presentation/blocs/intrusion_event.dart';
import 'package:privacy_vault/features/intrusion/presentation/pages/intrusion_page.dart';

/// 将 AuthBloc stream 转为 Listenable 供 GoRouter 使用
class _AuthStateListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _AuthStateListenable(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class PrivacyVaultApp extends StatefulWidget {
  const PrivacyVaultApp({super.key});

  @override
  State<PrivacyVaultApp> createState() => _PrivacyVaultAppState();
}

class _PrivacyVaultAppState extends State<PrivacyVaultApp> {
  late final AuthBloc _authBloc;
  late final SessionManager _sessionManager;
  late final _AuthStateListenable _authListenable;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(
      keyManager: getIt<KeyManager>(),
      intrusionCapture: getIt<IntrusionCaptureService>(),
      database: getIt<AppDatabase>(),
    )..add(AuthCheckSetup());
    _authListenable = _AuthStateListenable(_authBloc);
    _router = _createRouter();

    // 启用自动锁定（读取持久化的锁定时间）
    _sessionManager = getIt<SessionManager>();
    _initAutoLockDelay();
    _sessionManager.onLocked = () => _authBloc.add(AuthLock());
    _sessionManager.start();
  }

  Future<void> _initAutoLockDelay() async {
    final db = getIt<AppDatabase>();

    // 修复之前因删文件夹产生的孤儿文件（移入回收站）
    await db.fixOrphanedFiles();

    final autoLockStr = await db.getSetting('auto_lock_seconds');
    final seconds = int.tryParse(autoLockStr ?? '') ?? 30;
    _sessionManager.setAutoLockDelay(Duration(seconds: seconds));
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    _authListenable.dispose();
    _authBloc.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: '计算器', // 伪装名称
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: _authListenable,
      redirect: (context, state) {
        final path = state.matchedLocation;
        final authState = _authBloc.state;

        switch (authState.status) {
          case AuthStatus.initial:
            return null;
          case AuthStatus.needsSetup:
            if (path != '/setup') return '/setup';
          case AuthStatus.locked:
            if (path != '/unlock' && path != '/calculator') {
              return '/calculator';
            }
          case AuthStatus.unlocked:
            if (path == '/setup' || path == '/unlock' ||
                path == '/calculator' || path == '/') {
              return '/home';
            }
          case AuthStatus.error:
            return null;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(
          path: '/setup',
          pageBuilder: (context, state) => _fadePage(state, const OnboardingPage()),
        ),
        GoRoute(
          path: '/unlock',
          pageBuilder: (context, state) => _fadePage(state, const UnlockPage()),
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _fadePage(state, const HomePage()),
        ),
        GoRoute(
          path: '/calculator',
          pageBuilder: (context, state) => _fadePage(
            state,
            Theme(
              data: AppTheme.dark,
              child: BlocProvider(
                // 从 DI 获取 CalculatorBloc factory 实例
                create: (_) => getIt<CalculatorBloc>(),
                child: const CalculatorPage(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/folder/:id',
          pageBuilder: (context, state) => _slidePage(
            state,
            FolderDetailPage(folderId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/import/:folderId',
          pageBuilder: (context, state) {
            final folderId = state.pathParameters['folderId']!;
            return _slidePage(
              state,
              BlocProvider(
                // ImportBloc 需要运行时参数（folderId），保持手动构造
                create: (_) => ImportBloc(
                  importService: getIt<FileImportService>(),
                  fileStorage: getIt<EncryptedFileStorage>(),
                  thumbnailService: getIt<ThumbnailService>(),
                  database: getIt<AppDatabase>(),
                ),
                child: ImportPage(folderId: folderId),
              ),
            );
          },
        ),
        GoRoute(
          path: '/preview/image/:fileId',
          pageBuilder: (context, state) {
            final fileId = state.pathParameters['fileId']!;
            return _fadePage(
              state,
              BlocProvider(
                // 从 DI 获取 PreviewBloc factory 实例，fileId 通过事件传入
                create: (_) => getIt<PreviewBloc>()..add(PreviewLoadFile(fileId)),
                child: const ImagePreviewPage(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/preview/video/:fileId',
          pageBuilder: (context, state) {
            final fileId = state.pathParameters['fileId']!;
            return _fadePage(
              state,
              BlocProvider(
                // 从 DI 获取 PreviewBloc factory 实例，fileId 通过事件传入
                create: (_) => getIt<PreviewBloc>()..add(PreviewLoadFile(fileId)),
                child: const VideoPlayerPage(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/trash',
          pageBuilder: (context, state) => _slidePage(
            state,
            BlocProvider(
              // 从 DI 获取 TrashBloc factory 实例，立即触发加载
              create: (_) => getIt<TrashBloc>()..add(TrashLoadFiles()),
              child: const TrashPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _slidePage(state, const SettingsPage()),
        ),
        GoRoute(
          path: '/settings/password',
          pageBuilder: (context, state) => _slidePage(state, const ChangePasswordPage()),
        ),
        GoRoute(
          path: '/settings/donate',
          pageBuilder: (context, state) => _slidePage(state, const DonatePage()),
        ),
        GoRoute(
          path: '/settings/about',
          pageBuilder: (context, state) => _slidePage(state, const AboutPage()),
        ),
        GoRoute(
          path: '/settings/privacy-policy',
          pageBuilder: (context, state) => _slidePage(
            state,
            const LegalPage(
              title: '隐私政策',
              assetPath: 'assets/privacy_policy.md',
            ),
          ),
        ),
        GoRoute(
          path: '/settings/user-agreement',
          pageBuilder: (context, state) => _slidePage(
            state,
            const LegalPage(
              title: '用户协议',
              assetPath: 'assets/user_agreement.md',
            ),
          ),
        ),
        GoRoute(
          path: '/intrusion',
          pageBuilder: (context, state) => _slidePage(
            state,
            BlocProvider(
              // 从 DI 获取 IntrusionBloc factory 实例，立即触发加载
              create: (_) => getIt<IntrusionBloc>()..add(IntrusionLoadRecords()),
              child: const IntrusionPage(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 淡入过渡（用于顶级页面切换：计算器↔主页、解锁等）
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// 右滑入过渡（用于 push 导航：文件夹详情、设置、回收站等）
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

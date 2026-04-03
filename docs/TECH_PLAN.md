# 隐私保险箱 (Privacy Vault) -- 技术实现规划

**Status**: Draft | **Last Updated**: 2026-03-31 | **Version**: 1.0

---

## 1. 需求重述（技术视角）

### 1.1 系统定位

一个基于 Flutter 框架开发的纯本地化隐私文件管理应用。核心能力是对用户导入的图片、视频等文件执行 AES-256-GCM 对称加密后存储于应用私有目录，通过多层身份验证和伪装机制保护数据访问入口。先行支持 Android 平台（最低 API 26 / Android 8.0），后续扩展 iOS。

### 1.2 核心技术需求

**认证与入口安全**：
- 4-6 位 PIN 码作为主认证因子，PIN 经 PBKDF2/Argon2id 派生后用于主密钥解锁
- Android BiometricPrompt API 提供指纹/面部快捷认证（CryptoObject 绑定 Android Keystore 密钥）
- 计算器伪装入口：完整的四则运算计算器，特定输入序列（PIN + "="）触发认证流程
- 自动锁定：App 进入后台时启动计时器，超时后清除内存中的会话密钥
- 防暴力破解：错误计数持久化存储，指数退避冷却（5次/30s, 10次/5min），3次错误触发前置摄像头静默拍照

**文件加密与存储**：
- 每文件独立的 Data Encryption Key（DEK），使用 AES-256-GCM 加密文件内容
- DEK 由 Key Encryption Key（KEK）加密后存储在元数据数据库中
- KEK 派生自用户 PIN（通过 Argon2id/PBKDF2），KEK 本身由 Android Keystore 中的硬件级密钥保护
- 大文件（>10MB）采用分块加密（chunk size 1MB），支持流式解密播放
- 加密缩略图独立生成和存储，与原文件使用相同的 DEK
- 文件导入后可选删除源文件（通过 MediaStore API / SAF）

**文件预览**：
- 图片：内存解密后通过 Image widget 展示，支持手势缩放/滑动
- 视频：分块流式解密写入临时管道/文件，通过视频播放器控件播放，播放完毕清除临时数据
- 缩略图网格：加密缩略图解密后缓存于内存 LRU cache

**数据保护**：
- `FLAG_SECURE` 防截屏/录屏，最近任务列表显示空白
- 30 天回收站，到期自动清除（WorkManager 定时任务）
- 紧急销毁：删除所有加密数据文件及数据库，覆写密钥区域
- 剪贴板 PIN 输入禁止粘贴
- 所有临时解密文件（分享/导出产生）操作完成后立即删除

**用户体验**：
- 深色/浅色主题，跟随系统设置，基于 Design Token 的完整主题系统
- 4px 网格对齐的间距系统，Material Symbols Outlined 图标
- 全功能免费，设置页赞赏码捐赠入口（微信赞赏码图片）
- 无深度链接、无系统通知、不持久化导航栈

### 1.3 非功能需求

| 维度 | 要求 |
|------|------|
| 最低 Android 版本 | API 26 (Android 8.0) |
| 目标 Android 版本 | API 34 (Android 14) |
| 加密性能 | 图片导入加密 > 20MB/s，视频流式解密零可感知延迟 |
| 内存占用 | 缩略图 LRU cache <= 50MB |
| APK 大小 | < 30MB |
| 冷启动时间 | < 2s 到计算器/解锁页 |
| 数据库 | SQLite（加密），查询延迟 < 50ms |
| 合规 | PIPL 合规，仅申请存储/相机必要权限 |

---

## 2. 技术架构设计

### 2.1 整体架构：Clean Architecture + BLoC

```
┌─────────────────────────────────────────────────────────┐
│                     Presentation Layer                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Pages   │  │ Widgets  │  │  BLoCs   │  │  Theme   │ │
│  │ (Screens)│  │(Components│  │ (State)  │  │ (Tokens) │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Entities │  │ Use Cases│  │Repository│               │
│  │          │  │          │  │Interfaces│               │
│  └──────────┘  └──────────┘  └──────────┘               │
├─────────────────────────────────────────────────────────┤
│                       Data Layer                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │Repository│  │  Models  │  │   Data   │  │ Platform │ │
│  │  Impls   │  │ (DTOs)   │  │ Sources  │  │ Channels │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
├─────────────────────────────────────────────────────────┤
│                    Platform Layer (Native)                │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐ │
│  │Android Keystore│ │BiometricAPI │  │  MediaStore/SAF  │ │
│  └──────────────┘  └─────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 2.2 模块划分

```
lib/
├── main.dart
├── app.dart                          # MaterialApp 配置、路由、主题
│
├── core/                             # 跨模块共享基础设施
│   ├── crypto/                       # 加密引擎
│   │   ├── crypto_engine.dart        # AES-256-GCM 加密/解密
│   │   ├── key_manager.dart          # 密钥派生、KEK/DEK 管理
│   │   ├── chunk_encryptor.dart      # 分块加密/解密（大文件）
│   │   └── secure_random.dart        # 安全随机数生成
│   ├── database/                     # 数据库
│   │   ├── app_database.dart         # SQLite 数据库定义
│   │   ├── daos/                     # 各表 DAO
│   │   └── migrations/              # 数据库迁移
│   ├── storage/                      # 文件存储
│   │   ├── encrypted_file_storage.dart
│   │   └── temp_file_manager.dart    # 临时文件生命周期管理
│   ├── security/                     # 安全基础设施
│   │   ├── session_manager.dart      # 会话/锁定状态管理
│   │   ├── auto_lock_service.dart    # 自动锁定
│   │   └── screen_security.dart      # FLAG_SECURE、通知隐藏
│   ├── theme/                        # Design Token 主题系统
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_shadows.dart
│   │   └── app_theme.dart
│   ├── di/                           # 依赖注入
│   │   └── injection.dart
│   ├── error/                        # 错误处理
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   └── utils/                        # 工具函数
│       ├── file_utils.dart
│       └── format_utils.dart
│
├── features/                         # 按功能模块划分
│   ├── auth/                         # 认证模块
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── pages/
│   │       │   ├── pin_unlock_page.dart
│   │       │   ├── setup_page.dart
│   │       │   └── password_change_page.dart
│   │       └── widgets/
│   │           ├── pin_input.dart
│   │           └── pin_keyboard.dart
│   │
│   ├── calculator/                   # 计算器伪装模块
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── pages/
│   │       │   └── calculator_page.dart
│   │       └── widgets/
│   │           ├── calculator_display.dart
│   │           └── calculator_keypad.dart
│   │
│   ├── vault/                        # 文件保险箱核心模块
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── vault_file.dart
│   │   │   │   ├── vault_folder.dart
│   │   │   │   └── file_type.dart
│   │   │   ├── repositories/
│   │   │   │   ├── file_repository.dart
│   │   │   │   └── folder_repository.dart
│   │   │   └── usecases/
│   │   │       ├── import_files.dart
│   │   │       ├── export_file.dart
│   │   │       ├── delete_files.dart
│   │   │       ├── move_files.dart
│   │   │       └── generate_thumbnail.dart
│   │   ├── data/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── pages/
│   │       │   ├── home_page.dart
│   │       │   ├── folder_detail_page.dart
│   │       │   └── import_page.dart
│   │       └── widgets/
│   │           ├── folder_card.dart
│   │           ├── thumbnail_grid.dart
│   │           ├── batch_action_bar.dart
│   │           ├── storage_bar.dart
│   │           └── empty_state.dart
│   │
│   ├── preview/                      # 文件预览模块
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── pages/
│   │       │   ├── image_preview_page.dart
│   │       │   └── video_player_page.dart
│   │       └── widgets/
│   │
│   ├── trash/                        # 回收站模块
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── settings/                     # 设置模块
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── intrusion/                    # 入侵检测模块
│       ├── domain/
│       ├── data/
│       └── presentation/
│
├── shared/                           # 共享 UI 组件
│   └── widgets/
│       ├── app_button.dart
│       ├── app_dialog.dart
│       ├── app_bottom_sheet.dart
│       ├── app_toast.dart
│       ├── app_snackbar.dart
│       ├── app_switch.dart
│       ├── app_input.dart
│       ├── app_search_bar.dart
│       ├── app_skeleton.dart
│       ├── app_progress.dart
│       ├── app_list_item.dart
│       └── app_nav_bar.dart
│
android/
├── app/src/main/kotlin/
│   ├── KeystorePlugin.dart           # Android Keystore Method Channel
│   ├── BiometricPlugin.dart          # 生物识别 Method Channel
│   └── ScreenSecurityPlugin.dart     # FLAG_SECURE Method Channel
```

### 2.3 状态管理方案

采用 **flutter_bloc** 作为状态管理方案：

| BLoC | 职责 | 持久化 |
|------|------|--------|
| `AuthBloc` | 认证状态（锁定/解锁/首次设置）、PIN 验证、错误计数 | 错误计数持久化 |
| `SessionBloc` | 会话生命周期、自动锁定计时器 | 否（内存） |
| `CalculatorBloc` | 计算器运算逻辑、密码检测 | 否 |
| `VaultBloc` | 文件夹列表、文件列表、Tab 筛选 | 通过数据库 |
| `ImportBloc` | 导入流程状态、进度、队列 | 否 |
| `PreviewBloc` | 当前预览文件、缩放状态 | 否 |
| `TrashBloc` | 回收站列表 | 通过数据库 |
| `SettingsBloc` | 用户设置项 | SharedPreferences |
| `ThemeBloc` | 主题模式（浅色/深色/跟随系统） | SharedPreferences |

### 2.4 路由设计

采用 **go_router** 声明式路由：

```
/                          → 路由守卫判断首次/已设置
/setup                     → 首次设置页（步骤流程）
/unlock                    → PIN/生物识别解锁页
/calculator                → 计算器伪装入口
/home                      → 主页（文件总览）
/folder/:id                → 文件夹详情页
/preview/image/:fileId     → 图片预览页
/preview/video/:fileId     → 视频播放页
/import                    → 文件导入页（全屏）
/trash                     → 回收站页
/settings                  → 设置页
/settings/password          → 密码修改页
/settings/about             → 关于页
/settings/donate            → 支持开发者页
```

路由守卫逻辑：所有 `/home` 及以下路由需要 `SessionBloc` 状态为已认证，否则重定向到 `/unlock` 或 `/calculator`。

---

## 3. 技术选型

### 3.1 Flutter 核心依赖

| 类别 | 包名 | 版本 | 用途 | 选择理由 |
|------|------|------|------|---------|
| **状态管理** | `flutter_bloc` | ^8.x | BLoC 模式状态管理 | 社区主流、可测试性强、关注点分离清晰 |
| **路由** | `go_router` | ^14.x | 声明式路由 | Flutter 官方推荐、支持路由守卫和重定向 |
| **依赖注入** | `get_it` + `injectable` | latest | 服务定位器 + 代码生成 | 轻量级、编译时安全 |
| **数据库** | `drift` (原 moor) | ^2.x | SQLite ORM | 类型安全、支持迁移、支持加密扩展 |
| **数据库加密** | `sqlcipher_flutter_libs` | latest | SQLCipher 加密 SQLite | 数据库层加密，防止 root 设备读取 |
| **序列化** | `freezed` + `json_serializable` | latest | 不可变数据类 + JSON | 代码生成、不可变性保证 |
| **等价** | `equatable` | ^2.x | 值对象等价比较 | BLoC 状态比较必需 |

### 3.2 加密与安全

| 类别 | 包名 | 版本 | 用途 | 选择理由 |
|------|------|------|------|---------|
| **AES 加密** | `pointycastle` | ^3.x | AES-256-GCM 纯 Dart 实现 | 纯 Dart、跨平台、经过审计 |
| **密钥派生** | `pointycastle` (PBKDF2) | ^3.x | PBKDF2-HMAC-SHA256 | 同包内支持 |
| **Argon2** | `argon2_ffi` | latest | Argon2id 密钥派生（首选） | 内存硬函数、抗 GPU/ASIC 攻击 |
| **安全随机** | `dart:math` (Random.secure) | built-in | IV/Nonce/Salt/DEK 生成 | Dart 标准库安全随机 |
| **Android Keystore** | Method Channel (自定义) | - | 硬件级密钥保护 | 需原生 Kotlin 代码通过 MethodChannel 桥接 |
| **生物识别** | `local_auth` | ^2.x | 指纹/面部识别 | Flutter 官方维护、支持 BiometricPrompt |
| **安全存储** | `flutter_secure_storage` | ^9.x | 存储小型敏感数据（salt、设置标志） | Android Keystore 后端 |

### 3.3 文件与媒体

| 类别 | 包名 | 版本 | 用途 | 选择理由 |
|------|------|------|------|---------|
| **文件选择** | `file_picker` | ^8.x | SAF 文件选择器 | 支持多选、任意类型 |
| **图片选择** | `photo_manager` | ^3.x | 系统相册访问、批量选择 | 高性能、支持分页加载 |
| **图片缩放** | `photo_view` | ^0.15.x | 图片预览手势交互 | 成熟的缩放/平移/双击支持 |
| **视频播放** | `media_kit` | latest | 视频播放器 | 基于 mpv/libmpv、性能优秀、支持自定义 data source |
| **缩略图** | `video_thumbnail` | ^0.5.x | 视频缩略图提取 | 从视频提取关键帧 |
| **图片处理** | `image` (dart) | ^4.x | 缩略图生成/缩放 | 纯 Dart、支持多种格式 |
| **路径管理** | `path_provider` | ^2.x | 应用私有目录 | Flutter 官方维护 |
| **权限** | `permission_handler` | ^11.x | 运行时权限请求 | 统一权限管理 API |
| **MIME** | `mime` | ^1.x | 文件类型识别 | 根据扩展名/内容判断 MIME |
| **相机** | `camera` | ^0.11.x | 前置摄像头拍照（入侵检测） | Flutter 官方维护 |

### 3.4 UI 与体验

| 类别 | 包名 | 版本 | 用途 | 选择理由 |
|------|------|------|------|---------|
| **图标** | `material_symbols_icons` | latest | Material Symbols Outlined | 与 UI 规范一致 |
| **动画** | `flutter_animate` | ^4.x | 声明式动画链 | 简化复杂动画序列 |
| **骨架屏** | `shimmer` | ^3.x | 加载占位动画 | 轻量级、可定制 |
| **Toast** | `fluttertoast` | ^8.x | Toast 消息 | 简单稳定 |
| **Pull to refresh** | `pull_to_refresh` | latest | 下拉刷新（可选） | - |
| **设备信息** | `device_info_plus` | latest | 设备型号/系统版本 | 兼容性检测 |
| **存储空间** | `disk_space_plus` | latest | 磁盘可用空间 | 存储用量条显示 |

### 3.5 后台任务

| 类别 | 包名 | 版本 | 用途 | 选择理由 |
|------|------|------|------|---------|
| **后台任务** | `workmanager` | ^0.5.x | 回收站自动清理定时任务 | Android WorkManager 封装 |
| **Isolate** | `dart:isolate` (compute) | built-in | 加密/解密计算密集操作 | 不阻塞 UI 线程 |

---

## 4. 数据模型设计

### 4.1 数据库表结构（drift / SQLite + SQLCipher）

**数据库文件**：存储在应用私有目录，使用 SQLCipher 加密，数据库密码由 KEK 派生。

#### `vault_folders` 表

```sql
CREATE TABLE vault_folders (
  id            TEXT PRIMARY KEY,          -- UUID v4
  name          TEXT NOT NULL,             -- 文件夹名称
  color_hex     TEXT,                      -- 封面渐变色（无文件时显示）
  icon_name     TEXT,                      -- 可选自定义图标
  sort_order    INTEGER NOT NULL DEFAULT 0,-- 排序权重
  created_at    INTEGER NOT NULL,          -- Unix timestamp (ms)
  updated_at    INTEGER NOT NULL           -- Unix timestamp (ms)
);
```

#### `vault_files` 表

```sql
CREATE TABLE vault_files (
  id                TEXT PRIMARY KEY,      -- UUID v4
  folder_id         TEXT NOT NULL,         -- 所属文件夹 FK
  original_name     TEXT NOT NULL,         -- 原始文件名
  file_type         TEXT NOT NULL,         -- 'image' | 'video' | 'document' | 'other'
  mime_type         TEXT NOT NULL,         -- MIME 类型
  encrypted_path    TEXT NOT NULL,         -- 加密文件在应用私有目录的相对路径
  thumbnail_path    TEXT,                  -- 加密缩略图路径
  file_size         INTEGER NOT NULL,      -- 原始文件大小 (bytes)
  encrypted_size    INTEGER NOT NULL,      -- 加密后文件大小 (bytes)
  width             INTEGER,              -- 图片/视频宽度 (px)
  height            INTEGER,              -- 图片/视频高度 (px)
  duration_ms       INTEGER,              -- 视频时长 (ms)
  encrypted_dek     TEXT NOT NULL,         -- Base64 编码的加密 DEK
  dek_iv            TEXT NOT NULL,         -- Base64 编码的 DEK 加密 IV
  file_iv           TEXT NOT NULL,         -- Base64 编码的文件加密 IV
  chunk_count       INTEGER DEFAULT 1,     -- 分块数（大文件 > 1）
  checksum          TEXT NOT NULL,         -- 原文件 SHA-256 校验和
  is_deleted        INTEGER NOT NULL DEFAULT 0, -- 软删除标志
  deleted_at        INTEGER,              -- 删除时间 (回收站)
  original_folder_id TEXT,                -- 删除前所属文件夹（用于恢复）
  sort_order        INTEGER NOT NULL DEFAULT 0,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,

  FOREIGN KEY (folder_id) REFERENCES vault_folders(id)
);

CREATE INDEX idx_files_folder ON vault_files(folder_id, is_deleted);
CREATE INDEX idx_files_type ON vault_files(file_type, is_deleted);
CREATE INDEX idx_files_deleted ON vault_files(is_deleted, deleted_at);
```

#### `intrusion_records` 表

```sql
CREATE TABLE intrusion_records (
  id            TEXT PRIMARY KEY,
  photo_path    TEXT NOT NULL,             -- 加密入侵者照片路径
  encrypted_dek TEXT NOT NULL,
  dek_iv        TEXT NOT NULL,
  photo_iv      TEXT NOT NULL,
  timestamp     INTEGER NOT NULL,
  attempt_count INTEGER NOT NULL           -- 当次错误次数
);
```

#### `security_questions` 表

```sql
CREATE TABLE security_questions (
  id            TEXT PRIMARY KEY,
  question      TEXT NOT NULL,             -- 安全问题文本
  answer_hash   TEXT NOT NULL,             -- 答案的 Argon2id 哈希
  answer_salt   TEXT NOT NULL,
  created_at    INTEGER NOT NULL
);
```

#### `app_settings` 表

```sql
CREATE TABLE app_settings (
  key           TEXT PRIMARY KEY,
  value         TEXT NOT NULL
);
-- 存储: auto_lock_delay, delete_after_import, calculator_disguise_enabled,
--       intrusion_photo_enabled, theme_mode, pin_error_count, 
--       last_error_timestamp 等
```

### 4.2 加密文件存储结构

```
{app_private_dir}/vault/
├── files/                             # 加密文件
│   ├── {uuid}.enc                     # 小文件（单块）
│   ├── {uuid}/                        # 大文件（多块）
│   │   ├── chunk_000.enc
│   │   ├── chunk_001.enc
│   │   └── ...
│   └── ...
├── thumbnails/                        # 加密缩略图
│   ├── {uuid}_thumb.enc
│   └── ...
├── intrusion/                         # 加密入侵者照片
│   ├── {uuid}.enc
│   └── ...
├── temp/                              # 临时解密文件（分享/导出用）
│   └── (runtime only, auto-cleaned)
└── backup/                            # 备份包暂存
```

### 4.3 加密文件格式

每个 `.enc` 文件的二进制结构：

```
[Magic Bytes: 4B "PVLT"]
[Version: 1B]
[Header Length: 2B (big-endian)]
[Header JSON: variable length, 包含 IV/Tag 元数据]
[Encrypted Data: variable length]
[GCM Auth Tag: 16B]
```

对于分块文件，每个 chunk 独立包含上述结构，共享同一 DEK 但使用不同的 IV/Nonce。

---

## 5. 安全架构

### 5.1 密钥层级体系

```
用户 PIN (4-6 位数字)
     │
     ├── Argon2id(PIN, salt, t=3, m=65536, p=4)
     │         │
     │         ▼
     │   Master Key (256-bit)
     │         │
     │         ├── AES-256-GCM 加密 → KEK (Key Encryption Key)
     │         │     ↑ 由 Android Keystore 硬件密钥保护
     │         │
     │         └── KEK 用于加密/解密每个文件的 DEK
     │
     │   对于每个文件:
     │         DEK_i = SecureRandom(256-bit)
     │         Encrypted_DEK_i = AES-256-GCM(KEK, DEK_i)
     │         Encrypted_File_i = AES-256-GCM(DEK_i, plaintext_i)
     │
     └── Argon2id(PIN, different_salt) → PIN 验证哈希（存储用于验证）
```

### 5.2 Android Keystore 集成

通过 Kotlin MethodChannel 桥接：

```
Flutter (Dart)  ←─ MethodChannel ──→  Kotlin (Android Native)
                                        │
                                        ├── generateKey()
                                        │   → KeyGenerator AES/256 in AndroidKeyStore
                                        │   → 设置 setUserAuthenticationRequired(false)
                                        │     （KEK 保护不依赖锁屏，依赖应用自身认证）
                                        │
                                        ├── encryptWithKeystore(plaintext)
                                        │   → 用 Keystore 密钥 AES-GCM 加密
                                        │   → 返回 (ciphertext, iv)
                                        │
                                        └── decryptWithKeystore(ciphertext, iv)
                                            → 用 Keystore 密钥 AES-GCM 解密
                                            → 返回 plaintext
```

### 5.3 认证流程

```
用户输入 PIN
    │
    ▼
Argon2id(PIN, stored_salt) → candidate_hash
    │
    ▼
比较 candidate_hash 与 stored_pin_hash
    │
    ├── 不匹配 → 错误计数+1
    │            ├── >= 3 → 静默前摄拍照
    │            ├── >= 5 → 冷却 30s
    │            └── >= 10 → 冷却 5min
    │
    └── 匹配 → 
        │
        ▼
    Argon2id(PIN, master_salt) → master_key
        │
        ▼
    Keystore.decrypt(encrypted_kek) → kek_encrypted_by_master
        │
        ▼
    AES-GCM-Decrypt(master_key, kek_encrypted_by_master) → KEK
        │
        ▼
    KEK 存入内存 SessionManager（不持久化）
        │
        ▼
    重置错误计数 → 进入主页
```

### 5.4 生物识别快速解锁

```
生物识别认证成功（BiometricPrompt + CryptoObject）
    │
    ▼
Android Keystore 释放 biometric-bound 密钥
    │
    ▼
解密存储的 KEK（KEK 被 biometric-bound 密钥加密了一份副本）
    │
    ▼
KEK 存入内存 SessionManager
```

生物识别绑定时：将 KEK 额外用 biometric-bound Keystore 密钥加密存储一份副本。

### 5.5 自动锁定

```
App 生命周期监听（WidgetsBindingObserver）
    │
    ├── didChangeAppLifecycleState(paused/inactive)
    │       → 启动定时器 (delay = user_setting: 0/30s/60s/300s)
    │       → 定时器到期 → SessionManager.clearSession()
    │       → KEK 从内存清除
    │
    └── didChangeAppLifecycleState(resumed)
        → 检查 SessionManager.isAuthenticated
            ├── true → 取消定时器，恢复页面
            └── false → 导航到解锁页
```

### 5.6 密码修改流程

```
验证旧 PIN → 解锁 KEK
    │
    ▼
用新 PIN 重新派生 new_master_key
    │
    ▼
AES-GCM-Encrypt(new_master_key, KEK) → new_encrypted_kek
    │
    ▼
Argon2id(new_PIN, new_salt) → new_pin_hash
    │
    ▼
原子更新: stored_pin_hash, stored_master_salt, stored_encrypted_kek
    │
    ▼
注意: 所有文件的 DEK 无需重新加密（KEK 未变，只是 KEK 的保护方式变了）
```

### 5.7 诱饵保险箱（P1 阶段）

```
诱饵 PIN 输入
    │
    ▼
与诱饵 PIN 哈希匹配
    │
    ▼
使用诱饵 KEK 解密诱饵数据库
    │
    ▼
展示预设的无关文件
```

诱饵空间有独立的 KEK、独立的加密数据库和文件目录。输入假密码时无法区分是进入了真实空间还是诱饵空间。

---

## 6. 实现阶段拆解

### Phase 1: 安全基础设施（Week 1-2）

**目标**：完成加密引擎、密钥管理、认证系统，可以设置 PIN 并通过 PIN 解锁。

- [x] **1.1** 项目初始化：Flutter 工程创建、目录结构、依赖配置 — `pubspec.yaml`, `lib/` 结构 | 依赖: 无 | 复杂度: 低 | 风险: 低
- [x] **1.2** Design Token 主题系统实现 — `lib/core/theme/` | 依赖: 无 | 复杂度: 低 | 风险: 低
- [x] **1.3** 共享 UI 组件库（按钮、输入框、PIN 键盘、对话框） — `lib/shared/widgets/` | 依赖: 1.2 | 复杂度: 中 | 风险: 低
- [x] **1.4** AES-256-GCM 加密引擎（encrypt/decrypt/stream） — `lib/core/crypto/crypto_engine.dart` | 依赖: 无 | 复杂度: 高 | 风险: 中
- [x] **1.5** 分块加密器（1MB chunk） — `lib/core/crypto/chunk_encryptor.dart` | 依赖: 1.4 | 复杂度: 高 | 风险: 中
- [x] **1.6** Argon2id/PBKDF2 密钥派生 — `lib/core/crypto/key_manager.dart` | 依赖: 1.4 | 复杂度: 高 | 风险: 高
- [x] **1.7** Android Keystore MethodChannel（Kotlin 原生代码） — `android/...KeystorePlugin.kt` | 依赖: 无 | 复杂度: 高 | 风险: 高
- [x] **1.8** KEK/DEK 密钥管理完整流程 — `lib/core/crypto/key_manager.dart` | 依赖: 1.4, 1.6, 1.7 | 复杂度: 高 | 风险: 高
- [x] **1.9** SQLite + SQLCipher 数据库初始化、表定义、DAO — `lib/core/database/` | 依赖: 1.8 | 复杂度: 中 | 风险: 低
- [x] **1.10** 依赖注入配置 — `lib/core/di/` | 依赖: 1.1-1.9 | 复杂度: 低 | 风险: 低
- [x] **1.11** AuthBloc：PIN 设置、PIN 验证、错误计数 — `lib/features/auth/` | 依赖: 1.6, 1.8, 1.9 | 复杂度: 中 | 风险: 中
- [x] **1.12** 首次设置页面（PIN 设置 + 安全问题） — `lib/features/auth/presentation/` | 依赖: 1.3, 1.11 | 复杂度: 中 | 风险: 低
- [x] **1.13** PIN 解锁页面 — `lib/features/auth/presentation/` | 依赖: 1.3, 1.11 | 复杂度: 中 | 风险: 低
- [x] **1.14** 会话管理器 + 自动锁定服务 — `lib/core/security/` | 依赖: 1.11 | 复杂度: 中 | 风险: 中
- [x] **1.15** 路由配置 + 路由守卫 — `lib/app.dart` | 依赖: 1.14 | 复杂度: 中 | 风险: 低
- [x] **1.16** 生物识别集成（local_auth） — `lib/features/auth/` | 依赖: 1.7, 1.11 | 复杂度: 中 | 风险: 中
- [x] **1.17** 防截屏（FLAG_SECURE）MethodChannel — `lib/core/security/screen_security.dart` | 依赖: 无 | 复杂度: 低 | 风险: 低

**Phase 1 交付物**：可以设置 PIN、指纹解锁、自动锁定，安全基础设施完整可用。

---

### Phase 2: 核心文件操作（Week 3-4）

**目标**：完成文件导入加密、文件夹管理、缩略图生成、批量操作。

- [x] **2.1** 文件导入服务：从相册/SAF 选择文件 — `lib/features/vault/data/` | 依赖: P1 完成 | 复杂度: 中 | 风险: 中
- [x] **2.2** 文件加密与存储流程（Isolate 后台执行） — `lib/core/storage/encrypted_file_storage.dart` | 依赖: 1.4, 1.5, 1.8 | 复杂度: 高 | 风险: 高
- [x] **2.3** 缩略图生成：图片缩放 + 视频关键帧提取 + 加密存储 — `lib/features/vault/data/thumbnail_service.dart` | 依赖: 2.2 | 复杂度: 中 | 风险: 中
- [x] **2.4** 导入后删除原文件（MediaStore/SAF） — `lib/features/vault/data/file_import_service.dart` | 依赖: 2.2 | 复杂度: 中 | 风险: 高
- [x] **2.5** VaultBloc：文件夹 CRUD、文件列表查询 — `lib/features/vault/presentation/blocs/` | 依赖: 1.9, 2.2 | 复杂度: 中 | 风险: 低
- [x] **2.6** ImportBloc：导入流程状态、进度追踪、队列管理 — `lib/features/vault/presentation/blocs/` | 依赖: 2.1, 2.2, 2.3 | 复杂度: 中 | 风险: 中
- [x] **2.7** 主页 UI：Tab 栏、文件夹卡片网格、存储用量条、FAB — `lib/features/vault/presentation/pages/home_page.dart` | 依赖: 1.3, 2.5 | 复杂度: 中 | 风险: 低
- [x] **2.8** 文件夹详情页 UI：缩略图网格、多选模式 — `lib/features/vault/presentation/pages/folder_detail_page.dart` | 依赖: 2.5, 2.3 | 复杂度: 中 | 风险: 低
- [x] **2.9** 文件导入页 UI：导入来源选择、进度弹窗 — `lib/features/vault/presentation/pages/import_page.dart` | 依赖: 2.6 | 复杂度: 中 | 风险: 低
- [x] **2.10** 批量操作：多选、移动、批量删除 — `lib/features/vault/` | 依赖: 2.5, 2.8 | 复杂度: 中 | 风险: 低
- [x] **2.11** 文件夹创建/重命名/删除对话框 — `lib/features/vault/presentation/widgets/` | 依赖: 1.3, 2.5 | 复杂度: 低 | 风险: 低
- [x] **2.12** 空状态组件 — `lib/shared/widgets/empty_state.dart` | 依赖: 1.3 | 复杂度: 低 | 风险: 低
- [x] **2.13** 骨架屏加载态 — `lib/shared/widgets/app_skeleton.dart` | 依赖: 1.3 | 复杂度: 低 | 风险: 低

**Phase 2 交付物**：可以创建文件夹、从相册/文件管理器导入文件并加密、浏览加密缩略图网格、批量管理文件。

---

### Phase 3: 浏览预览与回收站（Week 5-6）

**目标**：完成图片全屏预览、视频流式播放、文件导出、回收站。

- [x] **3.1** 图片解密预览：全屏展示、Hero 动画 — `lib/features/preview/presentation/pages/image_preview_page.dart` | 依赖: 2.2, 2.3 | 复杂度: 中 | 风险: 低
- [x] **3.2** 图片手势：双指缩放、双击放大、左右滑动切换、下滑关闭 — `lib/features/preview/` | 依赖: 3.1 | 复杂度: 中 | 风险: 低
- [x] **3.3** 视频流式解密：分块解密写入临时管道 — `lib/features/preview/presentation/blocs/preview_bloc.dart` | 依赖: 1.5, 2.2 | 复杂度: 高 | 风险: 高
- [x] **3.4** 视频播放器 UI：播放控制、进度条、亮度/音量手势 — `lib/features/preview/presentation/pages/video_player_page.dart` | 依赖: 3.3 | 复杂度: 高 | 风险: 中
- [x] **3.5** 文件导出/解密到手机存储 — `lib/features/preview/presentation/blocs/preview_bloc.dart` | 依赖: 2.2 | 复杂度: 中 | 风险: 低
- [x] **3.6** 文件分享：解密到临时目录 → 系统分享 → 清除临时文件 — `lib/features/preview/presentation/blocs/preview_bloc.dart` | 依赖: 3.5 | 复杂度: 中 | 风险: 中
- [x] **3.7** 临时文件管理器：自动清理策略 — `lib/core/storage/temp_file_manager.dart` | 依赖: 无 | 复杂度: 低 | 风险: 低
- [x] **3.8** 回收站 BLoC + UI：软删除、恢复、彻底删除 — `lib/features/trash/` | 依赖: 2.5, 1.9 | 复杂度: 中 | 风险: 低
- [x] **3.9** 回收站自动清理（30 天 WorkManager） — `lib/features/trash/presentation/blocs/trash_bloc.dart` | 依赖: 3.8 | 复杂度: 中 | 风险: 低
- [x] **3.10** 预览页底部操作栏：分享、导出、删除、详情 — `lib/features/preview/presentation/widgets/preview_bottom_bar.dart` | 依赖: 3.1, 3.5, 3.6 | 复杂度: 低 | 风险: 低
- [x] **3.11** Snackbar 撤销删除 — `lib/shared/widgets/app_snackbar.dart` | 依赖: 3.8 | 复杂度: 低 | 风险: 低

**Phase 3 交付物**：完整的文件预览体验（图片缩放/切换、视频流式播放）、文件导出分享、30 天回收站。

---

### Phase 4: 伪装与高级安全（Week 7-8）

**目标**：完成计算器伪装入口、新手引导、设置页完整功能、入侵检测。

- [x] **4.1** 计算器 BLoC：四则运算逻辑 — `lib/features/calculator/presentation/blocs/calculator_bloc.dart` | 依赖: 无 | 复杂度: 中 | 风险: 低
- [x] **4.2** 计算器 UI：显示屏 + 键盘（模仿系统计算器） — `lib/features/calculator/presentation/pages/calculator_page.dart` | 依赖: 1.2, 4.1 | 复杂度: 中 | 风险: 中
- [x] **4.3** 计算器密码检测：PIN 序列 + "=" 触发认证 — `lib/features/calculator/presentation/blocs/calculator_bloc.dart` | 依赖: 4.1, 1.11 | 复杂度: 中 | 风险: 低
- [x] **4.4** 计算器 → 主页过渡动画（形变过渡 400ms） — `lib/app.dart` 路由守卫 | 依赖: 4.2, 4.3 | 复杂度: 中 | 风险: 低
- [x] **4.5** App 图标伪装（计算器自适应图标） — `android/app/src/main/res/` | 依赖: 无 | 复杂度: 低 | 风险: 低
- [x] **4.6** 通知隐藏：最近任务空白 / 伪装名称 — FLAG_SECURE + AndroidManifest label="计算器" | 依赖: 1.17 | 复杂度: 低 | 风险: 低
- [x] **4.7** 新手引导流程（4 步骤：欢迎 → PIN 设置 → 安全提示 → 使用引导） — `lib/features/auth/presentation/pages/onboarding_page.dart` | 依赖: 1.12 | 复杂度: 中 | 风险: 低
- [x] **4.8** 设置页完整 UI — `lib/features/settings/presentation/pages/settings_page.dart` | 依赖: 1.3 | 复杂度: 中 | 风险: 低
- [x] **4.9** 密码修改页（3 步骤流程） — `lib/features/settings/presentation/pages/change_password_page.dart` | 依赖: 1.11, 5.6 | 复杂度: 中 | 风险: 中
- [x] **4.10** 入侵检测：前置摄像头静默拍照 + 加密存储 — `lib/features/intrusion/data/intrusion_capture_service.dart` | 依赖: 1.4, 1.8 | 复杂度: 高 | 风险: 高
- [x] **4.11** 入侵记录查看页面 — `lib/features/intrusion/presentation/pages/intrusion_page.dart` | 依赖: 4.10 | 复杂度: 低 | 风险: 低
- [x] **4.12** 防暴力破解：冷却期 UI + 倒计时 — `lib/features/auth/presentation/blocs/auth_bloc.dart` | 依赖: 1.11 | 复杂度: 低 | 风险: 低
- [x] **4.13** 支持开发者页面（赞赏码展示） — `lib/features/settings/presentation/pages/donate_page.dart` | 依赖: 1.3 | 复杂度: 低 | 风险: 低
- [x] **4.14** 关于页面 + 隐私政策 + 用户协议 — `lib/features/settings/presentation/pages/about_page.dart` | 依赖: 无 | 复杂度: 低 | 风险: 低

**Phase 4 交付物**：计算器伪装入口完整可用、新手引导流程、完整设置页、入侵检测拍照。

---

### Phase 5: 测试、打磨与上架（Week 9-10）

- [x] **5.1** 加密引擎单元测试（各种文件大小、边界情况） | 依赖: P1 | 复杂度: 中 | 风险: 低
- [x] **5.2** 密钥管理单元测试（派生、存储、恢复、修改） | 依赖: P1 | 复杂度: 中 | 风险: 低
- [x] **5.3** BLoC 单元测试（Auth、Vault、Calculator） | 依赖: P1-P4 | 复杂度: 中 | 风险: 低
- [ ] **5.4** 集成测试（导入 → 加密 → 缩略图 → 预览 → 导出） | 依赖: P2-P3 | 复杂度: 高 | 风险: 中
- [x] **5.5** 安全测试（密钥不泄露、内存清除、临时文件清理） | 依赖: P1 | 复杂度: 高 | 风险: 高
- [x] **5.6** UI 打磨：动画时序调优、过渡效果、触觉反馈 | 依赖: P4 | 复杂度: 中 | 风险: 低
- [ ] **5.7** 性能优化：大量文件列表虚拟化、缩略图缓存策略 | 依赖: P2-P3 | 复杂度: 中 | 风险: 中
- [ ] **5.8** 主流机型兼容测试（小米、华为、OPPO、vivo、三星） | 依赖: All | 复杂度: 中 | 风险: 高
- [x] **5.9** Android 13/14 存储权限适配验证 | 依赖: P2 | 复杂度: 中 | 风险: 中
- [x] **5.10** 隐私政策文档编写 | 依赖: 无 | 复杂度: 低 | 风险: 低
- [x] **5.11** APK 签名、混淆配置（ProGuard/R8） | 依赖: All | 复杂度: 低 | 风险: 低
- [ ] **5.12** 应用商店素材准备（截图、描述、分类） | 依赖: P4 | 复杂度: 低 | 风险: 低
- [ ] **5.13** 应用备案准备（2-4 周提前量） | 依赖: 5.10 | 复杂度: 低 | 风险: 中

---

## 7. 风险评估

### 7.1 高风险

| 风险 | 影响 | 概率 | 缓解方案 |
|------|------|------|---------|
| **视频流式解密性能不足** | 视频播放卡顿、用户体验差 | 中 | 1) 预解密缓冲区（提前解密下 N 个 chunk）; 2) 使用 Isolate 并行解密; 3) chunk 大小可调（1-4MB）; 4) 备选方案：解密到临时文件后播放 |
| **Android Keystore 兼容性** | 部分国产 ROM 的 Keystore 实现有 bug | 中 | 1) 运行时检测 Keystore 可用性; 2) 降级方案：使用 flutter_secure_storage 软件级加密; 3) 主流机型逐一测试 |
| **Argon2 在低端设备上性能** | 解锁延迟超过 1s，用户感知慢 | 中 | 1) 动态调整参数（根据设备基准测试）; 2) 低端设备降级为 PBKDF2 (100k 迭代); 3) 解锁时显示加载动画掩盖延迟 |
| **大文件导入（>4GB）内存溢出** | App 崩溃 | 低 | 1) 严格流式读取，chunk 1MB; 2) 不在内存中持有完整文件; 3) 监控内存使用，超限暂停 |
| **密钥丢失导致数据永久不可访问** | 用户数据永久丢失 | 低 | 1) 安全问题重置仅重置 PIN（重新派生 master_key 保护 KEK）; 2) 首次设置时强烈提示密码重要性; 3) 后续版本加入本地加密备份 |

### 7.2 中风险

| 风险 | 影响 | 概率 | 缓解方案 |
|------|------|------|---------|
| **Android 存储权限碎片化** | 不同 Android 版本导入/删除行为不一致 | 高 | 1) Android 10 以下使用传统文件 API; 2) Android 10+ 使用 MediaStore; 3) Android 13+ 使用细粒度媒体权限; 4) SAF 作为通用备选 |
| **计算器伪装被应用商店审核拒绝** | 无法上架 | 中 | 1) 伪装入口默认关闭，用户主动开启; 2) 应用描述强调"隐私保护"而非"隐藏"; 3) 准备无伪装版本作为备选 |
| **SQLCipher 性能** | 加密数据库查询慢于预期 | 低 | 1) 合理建立索引; 2) 缩略图路径缓存到内存; 3) 分页查询 |
| **入侵者拍照相机权限** | 用户未授权相机权限 | 中 | 1) 静默降级（不拍照，仅记录时间和错误次数）; 2) 不在入侵时弹权限对话框（会暴露 App 身份） |

### 7.3 低风险

| 风险 | 影响 | 概率 | 缓解方案 |
|------|------|------|---------|
| **Flutter 版本升级破坏兼容** | 构建失败 | 低 | 锁定 Flutter SDK 版本，定期升级 |
| **第三方包停止维护** | 长期维护困难 | 低 | 选择官方维护或社区活跃的包，关键功能自实现 |
| **APK 体积超标** | 用户下载意愿降低 | 低 | 1) 启用 tree shaking; 2) 按需加载资源; 3) 使用 App Bundle |

---

## 8. 测试策略

### 8.1 单元测试（目标覆盖率 >= 85%）

| 模块 | 测试重点 | 框架 |
|------|---------|------|
| `crypto_engine` | AES-256-GCM 加密/解密正确性、不同数据长度、空数据、边界情况 | `flutter_test` |
| `chunk_encryptor` | 分块加密后逐块解密一致性、块边界、最后不足一块的处理 | `flutter_test` |
| `key_manager` | Argon2id 派生一致性、KEK 加解密链、密码修改后旧 DEK 仍可解密 | `flutter_test` |
| `AuthBloc` | PIN 设置/验证状态流转、错误计数递增、冷却期倒计时、重置 | `bloc_test` |
| `VaultBloc` | 文件夹 CRUD、文件列表查询与筛选、排序 | `bloc_test` |
| `ImportBloc` | 导入流程状态（selecting → importing → done/error）、进度更新、取消 | `bloc_test` |
| `TrashBloc` | 软删除、恢复、30 天过期清理 | `bloc_test` |
| `CalculatorBloc` | 四则运算正确性、密码序列检测、非密码输入不触发 | `bloc_test` |
| `SessionManager` | 锁定/解锁状态、计时器触发锁定、手动锁定 | `flutter_test` |

### 8.2 集成测试

| 流程 | 测试内容 | 框架 |
|------|---------|------|
| 首次设置 → 解锁 | PIN 设置 → 退出 → 重新打开 → PIN 解锁成功 | `integration_test` |
| 文件导入完整链路 | 选择文件 → 加密 → 存储 → 数据库记录 → 缩略图生成 | `integration_test` |
| 文件预览完整链路 | 打开加密文件 → 解密 → 显示 → 关闭 → 临时文件清除 | `integration_test` |
| 文件导出完整链路 | 选择文件 → 解密 → 保存到外部存储 → 验证文件完整性 | `integration_test` |
| 回收站完整链路 | 删除 → 回收站列表 → 恢复 → 彻底删除 | `integration_test` |
| 密码修改 | 旧 PIN → 新 PIN → 解锁 → 已有文件仍可访问 | `integration_test` |

### 8.3 安全测试

| 测试项 | 验证内容 |
|--------|---------|
| 密钥内存清除 | 锁定后内存中不残留 KEK / master_key |
| 临时文件清理 | 分享/导出后临时解密文件是否被删除 |
| 加密文件不可读 | 直接读取 .enc 文件无法获取明文 |
| PIN 哈希不可逆 | 数据库中的 pin_hash 无法反推 PIN |
| FLAG_SECURE | 截屏 API 返回空白 |
| 剪贴板安全 | PIN 输入框不可粘贴 |
| 暴力破解防护 | 连续错误后冷却期生效 |
| 数据库加密 | SQLCipher 数据库文件不可用普通 SQLite 工具打开 |

### 8.4 性能测试

| 测试项 | 目标 |
|--------|------|
| 100 张图片批量导入加密 | 完成时间 < 30s（中端设备） |
| 1GB 视频文件加密 | 完成时间 < 60s |
| 500 张缩略图网格加载 | 首屏渲染 < 500ms |
| 视频流式解密播放 | 首帧延迟 < 1s，播放无卡顿 |
| App 冷启动 | 到计算器/解锁页 < 2s |
| Argon2id 密钥派生 | < 800ms（中端设备） |

### 8.5 兼容性测试矩阵

| 维度 | 测试范围 |
|------|---------|
| Android 版本 | 8.0, 10, 11, 12, 13, 14 |
| 品牌/ROM | 小米 MIUI, 华为 HarmonyOS, OPPO ColorOS, vivo OriginOS, 三星 OneUI, 原生 Android |
| 屏幕尺寸 | 5.5 英寸(小)、6.1 英寸(标准)、6.7 英寸(大)、10 英寸(平板) |
| 刘海/挖孔 | 水滴屏、挖孔屏、刘海屏 |
| 生物识别 | 光学指纹、超声波指纹、侧边指纹、面部识别 |

---

## 9. 关键技术决策记录

| 决策 | 选项 | 最终选择 | 理由 |
|------|------|---------|------|
| 状态管理 | BLoC vs Riverpod vs Provider | **BLoC** | 可测试性最强、关注点分离清晰、大型项目维护性好 |
| 数据库 | drift vs sqflite vs Hive | **drift + SQLCipher** | 类型安全 ORM + 数据库层加密 |
| 加密库 | pointycastle vs cryptography vs Native | **pointycastle** | 纯 Dart 实现、跨平台、AES-256-GCM 支持完善 |
| 视频播放 | video_player vs media_kit vs chewie | **media_kit** | 自定义数据源支持（流式解密）、性能优秀 |
| 密钥派生 | PBKDF2 vs Argon2id | **Argon2id 优先、PBKDF2 降级** | Argon2id 抗 GPU 攻击更强，低端设备降级 |
| 路由 | go_router vs auto_route | **go_router** | Flutter 官方推荐、路由守卫简洁 |
| 图片预览 | photo_view vs InteractiveViewer | **photo_view** | 手势支持完善、Hero 动画兼容 |

---

以上是完整的技术实现规划。涵盖了从架构设计到分阶段实施、从安全方案到测试策略的各个维度。

关键参考文件路径：
- `/home/hexin/claude_projects/phone_privacyfiles/docs/PRD.md`
- `/home/hexin/claude_projects/phone_privacyfiles/docs/UX_ARCHITECTURE.md`
- `/home/hexin/claude_projects/phone_privacyfiles/docs/UI_DESIGN.md`

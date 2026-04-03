# 隐私保险箱 (Privacy Vault)

纯本地化隐私文件管理 App，对用户导入的图片/视频执行 AES-256-GCM 加密存储，通过多层身份验证和计算器伪装机制保护数据入口。

## 技术栈

- **框架**: Flutter (Dart)，先做 Android（最低 API 26）
- **架构**: Clean Architecture + BLoC 状态管理
- **加密**: AES-256-GCM (pointycastle) + PBKDF2-HMAC-SHA256 密钥派生（后续升级 Argon2id）
- **数据库**: drift + SQLCipher（加密 SQLite）
- **路由**: go_router（声明式，含路由守卫）
- **DI**: get_it + injectable
- **视频**: media_kit（支持自定义数据源流式解密）

## 目录结构

```
docs/               # 设计文档（PRD、UX、UI、技术规划）
lib/
  core/             # 跨模块基础设施（crypto、database、security、theme、di）
  features/         # 按功能模块（auth、calculator、vault、preview、trash、settings、intrusion）
  shared/           # 共享 UI 组件
android/            # Android 原生代码（Keystore、Biometric MethodChannel）
```

## 设计文档

- `docs/PRD.md` — 产品需求（V1.2 定稿）
- `docs/UX_ARCHITECTURE.md` — UX 交互架构（V1.1 定稿）
- `docs/UI_DESIGN.md` — UI 视觉规范（定稿）
- `docs/ui_preview.html` — UI 视觉预览（浏览器打开）
- `docs/TECH_PLAN.md` — 技术实现规划（V1.0 定稿）

## 架构约定

- Clean Architecture 三层分离：presentation → domain → data
- 每个 feature 模块独立包含 domain/data/presentation 三层
- 状态管理统一使用 BLoC，UI 不直接操作数据源
- BLoC State 类使用 Equatable + 手写 copyWith（实际选型，功能等价于 freezed）
- 密钥相关操作通过 Android Keystore MethodChannel 桥接原生代码

## 安全规则

- KEK/DEK 仅在内存中存在，锁定后立即清除
- 临时解密文件操作完成后立即删除
- PIN 输入框禁止粘贴
- FLAG_SECURE 防截屏全局生效
- 加密文件使用自定义格式（Magic Bytes: "PVLT"）

## 编码规范

- 使用中文注释和文档
- 文件 < 800 行，函数 < 50 行
- 核心模块（crypto、key_manager、BLoC）采用 TDD
- UI 层正常开发，不使用 TDD


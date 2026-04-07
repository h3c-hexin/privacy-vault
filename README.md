# 隐私保险箱 Privacy Vault

外表是计算器，内里是加密保险箱——你的私密照片视频，只有你能看到。

## 功能特性

- **计算器伪装** — 桌面图标和界面都是真正能用的计算器，输入密码按 = 进入保险箱
- **军事级加密** — AES-256-GCM 加密每一个文件，Android Keystore 硬件保护密钥
- **纯本地零联网** — 不注册、不登录、不上传，无任何第三方 SDK
- **防截屏保护** — 敏感页面自动启用 FLAG_SECURE，防止截屏和录屏
- **防暴力破解** — 连续输错密码触发冷却期，支持入侵拍照记录
- **回收站机制** — 删除文件保留 30 天，防止误删

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter (Dart)，Android 8.0+ |
| 架构 | Clean Architecture + BLoC |
| 加密 | AES-256-GCM (pointycastle) + PBKDF2 密钥派生 |
| 数据库 | drift + SQLCipher（加密 SQLite）|
| 密钥保护 | Android Keystore 硬件安全模块 |
| 路由 | go_router（声明式，含路由守卫）|
| 视频 | media_kit（流式解密播放）|

## 安全设计

- **零知识架构** — 开发者不持有任何密钥，无法解密用户数据
- **KEK/DEK 双层密钥** — 文件独立加密，更换密码无需重新加密所有文件
- **PVLT 自定义格式** — 加密文件无法被第三方工具识别或读取
- **安全删除** — 临时文件零覆写后删除，回收站 30 天自动清理
- **内存保护** — 密钥仅在需要时加载，锁定后立即从内存中清除

## 构建

```bash
# 安装依赖
flutter pub get

# 调试版
flutter build apk --debug

# 发布版（需先配置 android/key.properties）
flutter build apk --release

# 运行测试
flutter test
```

## 签名配置

发布版需要在 `android/key.properties` 中配置签名信息（已被 .gitignore 忽略）：

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=your_alias
storeFile=your_keystore.jks
```

## 隐私声明

本应用不收集、不上传、不存储任何用户个人信息。所有数据仅存储在用户设备本地。详见应用内隐私政策。

## 许可证

Private - All Rights Reserved

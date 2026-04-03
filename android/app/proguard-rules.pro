# Flutter 混淆规则
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keystore Plugin
-keep class com.privacyvault.privacy_vault.KeystorePlugin { *; }
-keep class com.privacyvault.privacy_vault.MainActivity { *; }

# media_kit
-keep class com.alexmercerind.** { *; }
-keep class dev.nicholasgasior.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.** { *; }

# SQLCipher / drift
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# pointycastle
-keep class org.bouncycastle.** { *; }

# 保留 Kotlin 协程
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Play Core（Flutter deferred components 引用，实际未使用）
-dontwarn com.google.android.play.core.**

# 保留注解
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

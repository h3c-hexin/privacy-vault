package com.privacyvault.privacy_vault

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/// Android Keystore 桥接
///
/// 提供硬件级密钥保护，用于加密/解密 KEK。
class KeystorePlugin {
    companion object {
        private const val CHANNEL = "com.privacyvault/keystore"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "privacy_vault_master"
        private const val GCM_TAG_LENGTH = 128

        fun register(flutterEngine: FlutterEngine) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    try {
                        when (call.method) {
                            "generateKey" -> {
                                generateKey()
                                result.success(null)
                            }
                            "hasKey" -> {
                                result.success(hasKey())
                            }
                            "encrypt" -> {
                                val plaintext = call.argument<ByteArray>("plaintext")
                                    ?: throw IllegalArgumentException("plaintext is required")
                                val encrypted = encrypt(plaintext)
                                result.success(encrypted)
                            }
                            "decrypt" -> {
                                val ciphertext = call.argument<ByteArray>("ciphertext")
                                    ?: throw IllegalArgumentException("ciphertext is required")
                                val iv = call.argument<ByteArray>("iv")
                                    ?: throw IllegalArgumentException("iv is required")
                                val decrypted = decrypt(ciphertext, iv)
                                result.success(decrypted)
                            }
                            "deleteKey" -> {
                                deleteKey()
                                result.success(null)
                            }
                            else -> result.notImplemented()
                        }
                    } catch (e: Exception) {
                        result.error("KEYSTORE_ERROR", e.message, null)
                    }
                }
        }

        private fun generateKey() {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                KEYSTORE_PROVIDER
            )
            keyGenerator.init(
                KeyGenParameterSpec.Builder(
                    KEY_ALIAS,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    // TODO: 启用生物识别功能后改为 true + setUserAuthenticationValidityDurationSeconds
                    // 可防止绕过 Flutter 层 PIN 直接调用 Keystore 密钥
                    .setUserAuthenticationRequired(false)
                    .build()
            )
            keyGenerator.generateKey()
        }

        private fun hasKey(): Boolean {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            return keyStore.containsAlias(KEY_ALIAS)
        }

        /// 返回 Map: {"ciphertext": ByteArray, "iv": ByteArray}
        private fun encrypt(plaintext: ByteArray): Map<String, ByteArray> {
            val key = getKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            val ciphertext = cipher.doFinal(plaintext)
            return mapOf(
                "ciphertext" to ciphertext,
                "iv" to cipher.iv
            )
        }

        private fun decrypt(ciphertext: ByteArray, iv: ByteArray): ByteArray {
            val key = getKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_LENGTH, iv))
            return cipher.doFinal(ciphertext)
        }

        private fun deleteKey() {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS)
            }
        }

        private fun getKey(): SecretKey {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            return keyStore.getKey(KEY_ALIAS, null) as SecretKey
        }
    }
}

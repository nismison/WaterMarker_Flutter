import org.gradle.api.GradleException
import java.io.File
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * CI 环境变量约定（P12 / PKCS12）：
 * - ANDROID_KEYSTORE_BASE64 : p12 文件的 base64（可含换行）
 * - ANDROID_STORE_PASSWORD  : 密钥库口令（你当前只有这一个口令）
 * - ANDROID_KEY_ALIAS       : alias（可选；默认 watermarkerv2）
 * - ANDROID_KEY_PASSWORD    : 私钥口令（可选；默认等于 storePassword）
 *
 * Hard-fail 策略：
 * - 只要执行的是 release 相关任务（assembleRelease / bundleRelease / ...），必须有签名信息，否则直接失败。
 */

data class SigningData(
    val storeFile: File,
    val storePassword: String,
    val keyAlias: String,
    val keyPassword: String,
)

fun isReleaseBuildInvocation(): Boolean {
    val tasks = gradle.startParameter.taskNames.joinToString(" ").lowercase()
    return tasks.contains("release")
}

val isReleaseBuild: Boolean = isReleaseBuildInvocation()

fun requiredEnv(name: String): String {
    val v = System.getenv(name)?.trim()
    if (v.isNullOrEmpty()) {
        throw GradleException("Missing required env var: $name (release signing is mandatory)")
    }
    return v
}

fun optionalEnv(name: String): String? =
    System.getenv(name)?.trim().takeUnless { it.isNullOrEmpty() }

// 显式类型：避免 Kotlin DSL 推断成 Any
val signing: SigningData? = if (isReleaseBuild) {
    val base64 = requiredEnv("ANDROID_KEYSTORE_BASE64")
    val storePass = requiredEnv("ANDROID_STORE_PASSWORD")
    val alias = optionalEnv("ANDROID_KEY_ALIAS") ?: "watermarkerv2"
    val keyPass = optionalEnv("ANDROID_KEY_PASSWORD") ?: storePass

    // 解码并写入到 android/build/keystores/release.p12（不进仓库）
    val outDir = rootProject.layout.buildDirectory.dir("keystores").get().asFile.apply { mkdirs() }
    val p12File = File(outDir, "release.p12")

    try {
        // 兼容 base64 含换行：MIME decoder
        val decoded = Base64.getMimeDecoder().decode(base64)
        p12File.writeBytes(decoded)
    } catch (e: Exception) {
        throw GradleException("Failed to decode ANDROID_KEYSTORE_BASE64 as PKCS12 (.p12).", e)
    }

    if (!p12File.exists() || p12File.length() == 0L) {
        throw GradleException("Decoded keystore file is empty: ${p12File.absolutePath}")
    }

    SigningData(
        storeFile = p12File,
        storePassword = storePass,
        keyAlias = alias,
        keyPassword = keyPass,
    )
} else {
    null
}

android {
    namespace = "com.watermarker.v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        @Suppress("DEPRECATION")
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.watermarker.v2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (isReleaseBuild) {
            val s = signing ?: throw GradleException("Internal error: signing data is null in release build.")
            create("release") {
                storeFile = s.storeFile
                storePassword = s.storePassword
                keyAlias = s.keyAlias
                keyPassword = s.keyPassword
                storeType = "PKCS12"
            }
        }
    }

    buildTypes {
        release {
            if (!isReleaseBuild) {
                // 防止出现“选了 release buildType，但任务名不含 release”的异常情况
                throw GradleException("Release buildType selected but Gradle task names do not contain 'release'.")
            }
            signingConfig = signingConfigs.getByName("release")

            // 可选：按需开启/配置混淆；Flutter 默认通常没问题
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}

// ==== 修复 R8 Release 构建失败问题 ====
// 排除 desktop-only 的 zxing / jai-imageio / javax.imageio 依赖
configurations.all {
    exclude(group = "com.google.zxing", module = "javase")
    exclude(group = "com.github.jai-imageio")
    exclude(group = "javax.imageio")
}

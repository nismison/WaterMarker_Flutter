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
 * - 只要是 Release 构建（assembleRelease / bundleRelease / ...），必须提供签名环境变量，否则直接失败。
 */

val env = System.getenv()

val keystoreBase64 = env["ANDROID_KEYSTORE_BASE64"]?.trim()
val storePassword = env["ANDROID_STORE_PASSWORD"]?.trim()
val keyAlias = env["ANDROID_KEY_ALIAS"]?.trim().takeUnless { it.isNullOrBlank() } ?: "watermarkerv2"
val keyPassword =
    env["ANDROID_KEY_PASSWORD"]?.trim().takeUnless { it.isNullOrBlank() } ?: storePassword

fun isReleaseTaskInvocation(): Boolean {
    // CI 下 flutter build apk --release 最终会触发 assembleRelease / bundleRelease 等
    val tasks = gradle.startParameter.taskNames.joinToString(" ").lowercase()
    return tasks.contains("release")
}

val isReleaseBuild = isReleaseTaskInvocation()

fun requireEnv(name: String, value: String?) {
    if (value.isNullOrBlank()) {
        throw GradleException("Missing required env var: $name (release signing is mandatory)")
    }
}

val releaseKeystoreFile: File? = if (isReleaseBuild) {
    requireEnv("ANDROID_KEYSTORE_BASE64", keystoreBase64)
    requireEnv("ANDROID_STORE_PASSWORD", storePassword)
    // alias / keyPassword 有默认值，但仍做一次兜底校验（避免误传空字符串）
    requireEnv("ANDROID_KEY_ALIAS", keyAlias)
    requireEnv("ANDROID_KEY_PASSWORD", keyPassword)

    val dir = rootProject.layout.buildDirectory.dir("keystores").get().asFile
    if (!dir.exists()) dir.mkdirs()

    val f = File(dir, "release.p12")

    try {
        // MIME decoder 兼容 base64 含换行
        val decoded = Base64.getMimeDecoder().decode(keystoreBase64!!)
        f.writeBytes(decoded)
    } catch (e: Exception) {
        throw GradleException("Failed to decode ANDROID_KEYSTORE_BASE64 as PKCS12 (.p12).", e)
    }

    if (!f.exists() || f.length() == 0L) {
        throw GradleException("Decoded keystore file is empty: ${f.absolutePath}")
    }

    f
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
        // Release 构建：强制要求签名配置存在（缺环境变量会在上面直接 GradleException）
        if (isReleaseBuild) {
            create("release") {
                storeFile = releaseKeystoreFile!!
                storePassword = storePassword!!
                keyAlias = keyAlias
                keyPassword = keyPassword!!

                // p12 必须 PKCS12
                storeType = "PKCS12"
            }
        }
    }

    buildTypes {
        release {
            // hard-fail：Release 一律使用 release signingConfig（不存在会直接报错）
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

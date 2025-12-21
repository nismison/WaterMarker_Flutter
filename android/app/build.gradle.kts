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
 * - 只要“本次构建会产出 release 变体”，必须有签名信息，否则直接失败。
 *
 * 注意：
 * - Gradle 会在“配置阶段”配置所有 buildTypes（包括 release），即使你只跑 assembleDebug。
 *   因此禁止在 buildTypes.release { ... } 中基于任务名直接 throw，否则 debug 也会被误杀。
 */

data class SigningData(
    val storeFile: File,
    val storePassword: String,
    val keyAlias: String,
    val keyPassword: String,
)

fun requiredEnv(name: String): String {
    val v = System.getenv(name)?.trim()
    if (v.isNullOrEmpty()) {
        throw GradleException("Missing required env var: $name (release signing is mandatory)")
    }
    return v
}

fun optionalEnv(name: String): String? =
    System.getenv(name)?.trim().takeUnless { it.isNullOrEmpty() }

/**
 * 判断“本次 Gradle invocation 是否会构建 release”。
 * 说明：
 * - flutter build apk --release 通常会触发 assembleRelease（包含 release）
 * - ./gradlew build / assemble / bundle 这类无变体任务往往会包含 release
 * - Android Studio/IDE 的 sync 场景 taskNames 可能为空，此时不应强制签名
 */
fun willBuildReleaseFromStartParameter(): Boolean {
    val tasks = gradle.startParameter.taskNames.map { it.lowercase() }
    if (tasks.isEmpty()) return false

    // 明确包含 release
    if (tasks.any { it.contains("release") }) return true

    // 无变体的聚合任务，通常会产出所有变体（包含 release）
    val multiVariant = setOf("build", "assemble", "bundle")
    if (tasks.any { it in multiVariant }) return true
    if (tasks.any { t -> multiVariant.any { mv -> t.endsWith(":$mv") } }) return true

    return false
}

val isReleaseBuild: Boolean = willBuildReleaseFromStartParameter()

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
        // debug 配置本来就存在，这里显式引用，便于 release initWith(debug) 兜底
        getByName("debug")

        /**
         * 关键点：release signingConfig 必须“始终存在”，否则 debug 构建在配置 release buildType 时
         * 可能因为引用 signingConfig 而在配置阶段报错。
         *
         * - debug 构建：release signingConfig 用 debug 配置兜底（不会影响最终产物，因为不会执行 release 任务）
         * - release 构建：强制要求 env，并用 p12 正式配置
         */
        create("release") {
            if (isReleaseBuild) {
                val s = signing ?: throw GradleException("Internal error: signing data is null in release build.")
                storeFile = s.storeFile
                storePassword = s.storePassword
                keyAlias = s.keyAlias
                keyPassword = s.keyPassword
                storeType = "PKCS12"
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            // 注意：不要在这里根据任务名 throw；配置阶段会执行到这里
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

/**
 * 额外兜底：当执行图里真的包含 release 相关任务时，必须具备 signing。
 * 这能覆盖少数“startParameter 不明显但 taskGraph 最终包含 release”的情况。
 */
gradle.taskGraph.whenReady {
    val willRunRelease = allTasks.any { it.name.contains("release", ignoreCase = true) }
    if (willRunRelease && signing == null) {
        throw GradleException(
            "Release tasks detected but signing env vars are missing. " +
                    "Please set ANDROID_KEYSTORE_BASE64 / ANDROID_STORE_PASSWORD " +
                    "(and optionally ANDROID_KEY_ALIAS / ANDROID_KEY_PASSWORD)."
        )
    }
}

// ==== 修复 R8 Release 构建失败问题 ====
// 排除 desktop-only 的 zxing / jai-imageio / javax.imageio 依赖
configurations.all {
    exclude(group = "com.google.zxing", module = "javase")
    exclude(group = "com.github.jai-imageio")
    exclude(group = "javax.imageio")
}

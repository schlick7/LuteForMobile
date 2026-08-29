import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.chaquo.python")
}

buildscript {
    extra["kotlinVersion"] = "2.3.20"
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.schlick7.luteformobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file("$it") }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.schlick7.luteformobile"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Chaquopy needs the arm64-v8a ABI; we ship a single-arch APK
        // for the on-device server. Other ABIs (x86_64 for emulators)
        // can be added later if needed.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }

        // Tell Flutter to use Chaquopy's PyApplication as the base
        // Application class. PyApplication initializes the Python
        // runtime on app launch; the Kotlin bridge then calls into
        // Python via com.chaquo.python.Python.
        manifestPlaceholders["applicationName"] =
            "com.chaquo.python.android.PyApplication"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}

chaquopy {
    defaultConfig {
        // Pin to the same Python version the upstream lute-v3 supports.
        version = "3.11"

        // lute needs its .sql migration files to be on disk at
        // runtime (lute.db.setup reads them via open()). Chaquopy
        // normally only extracts .py/.pyc, but adding lute to
        // extractPackages makes it copy the whole subtree (including
        // schema/migrations/*.sql) to the device on first import.
        extractPackages("lute")

        // The host system has uv-managed Python shims at
        // /home/cody/.local/bin/python3.11 which Chaquopy's venv
        // setup can't use directly. Point at the real CPython 3.11
        // binary so pip bootstraps correctly.
        buildPython("/home/cody/.local/share/uv/python/cpython-3.11.13-linux-x86_64-gnu/bin/python3.11")

        // We don't need pip / ensurepip in the APK; everything is
        // pre-bundled as source.
        pip {
            install("flask>=3.0,<4")
            install("flask-sqlalchemy>=3.1,<4")
            install("flask-wtf>=1.2,<2")
            install("waitress>=2.1,<3")
            install("beautifulsoup4>=4.12,<5")
            install("pypdf>=3.17,<5")
            install("requests>=2.31,<3")
            install("pyyaml>=6.0,<7")
            install("toml>=0.10,<1")
            install("pyparsing>=3.1,<4")
            install("ahocorapy>=1.6,<2")
            install("openepub>=0.0.8,<1")
            install("subtitle-parser>=1.3,<2")
            install("platformdirs>=3.10,<4")
            install("jinja2>=3.1,<4")
            install("jaconv>=0.3,<1")
        }
    }
}

dependencies {
    implementation("androidx.documentfile:documentfile:1.0.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}

flutter {
    source = "../.."
}

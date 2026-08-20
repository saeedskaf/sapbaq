import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Maps API key, injected at build time so it never lives in source
// control. Looks in android/local.properties (MAPS_API_KEY=...) first, then the
// MAPS_API_KEY environment variable, and finally falls back to an empty string
// so the build still succeeds without it (maps just won't render). Restrict the
// key by package name (com.albairakgroup.sapbaq) + SHA-1 in Google Cloud.
val mapsApiKey: String = Properties().run {
    val localProperties = rootProject.file("local.properties")
    if (localProperties.exists()) localProperties.inputStream().use { load(it) }
    getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY") ?: ""
}

// Release signing. Credentials live in android/key.properties (git-ignored, see
// key.properties.example) so the keystore and its passwords never enter source
// control. Without that file the release build falls back to the debug keystore
// so `flutter run --release` still works locally — but Play rejects a
// debug-signed upload, hence the loud warning below.
val keystoreProperties = Properties().apply {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) keystoreFile.inputStream().use { load(it) }
}
val hasReleaseKeystore: Boolean = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.albairakgroup.sapbaq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (backports java.time on older
        // Android via the desugared library declared in dependencies below).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.albairakgroup.sapbaq"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Google Maps requires minSdk 21+.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Exposed to AndroidManifest.xml as ${MAPS_API_KEY}.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // No keystore on this machine: fall back so `flutter run
                // --release` still works. Google Play REJECTS such a build.
                logger.warn(
                    "WARNING: android/key.properties not found — the release " +
                        "build is signed with the DEBUG keystore and cannot be " +
                        "uploaded to Google Play."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring — required by flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials. `key.properties` holds the passwords and points at a
// keystore kept OUTSIDE the repo; both are gitignored (android/.gitignore) because a
// leaked upload key lets anyone publish updates as us. On a fresh clone the file is
// absent, and we fall back to debug signing so the project still builds — such a build
// runs fine on a device but Play will reject it.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.unchained.unchained"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // The app's permanent identity on Google Play. `com.unchained.app` could not
        // be used: it is already registered to a different developer, which Play
        // surfaces as a content-provider authority clash on
        // `com.unchained.app.androidx-startup`. Once a build is published this value
        // can never change — a different applicationId is a different app to both
        // Android and Play, with its own installs, reviews and stored data.
        // Note this is deliberately NOT the same as `namespace` above: namespace is
        // the Kotlin/BuildConfig package (unchanged, so no source or the DEV_GUARD
        // broadcast action moves), applicationId is the installed identity.
        applicationId = "com.beunchained.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload key when key.properties is present, debug key otherwise so a
            // fresh clone still builds. NOTE: switching a device from a debug-signed
            // build to a release-signed one requires uninstalling first — Android
            // refuses to replace an app with one signed by a different key.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

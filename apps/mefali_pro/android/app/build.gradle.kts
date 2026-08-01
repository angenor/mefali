plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ci.mefali.mefali_pro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Exigé par `flutter_local_notifications` (CRS-02, US7) : la sonnerie
        // d'offre programme des alarmes via les API de date/heure de Java 8,
        // absentes des API Android sous la minSdk du projet. Sans ce drapeau,
        // `assembleDebug` ÉCHOUE — aucun `flutter test` ne le voit, ils
        // tournent sur la VM Dart de l'hôte.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ci.mefali.mefali_pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Contrepartie de `isCoreLibraryDesugaringEnabled` : la bibliothèque qui
    // fournit `java.time` aux niveaux d'API qui ne l'ont pas.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

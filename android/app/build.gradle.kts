import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Keystore Özelliklerini Yükleme ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.karaosman.arrow_puzzle"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.karaosman.arrow_puzzle"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- İmzalama Ayarları (Signing Configs) ---
    signingConfigs {
        create("release") {
            // getProperty kullanarak String olarak verileri güvenli çekiyoruz
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")

            // Dosya yolu null değilse file() fonksiyonuna veriyoruz
            val storeFileVal = keystoreProperties.getProperty("storeFile")
            if (storeFileVal != null) {
                storeFile = file(storeFileVal)
            }
        }
    }

    buildTypes {
        release {
            // Release modunda yukarıdaki 'release' imzasını kullan
            signingConfig = signingConfigs.getByName("release")

            // Küçültme ve karıştırma ayarları (İsteğe bağlı - false kalabilir)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
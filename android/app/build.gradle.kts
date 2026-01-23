plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")// The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
}

// Load Keystore
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.azdhaar.notesapp"
    compileSdk = 36
    ndkVersion =  "27.0.12077973" // flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // kotlinOptions {
    //     jvmTarget = "17"
    // }

    // App Signing
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.azdhaar.notesapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        named("release") {
            signingConfig = signingConfigs.release
            isMinifyEnabled = true
            isShrinkResources = true
        }
        named("profile") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    val core_version = "1.15.0"
    
    implementation("androidx.core:core:$core_version")      // Java language implementation
    implementation("androidx.core:core-ktx:$core_version")  // Kotlin
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    implementation("com.github.Yalantis:ucrop:2.2.11") {
        exclude(group = "com.github.Yalantis", module = "ucrop") // Exclude older versions from transitive dependencies
    }
}

configurations.all {
    resolutionStrategy {
        val core_version = "1.15.0"
        force("androidx.core:core:$core_version")      // Java language implementation
        force("androidx.core:core-ktx:$core_version")  // Kotlin
        force("com.github.Yalantis:ucrop:2.2.11")
    }
}

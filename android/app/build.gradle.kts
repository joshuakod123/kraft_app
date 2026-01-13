plugins {
    id("com.android.application")
    id("kotlin-android") // 또는 id("org.jetbrains.kotlin.android")
    // 필요한 플러그인이 있다면 여기에 더 있을 수 있습니다.
}

// 1. key.properties 파일 불러오는 마법의 코드
import java.util.Properties
        import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.joshuakod.kraft_app"// 본인의 패키지 이름인지 확인!
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.joshuakod.kraft_app" // 본인의 앱 ID인지 확인!
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. 서명 설정 (도장 정보 가져오기)
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    // 3. 빌드 타입 설정 (여기가 아까 에러 났던 곳!)
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
plugins {
    id("com.android.application")
    kotlin("android")
}

dependencies {
    implementation(project(":passiveData"))
    //implementation("com.google.android.material:material:1.7.0")
    //implementation("androidx.appcompat:appcompat:1.5.1")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}

android {
    compileSdk = 32
    defaultConfig {
        applicationId = "org.sagebionetworks.assessmentmodel.passivedata.android"
        minSdk = 21
        targetSdk = 31
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false

            packagingOptions {
                resources.excludes += "DebugProbesKt.bin"
            }
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
}
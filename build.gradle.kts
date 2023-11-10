buildscript {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${Versions.kotlin}")
        classpath("com.android.tools.build:gradle:8.1.2")
        classpath("org.jetbrains.kotlin:kotlin-serialization:${Versions.kotlin}")
    }
}

plugins {
    id("org.jetbrains.dokka") version Versions.kotlin
    id("maven-publish")
}

allprojects {
    group = "org.sagebionetworks.research.kmm"
    version = "0.6.0"
    repositories {
        google()
        mavenCentral()
        maven(url = "https://sagebionetworks.jfrog.io/artifactory/mobile-sdks/")
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

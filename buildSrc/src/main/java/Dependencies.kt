object Versions {

    const val assessmentVersion = "1.1.3"

    const val kotlinxDateTime = "0.4.1"

    const val kotlin = "1.9.10"
    const val kotlinxSerializationJson = "1.6.0"
    const val kotlinCoroutines = "1.7.2"

    const val ktor = "2.3.2"

    const val koin = "3.1.5"

    const val napier = "2.1.0"
}

object Deps {

    object Napier {
        val napier = "io.github.aakira:napier:${Versions.napier}"
    }

    object KotlinX {
        val dateTime = "org.jetbrains.kotlinx:kotlinx-datetime:${Versions.kotlinxDateTime}"
        val serializationJson =
            "org.jetbrains.kotlinx:kotlinx-serialization-json:${Versions.kotlinxSerializationJson}"
    }

    object AssessmentModel {
        val results =
            "org.sagebionetworks.assessmentmodel:assessmentresults:${Versions.assessmentVersion}"
    }

    object Ktor {
        val clientCore = "io.ktor:ktor-client-core:${Versions.ktor}"
        val clientContentNegotion = "io.ktor:ktor-client-content-negotiation:${Versions.ktor}"
        val clientMock = "io.ktor:ktor-client-mock:${Versions.ktor}"

        val clientLogging = "io.ktor:ktor-client-logging:${Versions.ktor}"
        val clientSerialization = "io.ktor:ktor-serialization-kotlinx-json:${Versions.ktor}"

        val clientAndroid = "io.ktor:ktor-client-android:${Versions.ktor}"
        val clientIos = "io.ktor:ktor-client-ios:${Versions.ktor}"
    }

    object Coroutines {
        val core = "org.jetbrains.kotlinx:kotlinx-coroutines-core:${Versions.kotlinCoroutines}"
        val android =
            "org.jetbrains.kotlinx:kotlinx-coroutines-android:${Versions.kotlinCoroutines}"
        val test = "org.jetbrains.kotlinx:kotlinx-coroutines-test:${Versions.kotlinCoroutines}"
    }

    object Koin {
        val core = "io.insert-koin:koin-core:${Versions.koin}"
        val test = "io.insert-koin:koin-test:${Versions.koin}"
        val android = "io.insert-koin:koin-android:${Versions.koin}"
        val androidWorkManager =  "io.insert-koin:koin-androidx-workmanager:${Versions.koin}"
    }
}

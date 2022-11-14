package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class AirQualityServiceIntegrationTest {
    @Test
    fun testRemoteCall() {
        val airQualityServiceApiKey = System.getProperty("airNowApiKey")

        val httpClient = HttpClient {
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                })
            }
        }

        val serviceConfiguration = WeatherServiceConfiguration(
            "weatherServiceConfig",
            WeatherServiceProviderName.AIR_NOW,
            airQualityServiceApiKey!!
        )

        val service = AirQualityService(
            serviceConfiguration,
            httpClient
        )

        val airQualityServiceResult = runBlocking {
            service.getResult(
                Location(
                    -122.22,
                    37.48
                )
            )
        } as AirQualityServiceResult

        val json = kotlinx.serialization.json.Json {
            prettyPrint = true
        }
        assertNotNull(airQualityServiceResult)
        assertEquals(WeatherServiceProviderName.AIR_NOW, airQualityServiceResult.providerName)
    }
}
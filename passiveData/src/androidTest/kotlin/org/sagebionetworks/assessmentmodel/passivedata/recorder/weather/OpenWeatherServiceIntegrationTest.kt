package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class OpenWeatherServiceIntegrationTest {
    @Test
    fun testRemoteCall() {
        val openWeatherApiKey = System.getProperty("openWeatherApiKey")

        val httpClient = HttpClient {
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                })
            }
        }

        val serviceConfiguration = WeatherServiceConfiguration(
            "weatherServiceConfig",
            WeatherServiceProviderName.OPEN_WEATHER,
            openWeatherApiKey!!
        )

        val service = OpenWeatherService(
            serviceConfiguration,
            httpClient
        )

        val weatherServiceResult = runBlocking {
            service.getResult(
                Location(
                    166.0,
                    42.0
                )
            )
        } as WeatherServiceResult

        val json = kotlinx.serialization.json.Json {
            prettyPrint = true
        }
        println(json.encodeToString(weatherServiceResult))
        assertNotNull(weatherServiceResult)
        assertEquals(WeatherServiceProviderName.OPEN_WEATHER, weatherServiceResult.providerName)
    }
}
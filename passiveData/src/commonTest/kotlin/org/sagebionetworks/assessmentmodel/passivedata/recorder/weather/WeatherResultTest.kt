package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.modules.plus
import org.sagebionetworks.assessmentmodel.Result
import org.sagebionetworks.assessmentmodel.passivedata.resultDataSerializersModule
import kotlin.test.*

class WeatherResultTest {
    @Serializable
    class ResultDataWrapper(val resultData: Result)

    val jsonCoder = Json {
        serializersModule += resultDataSerializersModule
        ignoreUnknownKeys = true
    }

    @Test
    fun testPolymorphicSerialization() {

        val weatherResult: Result =
            WeatherResult("identifier", weather = null, airQuality = null)


        val json = jsonCoder.encodeToString(ResultDataWrapper(weatherResult))

        val deserialized = jsonCoder.decodeFromString<ResultDataWrapper>(json)

        assertTrue(deserialized.resultData is WeatherResult)
    }

    @Test
    fun testNullResult() {
        val weatherResult = WeatherResult("identifier", weather = null, airQuality = null)

        val json = weatherResult.getJsonArchivableFile("foo").json
        val deserialized = Json.decodeFromString<JsonObject>(json)

        assertNull(deserialized["weather"])
        assertNull(deserialized["airQuality"])
        assertFalse(json.contains("null"))
    }

    @Test
    fun testDeserialization() {
        val result = jsonCoder.decodeFromString<WeatherResult>(sampleJsonUpload)

        val expectedResult = WeatherResult(
            identifier = "weather",
            startDateTime = Instant.parse("2021-09-20T16:34:47.782-07:00"),
            endDateTime = Instant.parse("2021-09-20T16:34:47.782-07:00"),
            airQuality = AirQualityServiceResult(
                identifier = "airQuality",
                startDateTime = Instant.parse("2021-09-20T16:34:48.839-07:00"),
                providerName = WeatherServiceProviderName.AIR_NOW,
                aqi = 57,
                category = AirQualityServiceResult.Category(2, "Moderate")
            ),
            weather = WeatherServiceResult(
                identifier = "weather",
                providerName = WeatherServiceProviderName.OPEN_WEATHER,
                startDateTime = Instant.parse("2021-09-20T16:30:19.000-07:00"),
                temperature = 28.960000000000001,
                seaLevelPressure = 1014.0,
                wind = WeatherServiceResult.Wind(
                    speed = 3.6000000000000001,
                    degrees = 230.0
                ),
                humidity = 33.0,
                clouds = 1.0
            )
        )

        assertEquals(expectedResult, result)

        val roundTripResult = jsonCoder.decodeFromString<WeatherResult>(
            jsonCoder.encodeToString(result)
        )

        // ensure symmetric
        assertEquals(expectedResult, roundTripResult)
    }
}

// json from iOS upload archive
val sampleJsonUpload =
    """
        {
          "weather": {
            "clouds": 1,
            "humidity": 33,
            "provider": "openWeather",
            "startDate": "2021-09-20T16:30:19.000-07:00",
            "wind": {
              "speed": 3.6000000000000001,
              "degrees": 230
            },
            "seaLevelPressure": 1014,
            "temperature": 28.960000000000001,
            "identifier": "weather",
            "type": "weather"
          },
          "airQuality": {
            "category": {
              "number": 2,
              "name": "Moderate"
            },
            "provider": "airNow",
            "startDate": "2021-09-20T16:34:48.839-07:00",
            "type": "airQuality",
            "identifier": "airQuality",
            "aqi": 57
          },
          "startDate": "2021-09-20T16:34:47.782-07:00",
          "type": "weather",
          "identifier": "weather",
          "endDate": "2021-09-20T16:34:47.782-07:00"
        }
    """.trimIndent()
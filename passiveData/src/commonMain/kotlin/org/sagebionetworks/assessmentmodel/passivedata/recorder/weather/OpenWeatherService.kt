package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.github.aakira.napier.Napier
import io.ktor.client.*
import io.ktor.client.call.*
import org.sagebionetworks.assessmentmodel.Result
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

class OpenWeatherService(
    override val configuration: WeatherServiceConfiguration,
    val httpClient: HttpClient
) : WeatherService {
    override suspend fun getResult(location: Location): Result {
        val url =
            "https://api.openweathermap.org/data/2.5/weather" +
                    "?lat=${location.latitude}&lon=${location.longitude}" +
                    "&units=metric&appid=${configuration.apiKey}"

        val builder = HttpRequestBuilder()
        with(builder) {
            method = HttpMethod.Get
            url(url)
            header("Accept", "application/json")
        }

        return httpClient.get(builder).body<Response>()
            .toWeatherServiceResult(configuration.identifier)
    }

    @Serializable
    data class Response(
        val main: Main,
        val wind: Wind? = null,
        val clouds: Clouds? = null,
        val rain: Precipitation? = null,
        val snow: Precipitation? = null,
        @Serializable(with = InstantEpochSecondsSerializer::class)
        val dt: Instant

    ) {
        companion object {
            val jsonCoder = Json {
                ignoreUnknownKeys = true
                useAlternativeNames = false
            }
        }

        @Serializable
        data class Main(
            // Temperature
            // Unit: Celsius
            val temp: Double? = null,
            // Temperature. This temperature parameter accounts for the human perception of weather.
            // Unit: Celsius
            val feels_like: Double? = null,
            // Minimum temperature at the moment. This is minimal currently observed temperature
            // (within large megalopolises and urban areas).
            // Unit: Celsius
            val temp_min: Double? = null,
            // Maximum temperature at the moment. This is maximal currently observed temperature
            // (within large megalopolises and urban areas).
            // Unit: Celsius
            val temp_max: Double? = null,
            // Atmospheric pressure (on the sea level, if there is no sea_level or grnd_level data)
            // Unit: hPa
            val pressure: Double? = null,
            // Atmospheric pressure on the sea level
            // Unit: hPa
            val sea_level: Double? = null,
            // Atmospheric pressure on the ground level
            // Unit: hPa
            val grnd_level: Double? = null,
            // Humidity
            // Unit: %
            val humidity: Double? = null
        ) {
            val seaLevel: Double?
                get() = sea_level ?: if (grnd_level == null) {
                    pressure
                } else null

        }

        @Serializable
        data class Wind(
            // Wind speed. Unit: meter/sec
            val speed: Double? = null,
            // Wind direction, degrees (meteorological)
            val deg: Double? = null,
            // Wind gust. Unit Default: meter/sec
            val gust: Double? = null
        ) {
            fun toWeatherServiceResult(): WeatherServiceResult.Wind? {
                return speed?.let {
                    WeatherServiceResult.Wind(
                        speed, deg, gust

                    )
                }
            }
        }

        @Serializable
        data class Clouds(
            // Cloudiness, %
            val all: Double
        )

        @Serializable
        data class Precipitation(
            @SerialName("1hr")
            val pastHour: Double? = null,
            @SerialName("3hr")
            val pastThreeHours: Double? = null
        ) {
            fun toWeatherServiceResult(): WeatherServiceResult.Precipitation {
                return WeatherServiceResult.Precipitation(
                    pastHour, pastThreeHours
                )
            }
        }

        fun toWeatherServiceResult(identifier: String): WeatherServiceResult {
            Napier.d("Converting WeatherServiceResult: $this")
            return WeatherServiceResult(
                identifier = identifier,
                providerName = WeatherServiceProviderName.OPEN_WEATHER,
                startDateTime = dt,
                temperature = main.temp,
                seaLevelPressure = main.seaLevel,
                groundLevelPressure = main.grnd_level,
                humidity = main.humidity,
                clouds = clouds?.all,
                rain = rain?.toWeatherServiceResult(),
                snow = snow?.toWeatherServiceResult(),
                wind = wind?.toWeatherServiceResult()
            )
        }
    }

}
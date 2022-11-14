package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import io.github.aakira.napier.Napier
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.passivedata.ResultData

class AirQualityService(
    override val configuration: WeatherServiceConfiguration,
    val httpClient: HttpClient
) : WeatherService {

    @ExperimentalSerializationApi
    override suspend fun getResult(location: Location): ResultData {

        val startTime = Clock.System.now()
        val dateString = startTime.toLocalDateTime(TimeZone.currentSystemDefault()).date.toString()

        val url = "https://www.airnowapi.org/aq/forecast/latLong/?format=application/json" +
                "&latitude=${location.latitude}&longitude=${location.longitude}" +
                "&date=${dateString}&distance=25&&API_KEY=${configuration.apiKey}"

        val builder = HttpRequestBuilder()
        with(builder) {
            method = HttpMethod.Get
            url(url)
            header("Accept", "application/json")
        }

        return (::handleResponse)(
            httpClient.get(builder).body(),
            configuration,
            dateString,
            startTime
        )
    }

    companion object {

        @ExperimentalSerializationApi
        internal fun handleResponse(
            response: List<Response>,
            configuration: WeatherServiceConfiguration,
            dateString: String,
            startTime: Instant
        ): AirQualityServiceResult {
            return response.firstOrNull {
                it.dateForecast.trim() == dateString
            }?.toAirQualityServiceResult(configuration.identifier, startTime) ?: let {
                Napier.w(
                    "Failed to find valid response from " +
                            "${configuration.providerName}: dateString=$dateString"
                )
                throw IllegalStateException("No valid dateForecast was returned.")
            }
        }
    }

    @Serializable
    data class Response(
        @SerialName("DateIssue")
        val dateIssue: String,
        @SerialName("DateForecast")
        val dateForecast: String,
        @SerialName("StateCode")
        val stateCode: String? = null,
        @SerialName("AQI")
        val aqi: Int? = null,
        @SerialName("Category")
        val category: Category? = null
    ) {
        @Serializable
        data class Category(
            @SerialName("Number")
            val number: Int,
            @SerialName("Name")
            val name: String
        )

        fun toAirQualityServiceResult(
            identifier: String,
            startDate: Instant
        ): AirQualityServiceResult {
            Napier.d("Converting AirQualityServiceResult: $this")
            return AirQualityServiceResult(
                identifier = identifier,
                providerName = WeatherServiceProviderName.AIR_NOW,
                startDate = startDate,
                aqi = aqi,
                category = category?.let {
                    AirQualityServiceResult.Category(category.number, category.name)

                }
            )
        }
    }
}
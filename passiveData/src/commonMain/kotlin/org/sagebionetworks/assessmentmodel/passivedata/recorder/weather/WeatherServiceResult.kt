package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.Result
import org.sagebionetworks.assessmentmodel.serialization.InstantSerializer

@Serializable
@SerialName(WeatherServiceTypeStrings.TYPE_WEATHER)
data class WeatherServiceResult(
    override val identifier: String,
    @SerialName("provider")
    val providerName: WeatherServiceProviderName,
    @SerialName("startDate")
    @Serializable(with = InstantSerializer::class)
    override var startDateTime: Instant,
    val temperature: Double? = null,
    val seaLevelPressure: Double? = null,
    val groundLevelPressure: Double? = null,
    val humidity: Double? = null,
    val clouds: Double? = null,
    val rain: Precipitation? = null,
    val snow: Precipitation? = null,
    val wind: Wind? = null
) : Result {
    @SerialName("endDate")
    @Serializable(with = InstantSerializer::class)
    override var endDateTime: Instant?
        get() = startDateTime
        set(value) {}

    override fun copyResult(identifier: String): WeatherServiceResult {
        return copy(identifier = identifier)
    }

    @Serializable
    data class Precipitation(val pastHour: Double? = null, val pastThreeHours: Double? = null)

    @Serializable
    data class Wind(val speed: Double, val degrees: Double? = null, val gust: Double? = null)

}


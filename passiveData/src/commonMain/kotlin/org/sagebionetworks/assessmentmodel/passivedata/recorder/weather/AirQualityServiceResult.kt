package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import org.sagebionetworks.assessmentmodel.Result
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceTypeStrings.TYPE_AIR_QUALITY
import org.sagebionetworks.assessmentmodel.serialization.InstantSerializer

@Serializable
@SerialName(TYPE_AIR_QUALITY)
data class AirQualityServiceResult(
    override val identifier: String,
    @SerialName("provider")
    val providerName: WeatherServiceProviderName,
    @SerialName("startDate")
    @Serializable(with = InstantSerializer::class)
    override var startDateTime: Instant,
    val aqi: Int?,
    val category: Category?
) : Result {
    @SerialName("endDate")
    @Serializable(with = InstantSerializer::class)
    override var endDateTime: Instant?
        get() = this.startDateTime
        set(value) {}

    override fun copyResult(identifier: String): AirQualityServiceResult {
        return copy(identifier = identifier)
    }

    @Serializable
    data class Category(
        val number: Int,
        val name: String
    )
}

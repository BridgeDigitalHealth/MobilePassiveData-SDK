package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.sagebionetworks.assessmentmodel.JsonArchivableFile
import org.sagebionetworks.assessmentmodel.JsonFileArchivableResult
import org.sagebionetworks.assessmentmodel.Result
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceTypeStrings.TYPE_WEATHER
import org.sagebionetworks.assessmentmodel.serialization.InstantSerializer

@Serializable
@SerialName(TYPE_WEATHER)
data class WeatherResult(
    override val identifier: String,
    @SerialName("startDate")
    @Serializable(with = InstantSerializer::class)
    override var startDateTime: Instant = Clock.System.now(),
    @SerialName("endDate")
    @Serializable(with = InstantSerializer::class)
    override var endDateTime: Instant? = Clock.System.now(),
    val weather: WeatherServiceResult?,
    val airQuality: AirQualityServiceResult?
) : JsonFileArchivableResult {

    override fun copyResult(identifier: String): WeatherResult {
        return copy(identifier = identifier)
    }

    override fun getJsonArchivableFile(stepPath: String): JsonArchivableFile {
        return JsonArchivableFile(
            filename = "$identifier.json",
            json = Json.encodeToString(this),
            jsonSchema = "https://sage-bionetworks.github.io/mobile-client-json/schemas/v2/WeatherResult.json"
        )
    }

}


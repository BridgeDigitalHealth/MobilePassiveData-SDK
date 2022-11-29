package org.sagebionetworks.assessmentmodel.passivedata

import kotlinx.datetime.Instant
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherResult
import org.sagebionetworks.assessmentmodel.serialization.InstantSerializer

val resultDataSerializersModule = SerializersModule {
    polymorphic(org.sagebionetworks.assessmentmodel.Result::class) {
        subclass(WeatherResult::class)
    }
    contextual(Instant::class, InstantSerializer)
}
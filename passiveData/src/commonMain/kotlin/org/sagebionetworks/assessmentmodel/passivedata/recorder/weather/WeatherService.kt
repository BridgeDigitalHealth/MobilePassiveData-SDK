package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import org.sagebionetworks.assessmentmodel.Result

interface WeatherService {
    val configuration: WeatherServiceConfiguration
    suspend fun getResult(location: Location): Result
}

data class Location(val longitude: Double, val latitude: Double)
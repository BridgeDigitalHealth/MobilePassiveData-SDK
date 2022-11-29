package org.sagebionetworks.assessmentmodel.passivedata.asyncaction.result.weather

import kotlinx.datetime.Instant
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.AirQualityService
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.recorder.weather.WeatherServiceProviderName
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

@ExperimentalSerializationApi
class AirQualityServiceResponseTest {

    private val jsonCoder = Json {
        ignoreUnknownKeys = true
    }

    @Test
    fun testDeserialize() {
        val result = jsonCoder.decodeFromString<List<AirQualityService.Response>>(sampleJson2)

        assertEquals(3, result.size)
        with(result[1]) {
            assertEquals("CA", stateCode)
            assertEquals(57, aqi)

            assertNotNull(category)
            assertEquals(2, category!!.number)
            assertEquals("Moderate", category!!.name)
        }
    }

    @Test
    fun testServiceResultHandling() {
        val deserializedresult =
            jsonCoder.decodeFromString<List<AirQualityService.Response>>(sampleJson)

        val startTime = Instant.parse("2021-10-03T12:01:25Z")
        val dateString = "2021-10-04"
        val response = AirQualityService.handleResponse(
            deserializedresult,
            WeatherServiceConfiguration("resultId", WeatherServiceProviderName.AIR_NOW, "apiKey"),
            dateString,
            startTime
        )
        with(response) {
            assertEquals("resultId", identifier)
            assertEquals(startTime, startDateTime)
            assertEquals(57, aqi)
            assertEquals(2, category?.number)
            assertEquals("Moderate", category?.name)
            assertEquals(WeatherServiceProviderName.AIR_NOW, providerName)
        }
    }

    val sampleJson =
        """
[
    {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-04 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "PM2.5",
        "AQI": 57,
        "Category": {
            "Number": 2,
            "Name": "Moderate"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-05 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-06 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-07 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }, {
        "DateIssue": "2021-10-03 ",
        "DateForecast": "2021-10-08 ",
        "ReportingArea": "Redwood City",
        "StateCode": "CA",
        "Latitude": 37.48,
        "Longitude": -122.22,
        "ParameterName": "O3",
        "AQI": -1,
        "Category": {
            "Number": 1,
            "Name": "Good"
        },
        "ActionDay": false
    }
]
   """



    val sampleJson2 = """
  [{
  		"DateIssue": "2020-11-20 ",
  		"DateForecast": "2020-11-20 ",
  		"ReportingArea": "Yuba City/Marysville",
  		"StateCode": "CA",
  		"Latitude": 39.1389,
  		"Longitude": -121.6175,
  		"ParameterName": "PM2.5",
  		"AQI": 46,
  		"Category": {
  			"Number": 1,
  			"Name": "Good"
  		},
  		"ActionDay": false,
  		"Discussion": "Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."
  	},
  	{
  		"DateIssue": "2020-11-20 ",
  		"DateForecast": "2020-11-21 ",
  		"ReportingArea": "Yuba City/Marysville",
  		"StateCode": "CA",
  		"Latitude": 39.1389,
  		"Longitude": -121.6175,
  		"ParameterName": "PM2.5",
  		"AQI": 57,
  		"Category": {
  			"Number": 2,
  			"Name": "Moderate"
  		},
  		"ActionDay": false,
  		"Discussion": "Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."
  	},
  	{
  		"DateIssue": "2020-11-20 ",
  		"DateForecast": "2020-11-22 ",
  		"ReportingArea": "Yuba City/Marysville",
  		"StateCode": "CA",
  		"Latitude": 39.1389,
  		"Longitude": -121.6175,
  		"ParameterName": "PM2.5",
  		"AQI": 66,
  		"Category": {
  			"Number": 2,
  			"Name": "Moderate"
  		},
  		"ActionDay": false,
  		"Discussion": "Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."
  	}
  ]
    """

}
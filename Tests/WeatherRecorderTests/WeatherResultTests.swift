//
//  WeatherResultTests.swift
//

import XCTest
@testable import WeatherRecorder

import JsonModel
import MobilePassiveData
import SharedResourcesTests

class CodableMotionRecorderTests: XCTestCase {
    
    var decoder: JSONDecoder {
        return SerializationFactory.defaultFactory.createJSONDecoder()
    }
    
    var encoder: JSONEncoder {
        return SerializationFactory.defaultFactory.createJSONEncoder()
    }
    
    override func setUp() {
        super.setUp()

        // Use a statically defined timezone.
        ISO8601TimestampFormatter.timeZone = TimeZone(secondsFromGMT: Int(-2.5 * 60 * 60))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWeatherResult_Coding() {
        let filename = "weather_result"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(WeatherResult.self, from: json)
            
            XCTAssertEqual(object.identifier, "weather")
            XCTAssertNotNil(object.startDate)
            XCTAssertNotNil(object.endDate)
            XCTAssertEqual(object.typeName, "weather")
            
            XCTAssertNotNil(object.weather)
            if let weather = object.weather {
                XCTAssertEqual(1.0, weather.clouds ?? 0, accuracy: 0.01)
                XCTAssertEqual(30.0, weather.humidity ?? 0, accuracy: 0.01)
                XCTAssertEqual(26.89, weather.temperature ?? 0, accuracy: 0.01)
                XCTAssertEqual(1015, weather.seaLevelPressure ?? 0, accuracy: 0.01)
                XCTAssertEqual(260, weather.wind?.degrees ?? 0, accuracy: 0.01)
                XCTAssertEqual(4.63, weather.wind?.speed ?? 0, accuracy: 0.01)
                XCTAssertEqual(.openWeather, weather.providerName)
            }
            
            XCTAssertNotNil(object.airQuality)
            if let airQuality = object.airQuality {
                XCTAssertEqual(2, airQuality.category?.number)
                XCTAssertEqual("Moderate", airQuality.category?.name)
                XCTAssertEqual(.airNow, airQuality.providerName)
                XCTAssertEqual(57, airQuality.aqi)
            }
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "weather")
            XCTAssertNotNil(dictionary["startDate"] as? String)
            XCTAssertNotNil(dictionary["endDate"] as? String)
            XCTAssertEqual(dictionary["type"] as? String, "weather")
            
            XCTAssertNotNil(dictionary["weather"] as? [String : Any])
            if let weather = dictionary["weather"] as? [String : Any] {
                XCTAssertEqual("openWeather", weather["provider"] as? String)
                XCTAssertEqual(1.0, weather["clouds"] as? Double ?? 0, accuracy: 0.01)
                XCTAssertEqual(30.0, weather["humidity"] as? Double ?? 0, accuracy: 0.01)
                XCTAssertEqual(26.89, weather["temperature"] as? Double ?? 0, accuracy: 0.01)
                XCTAssertEqual(1015.0, weather["seaLevelPressure"] as? Double ?? 0, accuracy: 0.01)
                XCTAssertNotNil(weather["wind"] as? [String : Any])
                if let wind = weather["wind"] as? [String : Any] {
                    XCTAssertEqual(260.0, wind["degrees"] as? Double ?? 0, accuracy: 0.01)
                    XCTAssertEqual(4.63, wind["speed"] as? Double ?? 0, accuracy: 0.01)
                }
            }
            
            XCTAssertNotNil(dictionary["airQuality"] as? [String : Any])
            if let airQuality = dictionary["airQuality"] as? [String : Any] {
                XCTAssertEqual("airNow", airQuality["provider"] as? String)
                XCTAssertEqual(57, airQuality["aqi"] as? Int)
                XCTAssertNotNil(airQuality["category"] as? [String : Any])
                if let category = airQuality["category"] as? [String : Any] {
                    XCTAssertEqual("Moderate", category["name"] as? String)
                    XCTAssertEqual(2, category["number"] as? Int)
                }
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}

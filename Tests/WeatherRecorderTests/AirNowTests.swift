//
//  AirNowTests.swift
//  
//

import XCTest
@testable import WeatherRecorder
import JsonModel
import MobilePassiveData
import SharedResourcesTests


class AirNowTests: XCTestCase {
    
    var service: AirNowService = {
        AirNowService(configuration: WeatherServiceConfigurationObject(identifier: "airQuality", providerName: .airNow, apiKey: "09458538-8403-419b-8600-9b541914e187"))
    }()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResponse() {
        let filename = "AirNow_Response"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let dateString = "2020-11-21"
            let date = DateComponents(calendar: .init(identifier: .iso8601),
                                      timeZone: TimeZone.init(identifier: "America/Los_Angeles"),
                                      era: nil,
                                      year: 2020,
                                      month: 11,
                                      day: 21,
                                      hour: 10,
                                      minute: 20).date!
            service.processResponse(url, dateString, date, data, nil) { (_, results, err) in
                XCTAssertNil(err)
                guard let result = results?.first as? AirQualityServiceResult else {
                    XCTFail("Failed to return expected result for \(String(describing: results))")
                    return
                }
                
                XCTAssertEqual("airQuality", result.identifier)
                XCTAssertEqual(.airQuality, result.serviceType)
                XCTAssertEqual(.airNow, result.providerName)
                XCTAssertEqual(date, result.startDate)
                XCTAssertEqual(57, result.aqi)
                XCTAssertEqual(.init(number: 2, name: "Moderate"), result.category)

            }
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}

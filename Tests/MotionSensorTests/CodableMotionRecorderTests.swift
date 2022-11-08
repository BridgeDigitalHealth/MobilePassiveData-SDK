//
//  CodableMotionRecorderTests.swift
//

import XCTest
@testable import MotionSensor

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
    
    func testMotionRecorderConfiguration() {
        let filename = "motion_config_custom"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(MotionRecorderConfigurationObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.startStepIdentifier, "start")
            XCTAssertEqual(object.stopStepIdentifier, "stop")
            XCTAssertTrue(object.requiresBackgroundAudio)
            XCTAssertEqual(object.frequency, 50)
            if let recorderTypes = object.recorderTypes {
                XCTAssertEqual(recorderTypes, [.accelerometer, .gyro, .magnetometer])
            } else {
                XCTAssertNotNil(object.recorderTypes)
            }
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "foo")
            XCTAssertEqual(dictionary["startStepIdentifier"] as? String, "start")
            XCTAssertEqual(dictionary["stopStepIdentifier"] as? String, "stop")
            XCTAssertEqual(dictionary["requiresBackgroundAudio"] as? Bool, true)
            XCTAssertEqual(dictionary["frequency"] as? Double, 50)
            if let recorderTypes = dictionary["recorderTypes"] as? [String] {
                XCTAssertEqual(Set(recorderTypes), Set(["accelerometer", "gyro", "magnetometer"]))
            } else {
                XCTFail("Failed to encode the recorder types: \(String(describing: dictionary["recorderTypes"]))")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMotionRecorderConfiguration_Defaults() {
        let filename = "motion_config_default"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(MotionRecorderConfigurationObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertNil(object.startStepIdentifier)
            XCTAssertNil(object.stopStepIdentifier)
            XCTAssertFalse(object.requiresBackgroundAudio)
            XCTAssertNil(object.frequency)
            XCTAssertNil(object.recorderTypes)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMotionRecord_Marker() {
        let filename = "motion_record_marker"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(MotionRecord.self, from: json)
            
            XCTAssertEqual(object.uptime, 37246.68689429167)
            XCTAssertEqual(object.timestamp, 1.2498140833340585)
            XCTAssertEqual(object.stepPath, "Cardio Stair Step/heartRate.after/heartRate")
            XCTAssertNotNil(object.timestampDate)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["uptime"] as? Double, 37246.68689429167)
            XCTAssertEqual(dictionary["timestamp"] as? Double, 1.2498140833340585)
            XCTAssertEqual(dictionary["stepPath"] as? String, "Cardio Stair Step/heartRate.after/heartRate")
            XCTAssertEqual(dictionary["timestampDate"] as? String, "2018-01-30T15:13:20.597-02:30")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMotionRecord_Gyro() {
        let filename = "motion_record_gyro"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(MotionRecord.self, from: json)
            
            XCTAssertEqual(object.uptime, 37246.68689429167)
            XCTAssertEqual(object.timestamp, 1.2498140833340585)
            XCTAssertEqual(object.stepPath, "Cardio Stair Step/heartRate.after/heartRate")
            XCTAssertNil(object.timestampDate)
            XCTAssertEqual(object.sensorType, .gyro)
            XCTAssertEqual(object.x, 0.064788818359375)
            XCTAssertEqual(object.y, -0.1324615478515625)
            XCTAssertEqual(object.z, -0.9501953125)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["uptime"] as? Double, 37246.68689429167)
            XCTAssertEqual(dictionary["timestamp"] as? Double, 1.2498140833340585)
            XCTAssertEqual(dictionary["stepPath"] as? String, "Cardio Stair Step/heartRate.after/heartRate")
            XCTAssertEqual(dictionary["sensorType"] as? String, "gyro")
            XCTAssertEqual(dictionary["x"] as? Double, 0.064788818359375)
            XCTAssertEqual(dictionary["y"] as? Double, -0.1324615478515625)
            XCTAssertEqual(dictionary["z"] as? Double, -0.9501953125)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    
    func testMotionRecord_Attitude() {
        let filename = "motion_record_attitude"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(MotionRecord.self, from: json)
            
            XCTAssertEqual(object.uptime, 37246.68689429167)
            XCTAssertEqual(object.timestamp, 1.2498140833340585)
            XCTAssertEqual(object.stepPath, "Cardio Stair Step/heartRate.after/heartRate")
            XCTAssertNil(object.timestampDate)
            XCTAssertEqual(object.sensorType, .attitude)
            XCTAssertEqual(object.referenceCoordinate, .xMagneticNorthZVertical)
            XCTAssertEqual(object.eventAccuracy, 4)
            XCTAssertEqual(object.heading, 270.25)
            XCTAssertEqual(object.x, 0.064788818359375)
            XCTAssertEqual(object.y, -0.1324615478515625)
            XCTAssertEqual(object.z, -0.9501953125)
            XCTAssertEqual(object.w, 1)

            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["uptime"] as? Double, 37246.68689429167)
            XCTAssertEqual(dictionary["timestamp"] as? Double, 1.2498140833340585)
            XCTAssertEqual(dictionary["stepPath"] as? String, "Cardio Stair Step/heartRate.after/heartRate")
            XCTAssertEqual(dictionary["sensorType"] as? String, "attitude")
            XCTAssertEqual(dictionary["referenceCoordinate"] as? String, "North-West-Up")
            XCTAssertEqual(dictionary["eventAccuracy"] as? Int, 4)
            XCTAssertEqual(dictionary["heading"] as? Double,270.25)
            XCTAssertEqual(dictionary["x"] as? Double, 0.064788818359375)
            XCTAssertEqual(dictionary["y"] as? Double, -0.1324615478515625)
            XCTAssertEqual(dictionary["z"] as? Double, -0.9501953125)
            XCTAssertEqual(dictionary["w"] as? Double, 1)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}

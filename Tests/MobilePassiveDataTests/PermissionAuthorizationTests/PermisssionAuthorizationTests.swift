//
//  PermisssionAuthorizationTests.swift
//  
//

import XCTest
@testable import MobilePassiveData

import JsonModel
import NSLocaleSwizzle
import Foundation
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

        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStandardPermission_DefaultMessage() {
        let permission = StandardPermission(permissionType: .motion)
        XCTAssertEqual(permission.deniedMessage, "You have not given this app permission to use the motion and fitness sensors. You can enable access by turning on 'Motion & Fitness' in the Privacy Settings.")
        XCTAssertTrue(permission.requestIfNeeded)
        XCTAssertFalse(permission.isOptional)
    }
    
    func testStandardPermission_DefaultCodable() {
        let permission = StandardPermission(permissionType: .motion)
        do {
            let encodedObject = try encoder.encode(permission)
            let jsonObject = try JSONSerialization.jsonObject(with: encodedObject, options: [])
            if let dictionary = jsonObject as? [String : Any] {
                XCTAssertEqual("motion", dictionary["permissionType"] as? String)
            }
            else {
                XCTFail("Failed to encode as a dictionary.")
            }
            
            let decodedObject = try decoder.decode(StandardPermission.self, from: encodedObject)
            
            XCTAssertEqual(.motion, decodedObject.permissionType)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testStandardPermission_CustomCodable() {
        let filename = "StandardPermission_Camera"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decodedObject = try decoder.decode(StandardPermission.self, from: data)
            
            XCTAssertEqual(.camera, decodedObject.permissionType)
            XCTAssertEqual("Camera Permission", decodedObject.title)
            XCTAssertEqual("A picture tells a thousand words.", decodedObject.reason)
            XCTAssertEqual("Your access to the camera is restricted.", decodedObject.restrictedMessage)
            XCTAssertEqual("You have previously denied permission for this app to use the camera.", decodedObject.deniedMessage)
            XCTAssertFalse(decodedObject.requestIfNeeded)
            XCTAssertTrue(decodedObject.isOptional)
        
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}

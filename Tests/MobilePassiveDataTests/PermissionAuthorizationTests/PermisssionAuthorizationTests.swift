//
//  PermisssionAuthorizationTests.swift
//  
//
//  Copyright © 2021 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
        XCTAssertFalse(permission.optional)
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
            XCTAssertEqual("Your access to the camera is restricted.", decodedObject.restrictedMessage)
            XCTAssertEqual("You have previously denied permission for this app to use the camera.", decodedObject.deniedMessage)
            XCTAssertFalse(decodedObject.requestIfNeeded)
            XCTAssertTrue(decodedObject.optional)
        
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}

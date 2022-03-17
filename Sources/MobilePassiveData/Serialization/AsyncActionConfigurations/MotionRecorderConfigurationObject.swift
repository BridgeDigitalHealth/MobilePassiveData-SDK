//
//  MotionRecorderConfigurationObject.swift
//
//  Copyright © 2018-2021 Sage Bionetworks. All rights reserved.
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

import Foundation
import JsonModel
import AssessmentModel

/// The default configuration to use for a `MotionSensor.MotionRecorder`.
///
/// - example:
///
/// ```
///     // Example json for a codable configuration.
///        let json = """
///             {
///                "identifier": "foo",
///                "type": "motion",
///                "startStepIdentifier": "start",
///                "stopStepIdentifier": "stop",
///                "requiresBackgroundAudio": true,
///                "recorderTypes": ["accelerometer", "gyro", "magnetometer"],
///                "frequency": 50
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct MotionRecorderConfigurationObject : MotionRecorderConfiguration, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case identifier, asyncActionType = "type", recorderTypes, startStepIdentifier, stopStepIdentifier, frequency, _requiresBackgroundAudio = "requiresBackgroundAudio", usesCSVEncoding, _shouldDeletePrevious = "shouldDeletePrevious"
    }

    public let identifier: String
    
    public private(set) var asyncActionType: AsyncActionType = .motion
    
    public var startStepIdentifier: String?
    public var stopStepIdentifier: String?
    
    /// Default = `true`.
    public var shouldDeletePrevious: Bool {
        return _shouldDeletePrevious ?? true
    }
    private let _shouldDeletePrevious: Bool?
    
    /// Default = `false`.
    public var requiresBackgroundAudio: Bool {
        return _requiresBackgroundAudio ?? false
    }
    private let _requiresBackgroundAudio: Bool?
    
    public var recorderTypes: Set<MotionRecorderType>?
    
    public var frequency: Double?
    
    public var usesCSVEncoding : Bool?
    
    /// Default initializer.
    public init(identifier: String, recorderTypes: Set<MotionRecorderType>? = nil, requiresBackgroundAudio: Bool = false, frequency: Double? = nil, shouldDeletePrevious: Bool? = nil, usesCSVEncoding : Bool? = nil) {
        self.identifier = identifier
        self.recorderTypes = recorderTypes
        self._requiresBackgroundAudio = requiresBackgroundAudio
        self.frequency = frequency
        self._shouldDeletePrevious = shouldDeletePrevious
        self.usesCSVEncoding = usesCSVEncoding
    }
}

extension MotionRecorderConfigurationObject : SerializableAsyncActionConfiguration {
}

extension MotionRecorderConfigurationObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .identifier || key == .asyncActionType
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription: "A short string that uniquely identifies the asynchronous action within the task.")
        case .asyncActionType:
            return .init(constValue: AsyncActionType.motion)
        case .startStepIdentifier,.stopStepIdentifier:
            return .init(propertyType: .primitive(.string))
        case ._requiresBackgroundAudio:
            return .init(defaultValue: .boolean(false), propertyDescription: "Whether or not the recorder requires background audio.")
        case ._shouldDeletePrevious:
            return .init(defaultValue: .boolean(true), propertyDescription: "Should the file used in a previous run of a recording be deleted?")
        case .frequency:
            return .init(defaultValue: .number(100), propertyDescription: "The sampling frequency of the motion sensors.")
        case .recorderTypes:
            return .init(propertyType: .referenceArray(MotionRecorderType.documentableType()), propertyDescription: "The motion sensor types to include with this configuration.")
        case .usesCSVEncoding:
            return .init(defaultValue: .boolean(false), propertyDescription: "Should samples be encoded as a CSV file?")
        }
    }
    
    public static func examples() -> [MotionRecorderConfigurationObject] {
        [
            MotionRecorderConfigurationObject(identifier: "exampleA"),
            MotionRecorderConfigurationObject(identifier: "exampleB",
                                              recorderTypes: [.gyro, .gravity],
                                              requiresBackgroundAudio: true,
                                              frequency: 200,
                                              shouldDeletePrevious: false,
                                              usesCSVEncoding: true)
        ]
    }
}



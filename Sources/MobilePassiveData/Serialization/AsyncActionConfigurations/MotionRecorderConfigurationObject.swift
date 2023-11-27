//
//  MotionRecorderConfigurationObject.swift
//

import Foundation
import JsonModel

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
@Serializable
@SerialName("motion")
public struct MotionRecorderConfigurationObject : MotionRecorderConfiguration, Codable {

    public let identifier: String
    
    public var startStepIdentifier: String?
    public var stopStepIdentifier: String?
    
    public var recorderTypes: Set<MotionRecorderType>?
    
    public private(set) var requiresBackgroundAudio: Bool = false
    public var frequency: Double?
    public private(set) var shouldDeletePrevious: Bool = true
    public var usesCSVEncoding : Bool?
    
    /// Do nothing. No validation is required for this recorder.
    public func validate() throws {
    }
}

extension MotionRecorderConfigurationObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .identifier || key == .typeName
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription: "A short string that uniquely identifies the asynchronous action within the task.")
        case .typeName:
            return .init(constValue: serialTypeName)
        case .startStepIdentifier,.stopStepIdentifier:
            return .init(propertyType: .primitive(.string))
        case .requiresBackgroundAudio:
            return .init(defaultValue: .boolean(false), propertyDescription: "Whether or not the recorder requires background audio.")
        case .shouldDeletePrevious:
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



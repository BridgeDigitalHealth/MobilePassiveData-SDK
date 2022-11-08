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
    
    /// Do nothing. No validation is required for this recorder.
    public func validate() throws {
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



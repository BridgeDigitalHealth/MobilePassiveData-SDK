//
//  AudioRecorderConfigurationObject.swift
//  
//


import Foundation
import JsonModel

/// The default configuration to use for a `AudioRecorder`.
///
/// - example:
///
/// ```
///     // Example json for a codable configuration.
///        let json = """
///             {
///                "identifier": "foo",
///                "type": "microphone",
///                "startStepIdentifier": "countdown",
///                "stopStepIdentifier": "rest",
///                "requiresBackgroundAudio": true,
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
@Serializable
@SerialName("microphone")
public struct AudioRecorderConfigurationObject : RestartableRecorderConfiguration, Codable {
  
    /// A short string that uniquely identifies the asynchronous action within the task. If started
    /// asynchronously, then the identifier maps to a result stored in `RSDTaskResult.asyncResults`.
    public let identifier: String
    
    /// An identifier marking the step to start the action. If `nil`, then the action will be started when
    /// the task is started.
    public let startStepIdentifier: String?
    
    /// An identifier marking the step to stop the action. If `nil`, then the action will be started when
    /// the task is started.
    public let stopStepIdentifier: String?
    
    /// Whether or not the recorder requires background audio. Default = `false`.
    ///
    /// If `true` then background audio can be used to keep the recorder running if the screen is locked
    /// because of the idle timer turning off the device screen.
    ///
    /// If the app uses background audio, then the developer will need to turn `ON` the "Background Modes"
    /// under the "Capabilities" tab of the Xcode project, and will need to select "Audio, AirPlay, and
    /// Picture in Picture".
    ///
    public private(set) var requiresBackgroundAudio: Bool = false
    
    /// Should the previous recording be deleted on restart?
    public private(set) var shouldDeletePrevious: Bool = true
    
    /// Should the audio recording be saved? Default = `false`.
    ///
    /// If `true` then the audio file used to measure meter levels is saved with the results.
    /// Otherwise, the audio file recorded is assumed to be a temporary file and should be deleted
    /// when the recording stops.
    public var saveAudioFile: Bool?
    
    /// Returns `microphone` on iOS. Returns an empty set on other platforms.
    public var permissionTypes: [PermissionType] {
        #if os(iOS)
            return [StandardPermissionType.microphone]
        #else
            return []
        #endif
    }
    
    /// Do nothing. No validation is required for this recorder.
    public func validate() throws {
    }
}

extension AudioRecorderConfigurationObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName || key == .identifier
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startStepIdentifier, .stopStepIdentifier:
            return .init(propertyType: .primitive(.string))
        case .requiresBackgroundAudio, .saveAudioFile, .shouldDeletePrevious:
            return .init(propertyType: .primitive(.boolean))
        }
    }
    
    public static func examples() -> [AudioRecorderConfigurationObject] {
        let example = AudioRecorderConfigurationObject(identifier: "microphone", startStepIdentifier: "countdown", stopStepIdentifier: "rest", requiresBackgroundAudio: true, saveAudioFile: true)
        return [example]
    }
}

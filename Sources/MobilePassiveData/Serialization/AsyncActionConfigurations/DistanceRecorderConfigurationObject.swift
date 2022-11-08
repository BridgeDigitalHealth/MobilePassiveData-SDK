//
//  DistanceRecorderConfigurationObject.swift
//

import Foundation
import JsonModel

/// The default configuration to use for a `RSDDistanceRecorder`.
///
/// - example:
///
/// ```
///     // Example json for a codable configuration.
///        let json = """
///             {
///                "identifier": "foo",
///                "type": "distance",
///                "motionStepIdentifier": "run"
///                "startStepIdentifier": "countdown",
///                "stopStepIdentifier": "rest",
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
@available(iOS 10.0, *)
public struct DistanceRecorderConfigurationObject : DistanceRecorderConfiguration, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case identifier, asyncActionType = "type", motionStepIdentifier, startStepIdentifier, stopStepIdentifier, usesCSVEncoding
    }
    
    /// A short string that uniquely identifies the asynchronous action within the task. If started
    /// asynchronously, then the identifier maps to a result stored in `RSDTaskResult.asyncResults`.
    public let identifier: String
    
    /// The standard permission type associated with this configuration.
    public private(set) var asyncActionType: AsyncActionType = .distance
    
    /// Identifier for the step that records distance travelled. The recorder uses this step to record
    /// distance travelled while the other steps in the task are assumed to be standing still.
    public let motionStepIdentifier: String?
    
    /// An identifier marking the step to start the action. If `nil`, then the action will be started when
    /// the task is started.
    public let startStepIdentifier: String?
    
    /// An identifier marking the step to stop the action. If `nil`, then the action will be started when
    /// the task is started.
    public let stopStepIdentifier: String?
    
    /// Set the flag to `true` to encode the samples as a CSV file.
    public var usesCSVEncoding : Bool?
    
    /// Default initializer.
    /// - parameters:
    ///     - identifier: The configuration identifier.
    ///     - motionStepIdentifier: Optional identifier for the step that records distance travelled.
    ///     - startStepIdentifier: An identifier marking the step to start the action. Default = `nil`.
    ///     - stopStepIdentifier: An identifier marking the step to stop the action.  Default = `nil`.
    public init(identifier: String, motionStepIdentifier: String? = nil, startStepIdentifier: String? = nil, stopStepIdentifier: String? = nil) {
        self.identifier = identifier
        self.motionStepIdentifier = motionStepIdentifier
        self.startStepIdentifier = startStepIdentifier
        self.stopStepIdentifier = stopStepIdentifier
    }
    
    
    /// Do nothing. No validation is required for this recorder.
    public func validate() throws {
    }
}

extension DistanceRecorderConfigurationObject : SerializableAsyncActionConfiguration {
}

extension DistanceRecorderConfigurationObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .asyncActionType || key == .identifier
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .asyncActionType:
            return .init(constValue: AsyncActionType.distance)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startStepIdentifier, .stopStepIdentifier, .motionStepIdentifier:
            return .init(propertyType: .primitive(.string))
        case .usesCSVEncoding:
            return .init(propertyType: .primitive(.boolean))
        }
    }
    
    public static func examples() -> [DistanceRecorderConfigurationObject] {
        let example = DistanceRecorderConfigurationObject(identifier: "distance", motionStepIdentifier: "run", startStepIdentifier: "countdown", stopStepIdentifier: "rest")
        return [example]
    }
}


//
//  DistanceRecorderConfiguration.swift
//

import Foundation
import JsonModel

public protocol DistanceRecorderConfiguration : RecorderConfiguration {
    
    /// Identifier for the step that records distance travelled. The recorder uses this step to record
    /// distance travelled while the other steps in the task are assumed to be standing still.
    var motionStepIdentifier: String? { get }
    
    /// Set the flag to `true` to encode the samples as a CSV file.
    var usesCSVEncoding : Bool?  { get }
    
}

extension DistanceRecorderConfiguration {
    
    /// Returns true. Background audio is required for this configuration.
    public var requiresBackgroundAudio: Bool {
        return true
    }
    
    /// Returns `location` and `motion` on iOS. Returns an empty set on platforms that do not
    /// support distance recording.
    /// - note: The use of this recorder requires adding “Privacy - Motion Usage Description” to the
    ///         application "info.plist" file.
    public var permissionTypes: [PermissionType] {
        #if os(iOS)
            return [StandardPermissionType.location, StandardPermissionType.motion]
        #else
            return []
        #endif
    }
}


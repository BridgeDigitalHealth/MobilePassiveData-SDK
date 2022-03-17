//
//  StandardPermission.swift
//
//  Copyright © 2017-2022 Sage Bionetworks. All rights reserved.
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

/// Standard permission types.
public extension PermissionType {
    
    /// “Privacy - Camera Usage Description”
    /// Specifies the reason for your app to access the device’s camera.
    /// - seealso: `NSCameraUsageDescription`
    static let camera: PermissionType = "camera"
    
    /// “Privacy - Location When In Use Usage Description”
    /// Specifies the reason for your app to access the user’s location information while your app is in use.
    /// - seealso: `NSLocationWhenInUseUsageDescription`
    static let locationWhenInUse: PermissionType = "locationWhenInUse"
    
    /// “Privacy - Location Always Usage Description”
    /// Specifies the reason for your app to access the user’s location information at all times.
    /// - seealso: `NSLocationAlwaysUsageDescription`
    static let location: PermissionType = "location"
    
    /// “Privacy - Microphone Usage Description”
    /// Specifies the reason for your app to access any of the device’s microphones.
    /// - seealso: `NSMicrophoneUsageDescription`
    static let microphone: PermissionType = .Standard.microphone.permissionType
    
    /// “Privacy - Motion Usage Description”
    /// Specifies the reason for your app to access the device’s accelerometer.
    /// - seealso: `NSMotionUsageDescription`
    static let motion: PermissionType = .Standard.motion.permissionType
    
    /// “Privacy - Photo Library Usage Description”
    /// Specifies the reason for your app to access the user’s photo library.
    /// - seealso: `NSPhotoLibraryUsageDescription`
    static let photoLibrary: PermissionType = "photoLibrary"
    
    /// Used to request permission to post local notifications.
    static let notifications: PermissionType = .Standard.notifications.permissionType
    
    /// Used to request permission to gather weather report.
    static let weather: PermissionType = .Standard.weather.permissionType
}

/// A Codable struct that can be used to store messaging information specific to the use-case specific to
/// the associated activity, task, or step.
public final class StandardPermission : PermissionInfo, Codable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case permissionType, _restrictedMessage = "restrictedMessage", _deniedMessage = "deniedMessage", _isOptional = "optional", _requestIfNeeded = "requestIfNeeded"
    }
    
    public static let camera = StandardPermission(permissionType: .camera)
    public static let microphone = StandardPermission(permissionType: .microphone)
    public static let motion = StandardPermission(permissionType: .motion)
    public static let photoLibrary = StandardPermission(permissionType: .photoLibrary)
    public static let weather = StandardPermission(permissionType: .weather)
    public static let location = StandardPermission(permissionType: .location)
    public static let locationWhenInUse = StandardPermission(permissionType: .locationWhenInUse)
    public static let notifications = StandardPermission(permissionType: .notifications)
    
    /// Default initializer.
    public init(permissionType : PermissionType, deniedMessage: String? = nil, restrictedMessage: String? = nil, requestIfNeeded: Bool? = nil, isOptional: Bool? = nil) {
        self.permissionType = permissionType
        self._deniedMessage = deniedMessage
        self._restrictedMessage = restrictedMessage
        self._isOptional = isOptional
        self._requestIfNeeded = requestIfNeeded
    }
    
    /// The permission type for this permission.
    public let permissionType: PermissionType
    
    /// Is the permission optional for a given task? (Default == `false`, ie. required)
    ///
    /// - example:
    ///
    /// Test A requires the motion sensors to calculate the results, in which case this permission should be
    /// required and the participant should be blocked from performing the task if the permission is not
    /// included.
    ///
    /// Test B uses the motion sensors (if available) to inform the results but can still receive valuable
    /// information about the participant without them. In this case, the permission is optional and the
    /// participant should be allowed to continue without permission to access the motion sensors.
    ///
    public var optional: Bool {
        return _isOptional ?? false
    }
    private let _isOptional: Bool?
    
    /// Should the step request the listed permissions before continuing to the next step? (Default == `true`)
    ///
    /// This flag can be used to optionally show an instruction step that will display information to a user
    /// concerning why a permission is being requested. This is allowed to add additional clarity to the user
    /// about the requirements of a given task that cannot be explained satisfactorily by the OS alert.
    public var requestIfNeeded: Bool {
        return _requestIfNeeded ?? true
    }
    private let _requestIfNeeded: Bool?
    
    /// The message to show when displaying an alert that the user cannot run a step or task because their
    /// access is restricted.
    public var restrictedMessage: String? {
        if let message = _restrictedMessage { return message }
        switch self.permissionType {
        case .camera:
            return Localization.localizedString("CAMERA_PERMISSION_RESTRICTED")
        case .location, .locationWhenInUse, .weather:
            return Localization.localizedString("LOCATION_PERMISSION_RESTRICTED")
        case .microphone:
            return Localization.localizedString("MICROPHONE_PERMISSION_RESTRICTED")
        case .photoLibrary:
            return Localization.localizedString("PHOTO_LIBRARY_PERMISSION_RESTRICTED")
            
        default:
            // permissions that are not currently part of restricted access. For these cases,
            // return a general-purpose message.
            assertionFailure("\(self.permissionType) is not expected to be restricted. Please fix.")
            return Localization.localizedString("GENERAL_PERMISSION_RESTRICTED")
        }
    }
    private let _restrictedMessage: String?
    
    /// The message to show when displaying an alert that the user cannot run a step or task because their
    /// access is denied.
    public var deniedMessage: String? {
        if let message = _deniedMessage { return message }
        switch self.permissionType {
        case .camera:
            return Localization.localizedString("CAMERA_PERMISSION_DENIED")
        case .location:
            return Localization.localizedString("LOCATION_BACKGROUND_PERMISSION_DENIED")
        case .locationWhenInUse, .weather:
            return Localization.localizedString("LOCATION_IN_USE_PERMISSION_DENIED")
        case .microphone:
            return Localization.localizedString("MICROPHONE_PERMISSION_DENIED")
        case .motion:
            return Localization.localizedString("MOTION_PERMISSION_DENIED")
        case .photoLibrary:
            return Localization.localizedString("PHOTO_LIBRARY_PERMISSION_DENIED")
        case .notifications:
            return Localization.localizedString("NOTIFICATIONS_PERMISSION_DENIED")
        default:
            assertionFailure("\(self.permissionType) is unknown and does not have a denied message. Please fix.")
            return nil
        }
    }
    private let _deniedMessage: String?
    
    private class Localization {
        static func localizedString(_ key: String) -> String {
            NSLocalizedString(key, tableName: nil, bundle: Bundle.module, value: key, comment: key)
        }
    }
}

extension PermissionInfo {
    func message(for status: PermissionAuthorizationStatus) -> String? {
        switch status {
        case .denied, .previouslyDenied:
            return self.deniedMessage
        case .restricted:
            return self.restrictedMessage
        default:
            return nil
        }
    }
}

/// `PermissionError` errors are thrown when a activity does not have a permission that is required
/// to run the action.
public enum PermissionError : Error {
    
    /// Permission denied.
    case notAuthorized(PermissionInfo, PermissionAuthorizationStatus)
    
    /// Permission was not handled by this framework.
    case notHandled(String)
    
    /// The localized message for this error.
    public var localizedDescription: String {
        switch(self) {
        case .notAuthorized(let permission, let status):
            return permission.message(for: status) ?? "\(permission) : \(status)"
        case .notHandled(let message):
            return message
        }
    }
    
    /// The domain of the error.
    public static var errorDomain: String {
        return "MPDPermissionErrorDomain"
    }
    
    /// The error code within the given domain.
    public var errorCode: Int {
        switch(self) {
        case .notAuthorized(_, let status):
            return status.rawValue
        case .notHandled(_):
            return PermissionAuthorizationStatus.notDetermined.rawValue
        }
    }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        return ["NSDebugDescription": self.localizedDescription]
    }
}

extension StandardPermission : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .permissionType
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .permissionType:
            return .init(propertyType: .reference(PermissionType.documentableType()))
        case ._restrictedMessage,._deniedMessage:
            return .init(propertyType: .primitive(.string))
        case ._isOptional, ._requestIfNeeded:
            return .init(propertyType: .primitive(.boolean))
        }
    }
    
    public static func examples() -> [StandardPermission] {
        let exampleA = StandardPermission(permissionType: .motion)
        let exampleB = StandardPermission(permissionType: .camera,
                                          deniedMessage: "You didn't give permission",
                                          restrictedMessage: "Your camera access is restricted",
                                          isOptional: true)
        return [exampleA, exampleB]
    }
}

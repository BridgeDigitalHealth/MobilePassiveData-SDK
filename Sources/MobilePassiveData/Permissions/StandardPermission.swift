//
//  StandardPermission.swift
//

import Foundation
import JsonModel

/// Standard permission types.
///
/// - note: This framework intentionally does not include any direct reference to Health Kit.
///         First, including Health Kit in applications that do not use that SDK makes it
///         confusing and difficult for researchers to set up the app. Second, the goal of
///         this framework is to include a model that is platform-agnostic and can be used
///         independently of the device. (syoung 11/1/7/2017)
///
public enum StandardPermissionType: String, PermissionType, Codable, CaseIterable {
    
    /// “Privacy - Camera Usage Description”
    /// Specifies the reason for your app to access the device’s camera.
    /// - seealso: `NSCameraUsageDescription`
    case camera
    
    /// “Privacy - Location When In Use Usage Description”
    /// Specifies the reason for your app to access the user’s location information while your app is in use.
    /// - seealso: `NSLocationWhenInUseUsageDescription`
    case locationWhenInUse
    
    /// “Privacy - Location Always Usage Description”
    /// Specifies the reason for your app to access the user’s location information at all times.
    /// - seealso: `NSLocationAlwaysUsageDescription`
    case location
    
    /// “Privacy - Microphone Usage Description”
    /// Specifies the reason for your app to access any of the device’s microphones.
    /// - seealso: `NSMicrophoneUsageDescription`
    case microphone
    
    /// “Privacy - Motion Usage Description”
    /// Specifies the reason for your app to access the device’s accelerometer.
    /// - seealso: `NSMotionUsageDescription`
    case motion
    
    /// “Privacy - Photo Library Usage Description”
    /// Specifies the reason for your app to access the user’s photo library.
    /// - seealso: `NSPhotoLibraryUsageDescription`
    case photoLibrary
    
    /// Used to request permission to post local notifications.
    case notifications
    
    /// An identifier for the permission.
    public var identifier: String {
        return rawValue
    }
}

extension StandardPermissionType : DocumentableStringEnum, StringEnumSet {
}

/// A Codable struct that can be used to store messaging information specific to the use-case specific to
/// the associated activity, task, or step.
public final class StandardPermission : Permission, Codable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case permissionType, title, reason, _restrictedMessage = "restrictedMessage", _deniedMessage = "deniedMessage", _requestIfNeeded = "requestIfNeeded", _isOptional = "optional"
    }
    
    public static let camera = StandardPermission(permissionType: .camera)
    public static let microphone = StandardPermission(permissionType: .microphone)
    public static let motion = StandardPermission(permissionType: .motion)
    public static let photoLibrary = StandardPermission(permissionType: .photoLibrary)
    public static let location = StandardPermission(permissionType: .location)
    public static let locationWhenInUse = StandardPermission(permissionType: .locationWhenInUse)
    public static let notifications = StandardPermission(permissionType: .notifications)
    
    /// Default initializer.
    public init(permissionType : StandardPermissionType, title: String? = nil, reason: String? = nil, deniedMessage: String? = nil, restrictedMessage: String? = nil, requestIfNeeded: Bool? = nil, isOptional: Bool? = nil) {
        self.permissionType = permissionType
        self.title = title
        self.reason = reason
        self._deniedMessage = deniedMessage
        self._restrictedMessage = restrictedMessage
        self._requestIfNeeded = requestIfNeeded
        self._isOptional = isOptional
    }
    
    /// The permission type for this permission.
    public let permissionType : StandardPermissionType
    
    public var identifier: String {
        return permissionType.identifier
    }
    
    /// A title for this permission.
    public let title: String?
    
    /// Additional reason for requiring the permission.
    public let reason: String?
    
    /// Should the step request the listed permissions before continuing to the next step? (Default == `true`)
    ///
    /// This flag can be used to optionally show an instruction step that will display information to a user
    /// concerning why a permission is being requested. This is allowed to add additional clarity to the user
    /// about the requirements of a given task that cannot be explained satisfactorily by the OS alert.
    public var requestIfNeeded: Bool {
        return _requestIfNeeded ?? true
    }
    private let _requestIfNeeded: Bool?
    
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
    public var isOptional: Bool {
        return _isOptional ?? false
    }
    private let _isOptional: Bool?
    
    /// The message to show when displaying an alert that the user cannot run a step or task because their
    /// access is restricted.
    public var restrictedMessage: String {
        if let message = _restrictedMessage { return message }
        switch self.permissionType {
        case .camera:
            return Localization.localizedString("CAMERA_PERMISSION_RESTRICTED")
        case .location, .locationWhenInUse:
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
    public var deniedMessage: String {
        if let message = _deniedMessage { return message }
        switch self.permissionType {
        case .camera:
            return Localization.localizedString("CAMERA_PERMISSION_DENIED")
        case .location:
            return Localization.localizedString("LOCATION_BACKGROUND_PERMISSION_DENIED")
        case .locationWhenInUse:
            return Localization.localizedString("LOCATION_IN_USE_PERMISSION_DENIED")
        case .microphone:
            return Localization.localizedString("MICROPHONE_PERMISSION_DENIED")
        case .motion:
            return Localization.localizedString("MOTION_PERMISSION_DENIED")
        case .photoLibrary:
            return Localization.localizedString("PHOTO_LIBRARY_PERMISSION_DENIED")
        case .notifications:
            return Localization.localizedString("NOTIFICATIONS_PERMISSION_DENIED")
        }
    }
    private let _deniedMessage: String?
    
    /// Returns the message appropriate to the status.
    public func message(for status: PermissionAuthorizationStatus) -> String? {
        switch status {
        case .denied, .previouslyDenied:
            return self.deniedMessage
        case .restricted:
            return self.restrictedMessage
        default:
            return nil
        }
    }
    
    private class Localization {
        static func localizedString(_ key: String) -> String {
            NSLocalizedString(key, tableName: nil, bundle: Bundle.module, value: key, comment: key)
        }
    }
}

/// `PermissionError` errors are thrown when a activity does not have a permission that is required
/// to run the action.
public enum PermissionError : Error {
    
    /// Permission denied.
    case notAuthorized(Permission, PermissionAuthorizationStatus)
    
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
            return .init(propertyType: .reference(StandardPermissionType.documentableType()))
        case .title,.reason,._restrictedMessage,._deniedMessage:
            return .init(propertyType: .primitive(.string))
        case ._requestIfNeeded, ._isOptional:
            return .init(propertyType: .primitive(.boolean))
        }
    }
    
    public static func examples() -> [StandardPermission] {
        let exampleA = StandardPermission(permissionType: .motion)
        let exampleB = StandardPermission(permissionType: .camera,
                                          title: "Permission to use the camera",
                                          reason: "Because we want to take a picture.",
                                          deniedMessage: "You didn't give permission",
                                          restrictedMessage: "Your camera access is restricted",
                                          requestIfNeeded: false,
                                          isOptional: true)
        return [exampleA, exampleB]
    }
}

//
//  PermissionAuthorizationHandler.swift
//

import Foundation


/// An authorization adapter is a class that can manage requesting authorization for a given permission.
public protocol PermissionAuthorizationAdaptor : AnyObject {
    
    /// A list of the permissions that this adaptor can manage.
    var permissions: [PermissionType] { get }
    
    /// The current status of the authorization.
    func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus
    
    /// Requesting the authorization.
    func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void))
}

@objc public final class PermissionAuthorizationHandler : NSObject {
    
    private static var adaptors: [String : PermissionAuthorizationAdaptor] = [:]
    
    /// Register the given adaptor as the authorization adapter to use. This will only register the
    /// adaptor if another adator with the same `identifier` has not already been set. Otherwise, the
    /// state that may be held by the adaptor could be lost.
    public static func registerAdaptorIfNeeded(_ adaptor: PermissionAuthorizationAdaptor) {
        adaptor.permissions.forEach {
            guard adaptors[$0.identifier] == nil else { return }
            adaptors[$0.identifier] = adaptor
        }
    }
    
    /// Returns authorization status the given permission.
    @objc public static func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        guard let adator = adaptors[permission]
            else {
                // "Starting Spring 2019, all apps submitted to the App Store that access user data will
                //  be required to include a purpose string. If you're using external libraries or SDKs,
                //  they may reference APIs that require a purpose string. While your app might not use
                //  these APIs, a purpose string is still required. You can contact the developer of the
                //  library or SDK and request they release a version of their code that doesn't contain
                //  the APIs." - syoung 05/15/2019 Message from Apple's App Store Connect.
                //
                // As a consequence of this, any permissions referenced by the recorders and view
                // controllers used by the Sage Bionetworks frameworks must be registered with the
                // authorization handler.
                assertionFailure("\(permission) was not recognized as a registered permission.")
                return .denied
        }
        return adator.authorizationStatus(for: permission)
    }
    
    /// Request authorization for the given permission.
    @objc public static func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        guard let adator = adaptors[permission.identifier]
            else {
                completion(.denied, PermissionError.notHandled("\(permission.identifier) was not recognized as a registered permission."))
                return
        }
        adator.requestAuthorization(for: permission, completion)
    }
}

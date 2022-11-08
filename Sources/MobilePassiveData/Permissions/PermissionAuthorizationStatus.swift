//
//  PermissionAuthorizationStatus.swift
//  
//

import Foundation

/// General-purpose enum for authorization status.
@objc public enum PermissionAuthorizationStatus : Int {
    
    /// Standard mapping of the authorization status.
    case authorized, notDetermined, restricted, denied
    
    /// There is a cached value for the authorization status that was previously denied but the user may
    /// have since updated the Settings to allow permission.
    case previouslyDenied
    
    /// Is the authorization status blocking the activity that requires it? This will return true if the
    /// status is restricted, denied, or previously denied.
    public func isDenied() -> Bool {
        switch self {
        case .authorized, .notDetermined:
            return false
        default:
            return true
        }
    }
}

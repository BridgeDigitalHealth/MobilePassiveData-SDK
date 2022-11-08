//
//  PermissionType.swift
//

import Foundation

/// `PermissionType` is a generic configuration object with information about a given permission.
/// The permission type can be used by the app to handle gracefully requesting authorization from
/// the user for access to sensors and hardware required by the app.
public protocol PermissionType {
    
    /// An identifier for the permission.
    var identifier: String { get }
}

/// An `Permission` can carry additional information about the permission
@objc public protocol Permission : AnyObject {
    
    /// An identifier for the permission.
    var identifier: String { get }
    
    /// A title for this permission.
    var title: String? { get }
    
    /// Additional reason for requiring the permission.
    var reason: String? { get }
    
    /// The failure message to show for this authorization status.
    func message(for status: PermissionAuthorizationStatus) -> String?
}


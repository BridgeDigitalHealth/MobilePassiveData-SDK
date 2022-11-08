//
//  PermissionsConfiguration.swift
//
//

import Foundation

/// A model object that defines a configuration for permissions to be requested either as a part of
/// a step or an async action.
public protocol PermissionsConfiguration {
    
    /// List of the permissions required for this action.
    var permissionTypes: [PermissionType] { get }
}

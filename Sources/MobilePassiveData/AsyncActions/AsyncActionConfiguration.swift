//
//  AsyncActionConfiguration.swift
//  
//

import Foundation

/// `AsyncActionConfiguration` defines general configuration for an asynchronous background action
/// that should be run in the background. Depending upon the parameters and how the action is set
/// up, this could be something that is run continuously or else is paused or reset based on a
/// timeout interval.
///
/// The configuration is intended to be a serializable object and does not call services, record
/// data, or anything else.
///
/// - seealso: `AsyncActionController`.
///
public protocol AsyncActionConfiguration : PermissionsConfiguration {
    
    /// A short string that uniquely identifies the asynchronous action within the task.
    var identifier : String { get }
    
    /// The type of the async action.
    var typeName : String { get }
    
    /// An identifier marking the step at which to start the action. If `nil`, then the action will
    /// be started when the task is started.
    var startStepIdentifier: String? { get }
    
    /// Validate the async action to check for any configuration that should throw an error.
    func validate() throws
}

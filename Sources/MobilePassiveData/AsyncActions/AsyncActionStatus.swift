//
//  AsyncActionStatus.swift
//  
//

import Foundation

/// `AsyncActionStatus` is an enum used to track the status of an `AsyncAction`.
@objc
public enum AsyncActionStatus : Int {
    
    /// Initial state before the controller has been started.
    case idle = 0
    
    /// Status if the controller is currently requesting authorization. Once in this state and
    /// until the controller is `starting`, the UI should be blocked from any view transitions.
    case requestingPermission
    
    /// Status if the controller has granted permission, but not yet been started.
    case permissionGranted
    
    /// The controller is starting up. This is the state once `AsyncAction.start()` has been
    /// called but before the recorder or request is running.
    case starting
    
    /// The action is running. For `RecorderConfiguration` controllers, this means that the
    /// recording is open. For `RequestConfiguration` controllers, this means that the request is
    /// in-flight.
    case running
    
    /// Waiting for in-flight buffers to be appended and ready to close.
    case waitingToStop
    
    /// Cleaning up by closing any buffers or file handles and processing any results that are
    /// returned by this controller.
    case processingResults
    
    /// Stopping any sensor managers. The controller should move to this state **after** any
    /// results are processed.
    /// - note: Once in this state, the async action should **not** be changing the results
    /// associated with this action.
    case stopping
    
    /// The controller is finished running and ready to `dealloc`.
    case finished
    
    /// The recorder or request was cancelled and any results may be invalid.
    case cancelled
    
    /// The recorder or request failed and any results may be invalid.
    case failed
}

extension AsyncActionStatus : Comparable {
    public static func <(lhs: AsyncActionStatus, rhs: AsyncActionStatus) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension AsyncActionStatus : CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .requestingPermission:
            return "requestingPermission"
        case .permissionGranted:
            return "permissionGranted"
        case .starting:
            return "starting"
        case .running:
            return "running"
        case .waitingToStop:
            return "waitingToStop"
        case .processingResults:
            return "processingResults"
        case .stopping:
            return "stopping"
        case .finished:
            return "finished"
        case .cancelled:
            return "cancelled"
        case .failed:
            return "failed"
        }
    }
}

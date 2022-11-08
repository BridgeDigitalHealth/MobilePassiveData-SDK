//
//  AsyncActionController.swift
//  
//

import Foundation
import JsonModel
import ResultModel

/// `AsyncActionVendor` is an extension of the configuration protocol for configurations that
/// know how to vend a new controller.
///
public protocol AsyncActionVendor : AsyncActionConfiguration {
    
    /// Instantiate a controller appropriate to this configuration.
    /// - parameters:
    ///     - outputDirectory: File URL for the directory in which to store generated data files.
    ///     - initialStepPath: The initial step path to use for the controller.
    ///     - sectionIdentifier: The section identifier for this controller.
    /// - returns: An async action controller or nil if the async action is not supported on this device.
    func instantiateController(outputDirectory: URL,
                               initialStepPath: String?,
                               sectionIdentifier: String?) -> AsyncActionController?
}

/// The completion handler for starting and stopping an async action.
public typealias AsyncActionCompletionHandler = (AsyncActionController, ResultData?, Error?) -> Void

/// `AsyncActionControllerDelegate` is the delegate protocol for `AsyncActionController`.
public protocol AsyncActionControllerDelegate : AnyObject {
    
    /// Method called when the controller fails. The delegate is responsible
    /// for handling the UI/UX and graceful exit (if needed) for failures.
    func asyncAction(_ controller: AsyncActionController, didFailWith error: Error)
    
    /// Find an answer with a given `identifier`. Typically, this will be used to allow the delegate to
    /// get answers to demographics questions from the data sources available to the delegate. The
    /// method returns a `JsonElement` to allow for a cross-platform compatible value that is of a
    /// known type (ie. JSON).
    ///
    /// - parameter identifier: The identifier associated with the result.
    /// - returns: The result or `nil` if not found.
    func findAnswerValue(with identifier: String) -> JsonElement?
}

/// A controller for an async action configuration.
public protocol AsyncActionController : AnyObject {
    
    /// Object equality.
    func isEqual(_ object: Any?) -> Bool
    
    /// Delegate callback for handling action completed or failed.
    var delegate: AsyncActionControllerDelegate? { get set }
    
    /// The status of the controller.
    var status: AsyncActionStatus { get }
    
    /// The current `stepPath` to record to log samples.
    var currentStepPath: String { get }
    
    /// The last error on the controller.
    /// - note: Under certain circumstances, getting an error will not result in a terminal failure
    /// of the controller. For example, if a controller is both processing motion and camera
    /// sensors and only the motion sensors failed but using them is a secondary action.
    var error: Error? { get }
    
    /// Results for this action controller.
    var result: ResultData? { get }
    
    /// The configuration used to set up the controller.
    var configuration: AsyncActionConfiguration { get }
    
    /// This method should be called on the main thread with the completion handler also called on
    /// the main thread. This method is intended to allow the controller to request any permissions
    /// associated with this controller *before* the step change happens.
    ///
    /// It is the responsibility of the controller to manage the display of any alerts that are not
    /// controlled by the OS. The `viewController` parameter is the view controler that should be
    /// used to present any modal dialogs.
    ///
    /// - note: The calling view controller or application delegate should block any UI presentation
    /// changes until *after* the completion handler is called to ensure that any modals presented
    /// by the async controller or the OS aren't swallowed by other UI events.
    ///
    /// - remark: The controller should call the completion handler with an `Error` if authorization
    /// failed. Whether or not the completion handler includes a non-nil result that includes the
    /// authorization status, is up to the developers and researchers using this controller as a
    /// tool for gathering information for their study.
    ///
    /// - parameters:
    ///     - viewController: The view controler that should be used to present any modal dialogs.
    ///     - completion: The completion handler.
    func requestPermissions(on viewController: Any, _ completion: @escaping AsyncActionCompletionHandler)
    
    /// Start the asynchronous action with the given completion handler.
    /// - note: The handler may be called on a background thread.
    /// - parameter completion: The completion handler to call once the controller is started.
    func start(_ completion: AsyncActionCompletionHandler?)
    
    /// Stop the action with the given completion handler.
    /// - note: The handler may be called on a background thread.
    /// - parameter completion: The completion handler to call once the controller has processed its results.
    func stop(_ completion: AsyncActionCompletionHandler?)
    
    /// Cancel the action.
    func cancel()
    
    /// Let the controller know that the task will move to the given step.
    /// - parameters:
    ///     - stepPath: An identifier path for the current step.
    func moveTo(stepPath: String)
}


//
//  SampleRecorder.swift
//


import Foundation
import Combine
import JsonModel
import ResultModel

public protocol ClockProxy : AnyObject {

    /// A marker for when the clock was started. This could be either a ``ClockUptime`` (ie. computer clock) or
    /// a ``SystemUptime`` (ie. processor clock).
    var startTime: TimeInterval { get }
    
    /// The date timestamp when the clock was started.
    var startDate: Date { get }
    
    /// Whether or not the clock is currently paused.
    var isPaused: Bool { get }
    
    /// The time interval marking "now".
    func now() -> TimeInterval

    /// Pause the clock.
    @MainActor func pause()
    
    /// Resume running the clock.
    @MainActor func resume()
    
    /// Reset the clock (zero).
    @MainActor func reset()
    
    /// How long has this clock been running.
    @MainActor func runningDuration() -> SecondDuration
    
    /// Get the clock uptime for a system awake time. This could be either a ``ClockUptime`` (ie. computer clock) or
    /// a ``SystemUptime`` (ie. processor clock).
    @MainActor func relativeUptime(to timestamp: SystemUptime) -> TimeInterval
    
    /// Get the duration (in seconds) between the given `ProcessInfo.processInfo.systemUptime` and when
    /// the clock was started. This is different from ``runningDuration(timestamp:)`` in that it does not subtract
    /// ``pauseCumulation`` or look at whether or not the clock has been stopped.
    /// - Parameter timestamp: The timestamp (processor clock) to use in calculating duration.
    /// - Returns: The calculated time between the timestamp and when the clock was started.
    @MainActor func zeroRelativeTime(to timestamp: SystemUptime) -> SecondDuration
}

/// `SampleRecorder` is a base-class implementation of a controller that is used to record samples.
///
/// While it isn't prohibited to instantiate this class directly, this is *intended* as an abstract
/// implementation for recording sample data from GPS location, accelerometers, etc.
///
/// Using this base implementation allows for a consistent logging of shared sample data key words
/// for the step path and the uptime. It implements the logic for writing to a file, tracking the
/// uptime and start date, and provides a consistent implementation for error handling.
open class SampleRecorder : NSObject, AsyncActionController, ObservableObject {
    
    /// Errors returned in the completion handler during `start()` when starting fails for timing reasons.
    public enum RecorderError : Error {
        
        /// Returned when the recorder has already been started.
        case alreadyRunning
        
        /// Returned when the recorder that has been cancelled, failed, or finished.
        case finished
        
        /// Returned when the recorder or task was interrupted.
        case interrupted
    }
    
    /// Default initializer.
    /// - parameters:
    ///     - configuration: The configuration used to set up the controller.
    ///     - initialStepPath: The initial step path to use for the recorder.
    ///     - sectionIdentifier: The section identifier for this recorder.
    ///     - outputDirectory: File URL for the directory in which to store generated data files.
    public init(configuration: AsyncActionConfiguration,
                outputDirectory: URL,
                initialStepPath: String?,
                sectionIdentifier: String?,
                clockProxy: ClockProxy? = nil) {
        self.configuration = configuration
        self.outputDirectory = outputDirectory
        self.currentStepPath = initialStepPath ?? ""
        self.sectionIdentifier = sectionIdentifier
        self.collectionResult = CollectionResultObject(identifier: configuration.identifier)
        self.clock = clockProxy ?? SimpleClock()
    }
    
    open var identifier: String {
        "\(type(of: self))/\(configuration.identifier)"
    }
    
    /// The current `stepPath` to record to log samples.
    @Published public private(set) var currentStepPath: String
    
    /// The section identifier for this recorder. In practice, this identifier is used to
    /// differentiate between log files where a separate recording is made for each section of an
    /// assessment.
    public let sectionIdentifier: String?
    
    /// File URL for the directory in which to store generated data files.
    public let outputDirectory: URL

    // Mark: `AsyncActionController` implementation
    
    /// Delegate callback for handling action completed or failed.
    open weak var delegate: AsyncActionControllerDelegate?
    
    /// The configuration used to set up the controller.
    public let configuration: AsyncActionConfiguration
    
    /// The clock for this recorder.
    public let clock: ClockProxy
        
    /// The status of the recorder.
    @Published public private(set) var status: AsyncActionStatus = .idle
    
    /// The last error on the action controller.
    /// - note: Under certain circumstances, getting an error will not result in a terminal failure
    ///         of the controller. For example, if a controller is both processing motion and
    ///         camera sensors and only the motion sensors failed but using them is a secondary
    ///         action.
    public var error: Error?
    
    /// Publisher for sending an error.
    public let errorNotification = PassthroughSubject<Error, Never>()
    
    /// A list of the record markers denoting each step change.
    @MainActor private var markers: [(uptime: ClockUptime, stepPath: String)] = []

    /// Results for this recorder.
    ///
    /// The default implementation is to return the `collectionResult` if that collection has more
    /// than one child. If the collection result only has one child then that child result is
    /// returned. If there are no child results, then the recorder will return `nil`.
    ///
    /// - seealso: `collectionResult`
    open var result: ResultData? {
        guard collectionResult.children.count > 0 else { return nil }
        if collectionResult.children.count == 1 {
            return collectionResult.children.first
        } else {
            return collectionResult
        }
    }
    
    /// The collection result is used internally to allow storing multiple results associated with
    /// this recorder. For example, a location recorder may also query the pedometer and record the
    /// number of steps during a walking or running task.
    ///
    /// During initialization the recorder will instantiate an `CollectionResultObject` that can be
    /// used to collect any results attached to this recorder, including the `FileResultObject`
    /// that points to the logging file used to record the log samples.
    open private(set) var collectionResult: CollectionResultObject
    
    /// Is the recorder currently paused?
    public final var isPaused: Bool {
        clock.isPaused
    }
    
    /// Start the recorder.
    ///
    /// This method is called by the task controller to start the recorder. This implementation
    /// performs the following actions:
    /// 1. Check to see if the recorder is already running or has been cancelled and will call the
    ///     completion handler with an error if that is the case.
    /// 2. Update the `startUptime` and `startDate` to the current time.
    /// 3. Open a file for logging samples.
    /// 4. If and only if the logging file was successfully opened, then call `startRecorder()`
    ///     asynchronously on the main queue.
    ///
    /// - note: This is implemented as a `public final` class to block overriding this method.
    ///         Instead, subclasses should implement logic required to start a recorder by
    ///         overriding the `startRecorder()` method. This is done to ensure that the logging
    ///         file was successfully created before attempting to record any data to that file.
    @MainActor public final func start() async throws {
        let _: Bool = try await withCheckedThrowingContinuation { continuation in
            start { _, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    continuation.resume(returning: true)
                }
            }
        }
    }

    /// Start the recorder with the given completion handler.
    ///
    /// This method is called by the task controller to start the recorder. This implementation
    /// performs the following actions:
    /// 1. Check to see if the recorder is already running or has been cancelled and will call the
    ///     completion handler with an error if that is the case.
    /// 2. Update the `startUptime` and `startDate` to the current time.
    /// 3. Open a file for logging samples.
    /// 4. If and only if the logging file was successfully opened, then call `startRecorder()`
    ///     asynchronously on the main queue.
    ///
    /// - note: This is implemented as a `public final` class to block overriding this method.
    ///         Instead, subclasses should implement logic required to start a recorder by
    ///         overriding the `startRecorder()` method. This is done to ensure that the logging
    ///         file was successfully created before attempting to record any data to that file.
    public final func start(_ completion: AsyncActionCompletionHandler?) {

        guard self.status < AsyncActionStatus.finished else {
            self.callOnMainThread(nil, RecorderError.finished, completion)
            return
        }

        guard self.status <= .permissionGranted else {
            self.callOnMainThread(nil, RecorderError.alreadyRunning, completion)
            return
        }

        // Set paused to false and set the start uptime and timestamp
        Task {
            let stepPath: String = await MainActor.run {
                status = .starting
                clock.reset()
                return currentStepPath
            }
            _continueStart(stepPath, completion)
        }
    }
    
    private func _continueStart(_ stepPath: String, _ completion: AsyncActionCompletionHandler?) {
        self.loggerQueue.async {
            do {
                try self._startLogger(at: stepPath)
                DispatchQueue.main.async {
                    guard self.status < .finished else {
                        completion?(self, nil, RecorderError.finished)
                        return
                    }
                    self.startRecorder({ (newStatus, error) in
                        self._syncUpdateStatus(newStatus, error: error)
                        self.callOnMainThread(self.result, error ?? self.error, completion)
                    })
                }
            } catch let error {
                self.callOnMainThread(nil, error, completion)
            }
        }
    }

    /// Pause the action. The base class implementation marks the `isPaused` property as `true`.
    open func pause() {
        Task {
            await clock.pause()
        }
    }

    /// Resume the action. The base class implementation marks the `isPaused` property as `false`.
    open func resume() {
        Task {
            await clock.resume()
        }
    }
    
    /// Stop the action.
    ///
    /// This method is called by the task controller to stop the recorder. This implementation will
    /// first close the logging file and then call `stopRecorder()` asynchronously on the main queue.
    /// The `stopRecorder()` method is called whether or not there is an error when closing the
    /// logging file so that subclasses can perform any required cleanup.
    ///
    /// - note: This is implemented as a `public final` class to block overriding this method.
    ///         Instead, subclasses should implement logic required to stop a recorder by overriding
    ///         the `stopRecorder()` method. This is done to ensure that the logging file is closed
    ///         and the result is added to the result collection *before* handing over control to
    ///         the subclass.
    ///
    @MainActor public final func stop() async throws -> ResultData {
        try await withCheckedThrowingContinuation { continuation in
            stop { _, resultData, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else if let resultData = resultData {
                    continuation.resume(returning: resultData)
                }
                else {
                    continuation.resume(throwing: ValidationError.unexpectedNullObject("Both result and error are null."))
                }
            }
        }
    }

    /// Stop the action with the given completion handler.
    ///
    /// This method is called by the task controller to stop the recorder. This implementation will
    /// first close the logging file and then call `stopRecorder()` asynchronously on the main queue.
    /// The `stopRecorder()` method is called whether or not there is an error when closing the
    /// logging file so that subclasses can perform any required cleanup.
    ///
    /// - note: This is implemented as a `public final` class to block overriding this method.
    ///         Instead, subclasses should implement logic required to stop a recorder by overriding
    ///         the `stopRecorder()` method. This is done to ensure that the logging file is closed
    ///         and the result is added to the result collection *before* handing over control to
    ///         the subclass.
    ///
    public final func stop(_ completion: AsyncActionCompletionHandler?) {
        _syncUpdateStatus(.waitingToStop)
        self.loggerQueue.async {
            do {
                self._syncUpdateStatus(.processingResults)
                try self._stopLogger()
            } catch let err {
                self.error = err
            }
            DispatchQueue.main.async {
                self.stopRecorder({ (newStatus) in
                    if newStatus > self.status {
                        self._syncUpdateStatus(newStatus)
                    } else {
                        self._syncUpdateStatus(.finished)
                    }
                    self.callOnMainThread(self.result, self.error, completion)
                })
            }
        }
    }

    /// Cancel the action. The default implementation will set the `isCancelled` flag to `true` and
    /// then call `stop()` with a nil completion handler.
    open func cancel() {
        _syncUpdateStatus(.cancelled)
        Task(priority: .high) {
            try? await stop()
        }
    }

    /// Let the controller know that the task has moved to the given step. This method is called by
    /// the task controller when the task transitions to a new step. This method will update the
    /// `currentStepPath` and add a marker to each logging file.
    public final func moveTo(stepPath: String) {
        let date = Date()
        let systemUptime = ProcessInfo.processInfo.systemUptime
        Task {
            await MainActor.run {
                let clockUptime = clock.relativeUptime(to: systemUptime)
                let timestamp = clock.zeroRelativeTime(to: systemUptime)
                currentStepPath = stepPath
                markers.append((clockUptime, stepPath))
                _writeMarkers(stepPath: stepPath, uptime: clockUptime, timestamp: timestamp, date: date)
            }
            didMoveTo(stepPath: stepPath)
        }
    }
    
    open func didMoveTo(stepPath: String) {
    }
    
    @MainActor public final func stepPath(for timestamp: SystemUptime) -> String {
        let uptime = clock.relativeUptime(to: timestamp)
        return markers.first(where: { $0.uptime < uptime }).map { $0.stepPath } ?? currentStepPath
    }
    
    /// This method should be called on the main thread with the completion handler also called on
    /// the main thread. The base class implementation will immediately call the completion handler.
    @MainActor public final func requestPermissions() async throws -> ResultData {
        try await withCheckedThrowingContinuation { continuation in
            requestPermissions(on: self) { _, resultData, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else if let resultData = resultData {
                    continuation.resume(returning: resultData)
                }
                else {
                    continuation.resume(throwing: ValidationError.unexpectedNullObject("Both result and error are null."))
                }
            }
        }
    }
    
    /// This method should be called on the main thread with the completion handler also called on
    /// the main thread. The base class implementation will immediately call the completion handler.
    ///
    /// - remark: Override to implement custom permission handling.
    /// - parameters:
    ///     - viewController: The view controler that should be used to present any modal dialogs.
    ///     - completion: The completion handler.
    open func requestPermissions(on viewController: Any, _ completion: @escaping AsyncActionCompletionHandler) {
        _syncUpdateStatus(.permissionGranted)
        completion(self, self.result, nil)
    }

    // MARK: State management

    /// Is this recorder running in the simulator?
    public let isSimulator: Bool = {
        #if (arch(i386) || arch(x86_64)) && !os(macOS)
            return true
        #else
            return false
        #endif
    }()

    /// The date timestamp for when the recorder was started.
    public var startDate: Date {
        return clock.startDate
    }

    /// The identifier for tracking the current step.
    public private(set) var currentStepIdentifier: String = ""

    /// A conveniece method for calling the result handler on the main thread asynchronously.
    private func callOnMainThread(_ result: ResultData?, _ error: Error?, _ completion: AsyncActionCompletionHandler?) {
        DispatchQueue.main.async {
            completion?(self, result, error)
        }
    }

    /// This method is called during startup after the logger is setup to start the recorder. The
    /// base class implementation will immediately call the completion handler. If an overriding
    /// class needs to do any initialization to start the recorder, then override this method.
    /// If the override calls the completion handler then **DO NOT** call super. This method is
    /// called from `start()` on the main thread queue.
    ///
    /// - parameter completion: Callback for updating the status of the recorder once startup has
    ///                         completed (or failed).
    open func startRecorder(_ completion: @escaping ((AsyncActionStatus, Error?) -> Void)) {
        completion(.running, nil)
    }

    /// This method is called during finish after the logger is closed. The base class
    /// implementation will immediately call the completion handler. If an overriding class needs
    /// to do any actions to stop the recorder, then override this method. If the override calls
    /// the completion handler then **DO NOT** call super. Otherwise, super will call the
    /// completion with the logger error as the input to the completion handler. This method is
    /// called from `stop()` on the main thread queue.
    ///
    /// - parameter completion: Callback for updating the status of the recorder once startup has
    ///                         completed (or failed).
    open func stopRecorder(_ completion: @escaping ((AsyncActionStatus) -> Void)) {
        completion(.finished)
    }

    /// This method can be called by either the logging file if there was a write error, or by the
    /// subclass if there was an error when attempting to record samples. The method will call the
    /// delegate method `asyncAction(_, didFailWith:)` asynchronously on the main queue and will
    /// call `cancel()` synchronously on the current queue.
    open func didFail(with error: Error) {
        guard self.status <= .running else { return }
        _syncUpdateStatus(.failed, error: error)
        if self.status == .running {
            self.errorNotification.send(error)
        }
        DispatchQueue.main.async {
            self.delegate?.asyncAction(self, didFailWith: error)
        }
        cancel()
    }

    /// Append the `collectionResult` with the given result.
    /// - parameter result: The result to add to the collection.
    public final func appendResults(_ result: ResultData) {
        guard self.status <= .processingResults else {
            debugPrint("WARNING: Attempting to append the result set after status has been locked. \(self.status)")
            return
        }
        self.collectionResult.children.removeAll(where: { $0.identifier == result.identifier })
        self.collectionResult.children.append(result)
    }

    /// This method will synchronously update the status and is expected to **only** be called by a
    /// subclass to allow subclasses to transition the status from `.processingResults` to
    /// `.stopping` and then `.finished` or from `.starting` to `.running`.
    public final func updateStatus(to newStatus: AsyncActionStatus, error: Error?) {
        _syncUpdateStatus(newStatus, error: error)
    }

    /// Synchronously update the status. If called from a background thread, then this call will block until
    /// the main thread is available. The status is only changed on the main thread to ensure that KVO observers
    /// are on the main thread and also to ensure that the status is changed synchronously.
    private func _syncUpdateStatus(_ newStatus: AsyncActionStatus, error: Error? = nil) {
        // Status transitions are sequential so do not change the status if the new status is not greater than
        // the current status
        guard newStatus > self.status else { return }

        // Check if this is the main thread and if not, then call it *synchronously* on the main thread.
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self._syncUpdateStatus(newStatus, error: error)
            }
            return
        }

        // Change the status
        self.status = newStatus
        self.error = error
    }

    // MARK: Logger handling

    /// The serial queue used for writing samples to the log files. To ensure that write failures due to memory
    /// warnings do not get thrown by multiple threads, a single logging queue is used for writing to all the
    /// open log files.
    public let loggerQueue = DispatchQueue(label: "org.sagebase.Research.Recorder.\(UUID())")

    /// The loggers used to record samples to a file.
    public private(set) var loggers: [String : DataLogger] = [:]

    /// The list of identifiers for the loggers. For each unique identifier in this list, the recorder
    /// will open a file for recording record samples. This allows a single recorder to handle data from
    /// multiple sensors.
    ///
    /// For example, if the application requires recording both raw accelerometer data and the device
    /// motion data, these can be recordeded to different sample files by defining a unique identifier
    /// for each sensor recording, while using a single `CMMotionManager` as recommended by Apple.
    open var loggerIdentifiers : Set<String> {
        return [defaultLoggerIdentifier]
    }

    /// The default logger identifier to call if the `writeSample()` method is called without a logger
    /// identifier.
    open var defaultLoggerIdentifier : String {
        return "\(filePrefix)\(configuration.identifier)"
    }

    /// A prefix to add to all log files.
    open var filePrefix: String {
        (self.sectionIdentifier != nil) ? "\(self.sectionIdentifier!)_" : ""
    }

    /// Should the logger use a dictionary as the root element?
    ///
    /// If `true` then the logger will open the file with the samples included in an array with the key
    /// of "items". If `false` then the file will use an array as the root elemenent and the samples will
    /// be added to that array.
    open var usesRootDictionary: Bool {
        return (self.configuration as? JsonRecorderConfiguration)?.usesRootDictionary ?? false
    }

    /// Should the log file include step transition markers? Default = `true`
    /// If `false`, then the a transition between steps will *not* add a marker record.
    /// - seealso: `instantiateMarker()`
    open var shouldIncludeMarkers: Bool {
        true
    }

    /// instantiate a marker for recording step transitions as well as start and stop points.
    /// The default implementation will instantiate a `RecordMarker`.
    ///
    /// - parameters:
    ///     - uptime: The system clock time.
    ///     - timestamp: Relative timestamp for this recorder.
    ///     - date: The timestamp date.
    ///     - stepPath: The step path.
    ///     - loggerIdentifier: The identifier for the logger for which to create the marker.
    /// - returns: A sample to add to the log file that can be used as a step transition marker.
    open func instantiateMarker(uptime: ClockUptime, timestamp: SecondDuration, date: Date, stepPath: String, loggerIdentifier: String) -> SampleRecord {
        RecordMarker(uptime: uptime, timestamp: timestamp, date: date, stepPath: stepPath)
    }

    /// Write a sample to the logger.
    /// - parameters:
    ///     - sample: sample: The sample to add to the logging file.
    ///     - loggerIdentifier: The identifier for the logger for which to create the marker. If nil, then the
    ///                         `defaultLoggerIdentifier` will be used.
    public final func writeSample(_ sample: SampleRecord, loggerIdentifier:String? = nil) {
        self.loggerQueue.async {
            // Only write to the file if the recorder status indicates that the logging file is open
            guard self.status >= .starting && self.status <= .running else { return }

            let identifier = loggerIdentifier ?? self.defaultLoggerIdentifier
            guard let logger = self.loggers[identifier] as? RecordSampleLogger else { return }
            do {
                try logger.writeSample(sample)
            } catch let err {
                DispatchQueue.global().async {
                    self.didFail(with: err)
                }
            }
        }
    }

    /// Write multiple samples to the logger.
    /// - parameters:
    ///     - samples: The samples to add to the logging file.
    ///     - loggerIdentifier: The identifier for the logger for which to create the marker. If nil, then the
    ///                         `defaultLoggerIdentifier` will be used.
    public final func writeSamples(_ samples: [SampleRecord], loggerIdentifier:String? = nil) {
        self.loggerQueue.async {
            // Only write to the file if the recorder status indicates that the logging file is open
            guard self.status >= .starting && self.status <= .running else { return }

            // Check that the logger hasn't been closed and nil'd
            let identifier = loggerIdentifier ?? self.defaultLoggerIdentifier
            guard let logger = self.loggers[identifier] as? RecordSampleLogger else { return }
            do {
                try logger.writeSamples(samples)
            } catch let err {
                DispatchQueue.global().async {
                    self.didFail(with: err)
                }
            }
        }
    }

    /// Instantiate the logger file for the given identifier.
    ///
    /// By default, the file will be created using the `FileUtility.createFileURL()` utility method
    /// to create a URL in the `outputDirectory`. A `RecordSampleLogger` is returned by default.
    ///
    /// - parameter identifier: The unique identifier for the logger.
    /// - returns: A new instance of a `DataLogger`.
    /// - throws: An error if opening the log file failed.
    open func instantiateLogger(with identifier: String) throws -> DataLogger? {
        let format = stringEncodingFormat()
        let ext = format?.fileExtension ?? "json"
        let shouldDelete = (self.configuration as? RestartableRecorderConfiguration)?.shouldDeletePrevious ?? false
        let url = try FileUtility.createFileURL(identifier: identifier, ext: ext, outputDirectory: outputDirectory, shouldDeletePrevious: shouldDelete)
        return try RecordSampleLogger(identifier: identifier,
                                      url: url,
                                      usesRootDictionary: self.usesRootDictionary,
                                      stringEncodingFormat: format)
    }

    /// Returns the string encoding format to use for this file. Default is `nil`. If this is `nil`
    /// then the file will be formatted using JSON encoding.
    open func stringEncodingFormat() -> StringSeparatedEncodingFormat? {
        return nil
    }

    /// Write a marker to each logging file.
    private func _writeMarkers(stepPath: String, uptime: ClockUptime, timestamp: SystemUptime, date: Date) {
        self.loggerQueue.async {

            // Only write to the file if the recorder status indicates that the logging file is open
            guard self.shouldIncludeMarkers,
                self.status >= .starting && self.status <= .running
                else {
                    return
            }

            do {
                for (identifier, dataLogger) in self.loggers {
                    guard let logger = dataLogger as? RecordSampleLogger else { continue }
                    let marker = self.instantiateMarker(uptime: uptime, timestamp: timestamp, date: date, stepPath: stepPath, loggerIdentifier: identifier)
                    try logger.writeSample(marker)
                }
            } catch let err {
                DispatchQueue.global().async {
                    self.didFail(with: err)
                }
            }
        }
    }

    /// Open log files. This method should be called on the `loggerQueue`.
    private func _startLogger(at stepPath: String) throws {
        for identifier in self.loggerIdentifiers {
            guard let dataLogger = try instantiateLogger(with: identifier) else {
                continue
            }
            loggers[identifier] = dataLogger
            if let logger = dataLogger as? RecordSampleLogger, self.shouldIncludeMarkers {
                let marker = instantiateMarker(uptime: clock.startTime, timestamp: 0, date: self.clock.startDate, stepPath: stepPath, loggerIdentifier: identifier)
                try logger.writeSample(marker)
            }
        }
    }
    
    open private(set) var schemaDoc : DocumentableRootArray?

    open func instantiateFileResult(for fileHandle: LogFileHandle) -> FileResultObject {
        // The result identifier is the logger identifer without the section identifier prefix
        let identifier = fileHandle.identifier.hasPrefix(filePrefix) ?
            String(fileHandle.identifier.dropFirst(filePrefix.count)) : fileHandle.identifier
        var fileResult: FileResultObject = {
            if let schema = self.schemaDoc {
                return .init(identifier: identifier,
                             url: fileHandle.url,
                             rootSchema: schema,
                             startUptime: clock.startTime)
            }
            else {
                return .init(identifier: identifier,
                             url: fileHandle.url,
                             contentType: fileHandle.contentType,
                             startUptime: clock.startTime)
            }
        }()
        fileResult.startDate = self.startDate
        fileResult.endDate = Date()
        return fileResult
    }

    /// Close log files. This method should be called on the `loggerQueue`.
    private func _stopLogger() throws {
        var error: Error?
        for (_, logger) in self.loggers {
            do {
                try logger.close()

                // Create and add the result
                let fileResult = instantiateFileResult(for: logger)
                self.appendResults(fileResult)
            }
            catch let err {
                error = err
            }
        }

        // Close all the loggers
        loggers = [:]

        // throw the last caught error if there was one
        if error != nil {
            throw error!
        }
    }
}



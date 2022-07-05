//
//  MotionRecorder.swift
//
//  Copyright © 2018-2022 Sage Bionetworks. All rights reserved.
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
import MobilePassiveData
import JsonModel

extension Notification.Name {
    /// Notification name posted by a `MotionRecorder` instance when it is starting. If you intend to
    /// listen for this notification in order to shut down passive motion recorders, you must pass
    /// nil for the operation queue so it gets handled synchronously on the calling queue.
    public static let MotionRecorderWillStart = Notification.Name(rawValue: "MotionRecorderWillStart")
}
    
#if os(iOS)

import UIKit
import CoreMotion
import AVFoundation

/// `MotionRecorder` is a subclass of `SampleRecorder` that implements recording core motion
/// sensor data.
///
/// If using this recorder in the background, you will need to add the privacy permission for  motion sensors to the
/// application `Info.plist` file. As of this writing (syoung 02/09/2018), the required key is:
/// `Privacy - Motion Usage Description`
///
/// TODO: syoung 07/05/2022 Refactor this recorder to use newer background sensor manager rather than
/// the hack-around of playing a silence wav file to keep the app awake.
///
/// - note: This recorder is only available on iOS devices. CoreMotion is not supported by other
///         platforms.
///
/// - seealso: `MotionRecorderType`, `MotionRecorderConfiguration`, and `MotionRecord`.
open class MotionRecorder : SampleRecorder {
    
    let audioSessionIdentifier = "org.sagebase.MotionRecorder.\(UUID())"
    
    public init(configuration: MotionRecorderConfiguration, outputDirectory: URL, initialStepPath: String?, sectionIdentifier: String?, clockProxy: ClockProxy? = nil) {
        var proxy: ClockProxy = clockProxy ?? SimpleClock()
        if proxy is SimpleClock && configuration.requiresBackgroundAudio {
            proxy = SystemClock()
        }
        super.init(configuration: configuration, outputDirectory: outputDirectory, initialStepPath: initialStepPath, sectionIdentifier: sectionIdentifier, clockProxy: proxy)
    }
    
    deinit {
        AudioSessionController.shared.stopAudioSession(on: self.audioSessionIdentifier)
    }
    
    /// The currently-running instance, if any. You should confirm that this is nil
    /// (on the main queue) before starting a passive recorder instance.
    public static var current: MotionRecorder?

    /// The most recent device motion sample. This property is updated on the motion queue.
    /// This is an `@objc dynamic` property so that listeners can be set up using KVO to
    /// observe changes to this property.
    @objc dynamic public private(set) var currentDeviceMotion: CMDeviceMotion?

    /// The most recent accelerometer data sample. This property is updated on the motion queue.
    /// This is an `@objc dynamic` property so that listeners can be set up using KVO to
    /// observe changes to this property.
    @objc dynamic public private(set) var currentAccelerometerData: CMAccelerometerData?

    /// The most recent gyro data sample. This property is updated on the motion queue.
    /// This is an `@objc dynamic` property so that listeners can be set up using KVO to
    /// observe changes to this property.
    @objc dynamic public private(set) var currentGyroData: CMGyroData?

    /// The most recent magnetometer data sample. This property is updated on the motion queue.
    /// This is an `@objc dynamic` property so that listeners can be set up using KVO to
    /// observe changes to this property.
    @objc dynamic public private(set) var currentMagnetometerData: CMMagnetometerData?

    /// The motion sensor configuration for this recorder.
    public var motionConfiguration: MotionRecorderConfiguration? {
        return self.configuration as? MotionRecorderConfiguration
    }

    /// The recorder types to use for this recording. This will be set to the `recorderTypes`
    /// from the `coreMotionConfiguration`. If that value is `nil`, then the defaults are
    /// `[.accelerometer, .gyro]` because all other non-compass measurements can be calculated
    /// from the accelerometer and gyro.
    lazy public var recorderTypes: Set<MotionRecorderType> = {
        return self.motionConfiguration?.recorderTypes ?? [.accelerometer, .gyro]
    }()

    /// The sampling frequency of the motion sensors. This will be set to the `frequency`
    /// from the `coreMotionConfiguration`. If that value is `nil`, then the default sampling
    /// rate is `100` samples per second.
    lazy public var frequency: Double = {
        return self.motionConfiguration?.frequency ?? 100
    }()

    /// For best results, only use a single motion manager to handle all motion sensor data.
    public private(set) var motionManager: CMMotionManager?

    /// The pedometer is used to request motion sensor permission since for motion sensors
    /// there is no method specifically intended for that purpose.
    private var pedometer: CMPedometer?

    /// The motion queue is the operation queue that is used for the motion updates callback.
    private let motionQueue = OperationQueue()
    
    override open var schemaDoc: DocumentableRootArray? { motionRecordSchema }

    /// Override to implement requesting permission to access the participant's motion sensors.
    override public func requestPermissions(on viewController: Any, _ completion: @escaping AsyncActionCompletionHandler) {
        guard motionConfiguration?.requiresBackgroundAudio ?? false else {
            super.requestPermissions(on: viewController, completion)
            return
        }
        
        self.updateStatus(to: .requestingPermission , error: nil)
        if MotionAuthorization.authorizationStatus() == .authorized {
            self.updateStatus(to: .permissionGranted , error: nil)
            completion(self, nil, nil)
        } else {
            MotionAuthorization.requestAuthorization { [weak self] (authStatus, error) in
                guard let strongSelf = self else { return }
                let status: AsyncActionStatus = (authStatus == .authorized) ? .permissionGranted : .failed
                strongSelf.updateStatus(to: status, error: error)
                completion(strongSelf, nil, error)
            }
        }
    }

    /// Override to start the motion sensor updates.
    override public func startRecorder(_ completion: @escaping ((AsyncActionStatus, Error?) -> Void)) {
        guard self.motionManager == nil else {
            completion(.failed, RecorderError.alreadyRunning)
            return
        }

        // Tell the world that a new motion recorder instance is running.
        NotificationCenter.default.post(name: .MotionRecorderWillStart, object: self)

        // Call completion before starting all the sensors
        // then add a block to the main queue to start the sensors
        // on the next run loop.
        completion(.running, nil)
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf._startNextRunLoop()
            if strongSelf.motionConfiguration?.requiresBackgroundAudio ?? false {
                AudioSessionController.shared.startBackgroundAudioIfNeeded(on: strongSelf.audioSessionIdentifier)
            }
        }
    }

    private func _startNextRunLoop() {
        guard self.status <= .running else { return }
        MotionRecorder.current = self

        // set up the motion manager and the frequency
        let updateInterval: TimeInterval = 1.0 / self.frequency
        let motionManager = CMMotionManager()
        self.motionManager = motionManager

        // start each sensor
        var deviceMotionStarted = false
        for motionType in recorderTypes {
            switch motionType {
            case .accelerometer:
                startAccelerometer(with: motionManager, updateInterval: updateInterval, completion: nil)
            case .gyro:
                startGyro(with: motionManager, updateInterval: updateInterval, completion: nil)
            case .magnetometer:
                startMagnetometer(with: motionManager, updateInterval: updateInterval, completion: nil)
            default:
                if !deviceMotionStarted {
                    deviceMotionStarted = true
                    startDeviceMotion(with: motionManager, updateInterval: updateInterval, completion: nil)
                }
            }
        }
    }

    func startAccelerometer(with motionManager: CMMotionManager, updateInterval: TimeInterval, completion: ((Error?) -> Void)?) {
        motionManager.stopAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] (data, error) in
            if data != nil, self?.status == .running {
                self?.currentAccelerometerData = data
                self?.recordRawSample(data!)
            } else if error != nil, self?.status != .failed {
                self?.didFail(with: error!)
            }
            completion?(error)
        }
    }

    func startGyro(with motionManager: CMMotionManager, updateInterval: TimeInterval, completion: ((Error?) -> Void)?) {
        motionManager.stopGyroUpdates()
        motionManager.gyroUpdateInterval = updateInterval
        motionManager.startGyroUpdates(to: motionQueue) { [weak self] (data, error) in
            if data != nil, self?.status == .running {
                self?.currentGyroData = data
                self?.recordRawSample(data!)
            } else if error != nil, self?.status != .failed {
                self?.didFail(with: error!)
            }
            completion?(error)
        }
    }

    func startMagnetometer(with motionManager: CMMotionManager, updateInterval: TimeInterval, completion: ((Error?) -> Void)?) {
        motionManager.stopMagnetometerUpdates()
        motionManager.magnetometerUpdateInterval = updateInterval
        motionManager.startMagnetometerUpdates(to: motionQueue) { [weak self] (data, error) in
            if data != nil, self?.status == .running {
                self?.currentMagnetometerData = data
                self?.recordRawSample(data!)
            } else if error != nil, self?.status != .failed {
                self?.didFail(with: error!)
            }
            completion?(error)
        }
    }

    func recordRawSample(_ data: MotionVectorData) {
        guard !isPaused else { return }
        Task {
            async let uptime = clock.relativeUptime(to: data.timestamp)
            async let timestamp = clock.zeroRelativeTime(to: data.timestamp)
            async let stepPath = stepPath(for: data.timestamp)
            let sample = await sample(from: data, stepPath: stepPath, uptime: uptime, timestamp: timestamp)
            self.writeSample(sample)
        }
    }
    
    open func sample(from data: MotionVectorData, stepPath: String, uptime: ClockUptime, timestamp: SecondDuration) -> SampleRecord {
        MotionRecord(stepPath: stepPath, data: data, uptime: uptime, timestamp: timestamp)
    }

    func startDeviceMotion(with motionManager: CMMotionManager, updateInterval: TimeInterval, completion: ((Error?) -> Void)?) {
        motionManager.stopDeviceMotionUpdates()
        motionManager.deviceMotionUpdateInterval = updateInterval
        let frame: CMAttitudeReferenceFrame = recorderTypes.contains(.magneticField) ? .xMagneticNorthZVertical : .xArbitraryZVertical
        motionManager.startDeviceMotionUpdates(using: frame, to: motionQueue) { [weak self] (data, error) in
            if data != nil, self?.status == .running {
                self?.currentDeviceMotion = data
                self?.recordDeviceMotionSample(data!)
            } else if error != nil, self?.status != .failed {
                self?.didFail(with: error!)
            }
            completion?(error)
        }
    }
    
    func recordDeviceMotionSample(_ data: CMDeviceMotion) {
        guard !isPaused else { return }
        let frame = motionManager?.attitudeReferenceFrame ?? CMAttitudeReferenceFrame.xArbitraryZVertical
        Task {
            async let uptime = clock.relativeUptime(to: data.timestamp)
            async let timestamp = clock.zeroRelativeTime(to: data.timestamp)
            async let stepPath = stepPath(for: data.timestamp)
            let samples = await samples(from: data, frame: frame, stepPath: stepPath, uptime: uptime, timestamp: timestamp)
            self.writeSamples(samples)
        }
    }
    
    open func samples(from data: CMDeviceMotion, frame: CMAttitudeReferenceFrame, stepPath: String, uptime: ClockUptime, timestamp: SecondDuration) -> [SampleRecord] {
        recorderTypes.compactMap {
            MotionRecord(stepPath: stepPath, data: data, referenceFrame: frame, sensorType: $0, uptime: uptime, timestamp: timestamp)
        }
    }

    /// Override to stop updating the motion sensors.
    override public func stopRecorder(_ completion: @escaping ((AsyncActionStatus) -> Void)) {

        // Call completion immediately with a "stopping" status.
        completion(.stopping)

        DispatchQueue.main.async {
            
            AudioSessionController.shared.stopAudioSession(on: self.audioSessionIdentifier)

            // Stop the updates synchronously
            if let motionManager = self.motionManager {
                for motionType in self.recorderTypes {
                    switch motionType {
                    case .accelerometer:
                        motionManager.stopAccelerometerUpdates()
                    case .gyro:
                        motionManager.stopGyroUpdates()
                    case .magnetometer:
                        motionManager.stopMagnetometerUpdates()
                    default:
                        motionManager.stopDeviceMotionUpdates()
                    }
                }
            }
            if MotionRecorder.current == self {
                MotionRecorder.current = nil
            }
            self.motionManager = nil

            // and then call finished.
            self.updateStatus(to: .finished, error: nil)
        }
    }

    /// Returns the string encoding format to use for this file. Default is `nil`. If this is `nil`
    /// then the file will be formatted using JSON encoding.
    override public func stringEncodingFormat() -> StringSeparatedEncodingFormat? {
        if self.motionConfiguration?.usesCSVEncoding == true {
            return CSVEncodingFormat<MotionRecord>()
        } else {
            return nil
        }
    }
}

#else

open class MotionRecorder : SampleRecorder {
}

#endif

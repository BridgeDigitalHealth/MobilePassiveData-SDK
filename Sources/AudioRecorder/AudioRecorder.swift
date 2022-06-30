//
//  AudioRecorder.swift
//
//  Copyright © 2020-2021 Sage Bionetworks. All rights reserved.
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

#if !os(tvOS)

import Foundation
import MobilePassiveData
import JsonModel

#if canImport(AVFoundation)
import AVFoundation
#endif


/// `AudioRecorder` is a subclass of `RSDSampleRecorder` that implements recording audio.
///
/// You will need to add the privacy permission for using the microphone to the application `Info.plist`
/// file. As of this writing (syoung 09/02/2020), the required key is:
/// - `Privacy - Microphone Usage Description`
///
/// - note: This recorder is only available on iOS devices.
///
/// - seealso: `AudioRecorderConfiguration`.
public class AudioRecorder : SampleRecorder, AVAudioRecorderDelegate {
    
    enum AudioRecorderError : Error {
        case audioSessionPlaying
    }
    
    let audioSessionIdentifier = "org.sagebase.AudioRecorder.\(UUID())"

    deinit {
        
        // Belt and suspenders. There is apparently a bug that can cause a crash if the timer is not
        // cancelled before it is deallocated. syoung 09/03/2020
        meterTimer?.cancel()
        meterTimer = nil
        
        // Stop the recorder and remove self from audio session controller.
        audioRecorder?.stop()
        audioRecorder = nil
        AudioSessionController.shared.stopAudioSession(on: audioSessionIdentifier)
    }
    
    /// The audio configuration for this recorder.
    public var audioConfiguration: AudioRecorderConfiguration? {
        return self.configuration as? AudioRecorderConfiguration
    }
    
    /// The default logger is just a file with markers for each step transition.
    public override var defaultLoggerIdentifier: String {
        "\(super.defaultLoggerIdentifier)_levels"
    }
    
    private var audioFileHandle: AudioFileHandle?
    private var audioRecorder: AVAudioRecorder?
    
    override public var schemaDoc: DocumentableRootArray? { audioLevelRecordSchema }
    
    /// Override to implement requesting permission to access the participant's microphone.
    override public func requestPermissions(on viewController: Any, _ completion: @escaping AsyncActionCompletionHandler) {
        
        // Check that the recorder is not being attached to an audio session where the
        // session is using audio in a manner that requires playback through the louder
        // speakers that are at the bottom of the phone.
        if let settings = AudioSessionController.shared.currentSettings, settings.category.isPlayback {
            self.updateStatus(to: .failed , error: AudioRecorderError.audioSessionPlaying)
            completion(self, nil, AudioRecorderError.audioSessionPlaying)
            return
        }
        
        self.updateStatus(to: .requestingPermission , error: nil)
        AudioSessionController.shared.startAudioSessionIfNeeded(on: audioSessionIdentifier, with: .recordDBLevel)
        if AudioRecorderAuthorization.authorizationStatus() == .authorized {
            self.updateStatus(to: .permissionGranted , error: nil)
            completion(self, nil, nil)
        } else {
            AudioRecorderAuthorization.requestAuthorization { [weak self] (authStatus, error) in
                guard let strongSelf = self else { return }
                let status: AsyncActionStatus = (authStatus == .authorized) ? .permissionGranted : .failed
                strongSelf.updateStatus(to: status, error: error)
                completion(strongSelf, nil, error)
            }
        }
    }
    
    /// Override to start recording audio.
    override public func startRecorder(_ completion: @escaping ((AsyncActionStatus, Error?) -> Void)) {
        guard self.audioRecorder == nil, self.audioFileHandle == nil else {
            completion(.failed, RecorderError.alreadyRunning)
            return
        }
        
        // Call completion before starting the recorder then add a block to the main queue
        // to start the recorder on the next run loop.
        completion(.running, nil)
        DispatchQueue.main.async { [weak self] in
            self?._startNextRunLoop()
        }
    }
    
    private func _startNextRunLoop() {
        guard self.status <= .running else { return }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let fileHandleIdentifier = "\(filePrefix)\(configuration.identifier)"

        do {
            let fileHandle = try AudioFileHandle(identifier: fileHandleIdentifier,
                                                 outputDirectory: outputDirectory)
            
            let recorder = try AVAudioRecorder(url: fileHandle.url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            recorder.record()
            
            self.audioRecorder = recorder
            self.audioFileHandle = fileHandle
            self.startTimer()
            
            // Set up the interruption observer.
            self.setupInterruptionObserver()
        }
        catch let err {
            self.didFail(with: err)
        }
    }
    
    public override func cancel() {
        if Thread.isMainThread {
            self.stopRecording(true)
        }
        else {
            DispatchQueue.main.sync {
                self.stopRecording(true)
            }
        }
        super.cancel()
    }

    /// Override to stop recording audio.
    override public func stopRecorder(_ completion: @escaping ((AsyncActionStatus) -> Void)) {
        if self.status < .processingResults {
            updateStatus(to: .processingResults, error: nil)
        }
        
        DispatchQueue.main.async {
            
            // Append the audio file to the results *if* it should be saved.
            let saveRecording = self.audioConfiguration?.saveAudioFile ?? false
            if saveRecording,
               self.status == .processingResults,
               let fileHandle = self.audioFileHandle {
                let result = self.instantiateFileResult(for: fileHandle)
                self.appendResults(result)
            }
            self.audioFileHandle = nil
            
            // Stop the recording before calling completion.
            self.stopRecording(!saveRecording)

            // And we're done!
            completion(.finished)
        }
    }
    
    private func stopRecording(_ shouldDelete: Bool) {
        guard let recorder = self.audioRecorder else { return }
        self.audioRecorder = nil
        
        // Stop the recorder.
        recorder.stop()
        recorder.delegate = nil
        
        // Stop listeners.
        self.stopInterruptionObserver()
        self.stopTimer()
        
        // Stop the audio session.
        AudioSessionController.shared.stopAudioSession(on: self.audioSessionIdentifier)
        
        // Delete the recording if we're not saving it.
        if shouldDelete {
            recorder.deleteRecording()
        }
    }
    
    // MARK: Record decibel level
    
    var meterTimer: DispatchSourceTimer?
    let timeInterval: TimeInterval = 1.0
    let meterUnit: String = "dbFS"  // decibel level full scale (0 to -160)
    
    /// Do not include the step transition markers in the file stream.
    public override var shouldIncludeMarkers: Bool { false }
    
    func startTimer() {
        let meterQueue = DispatchQueue(label: "org.sagebase.AudioRecorder.decibelMeter.\(UUID())", attributes: .concurrent)
        let timer = DispatchSource.makeTimerSource(flags: [], queue: meterQueue)
        timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        timer.setEventHandler { [weak self] in
            guard let strongSelf = self,
                strongSelf.status <= .running,
                let recorder = strongSelf.audioRecorder
                else {
                    return
            }
            recorder.updateMeters()
            let average = recorder.averagePower(forChannel: 0)
            let peak = recorder.peakPower(forChannel: 0)
            strongSelf.recordMeterLevels(average: average, peak: peak, uptime: SystemClock.uptime())
        }
        timer.resume()
        meterTimer = timer
    }
    
    func recordMeterLevels(average: Float, peak: Float, uptime: ClockUptime) {
        Task {
            let timestamp = await clock.runningDuration(for: uptime)
            let sample = AudioLevelRecord(uptime: uptime,
                                          timestamp: timestamp,
                                          stepPath: self.currentStepPath,
                                          timeInterval: self.timeInterval,
                                          average: convertLevel(average),
                                          peak: convertLevel(peak),
                                          unit: self.meterUnit)
            self.writeSample(sample)
        }
    }
    
    func convertLevel(_ level: Float) -> Float {
        guard level.isFinite else { return 0.0 }
        return level
    }
    
    func stopTimer() {
        meterTimer?.cancel()
        meterTimer = nil
    }
    
    // MARK: AVAudioRecorderDelegate
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        let err = error ?? RecorderError.interrupted
        self.didFail(with: err)
    }
    
    // MARK: Phone interruption
    
    private var _audioInterruptObserver: Any?
    
    func setupInterruptionObserver() {
        
        #if canImport(AVFoundation) && !os(macOS)
        
        // If the task should cancel if interrupted by a phone call, then set up a listener.
        _audioInterruptObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: rawValue), type == .began
                else {
                    return
            }

            // The recorder is not currently designed to handle phone calls and resume. Until
            // there is a use-case for prioritizing pause/resume of this recorder
            // (not currently implemented), just stop the recorder. syoung 05/21/2019
            self?.didFail(with: RecorderError.interrupted)
        })
        
        #endif
    }
    
    func stopInterruptionObserver() {
        if let observer = _audioInterruptObserver {
            NotificationCenter.default.removeObserver(observer)
            _audioInterruptObserver = nil
        }
    }
}

class AudioFileHandle : LogFileHandle {
    
    let identifier: String
    let url: URL
    var contentType: String? {
        "audio/mp4"
    }
    
    init(identifier: String, outputDirectory: URL) throws {
        self.identifier = identifier
        self.url = try FileUtility.createFileURL(identifier: identifier,
                                                 ext: "mp4",
                                                 outputDirectory: outputDirectory,
                                                 shouldDeletePrevious: false)
    }
}


#endif

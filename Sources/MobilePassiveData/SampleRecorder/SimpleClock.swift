//
//  SimpleClock.swift
//  
//

import Foundation
import Combine

#if os(iOS)
import UIKit
import AVFoundation
#endif

/// This is a simple clock used to track pause state of a recorder or active step. This can be used to pause animations,
/// timers, and/or recorders. This clock should only be used in assessments that are designed to run recorders when
/// the app is *active* and will pause if the app is inactive.
///
/// - SeeAlso: ``SystemClock``
public final class SimpleClock : ObservableObject, ClockProxy {

    /// The processor clock system uptime when this clock was started.
    public private(set) var startTime: SystemUptime = ProcessInfo.processInfo.systemUptime
    /// The total time that this clock has been paused.
    public private(set) var pauseCumulation: SecondDuration = 0
    /// The time when this clock was stopped.
    public private(set) var stopTime: SystemUptime? = nil
    /// The date timestamp for when the clock was started.
    public private(set) var startDate: Date = Date()

    /// Whether or not the clock is currently paused.
    @Published public private(set) var isPaused: Bool = false {
        didSet {
            onPauseChanged.send(isPaused)
        }
    }
    
    /// A publisher for listening to changes to the pause state of the clock.
    public let onPauseChanged = PassthroughSubject<Bool, Never>()
    
    public init() {
        Task {
            await setupNotifications()
        }
    }
    
    @MainActor func setupNotifications() {
#if os(iOS)
        // Pause/resume the clock when the app is sent to the background.
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?._handleNotification(pauseOn: true)
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?._handleNotification(pauseOn: false)
        }
        // Pause/resume the clock when the participant answers a phone call.
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] (notification) in
            guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawValue),
                  (type == .began || type == .ended)
                else {
                    return
            }
            self?._handleNotification(pauseOn: type == .began)
        }
#endif
    }
    
    private func _handleNotification(pauseOn: Bool) {
        Task {
            if pauseOn {
                await pause()
            }
            else {
                await resume()
            }
        }
    }
    
    private(set) var pauseStartTime: ClockUptime? = nil
    
    public func now() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
    
    /// Reset the clock (zero).
    public func reset() {
        startTime = now()
        stopTime = nil
        pauseStartTime = nil
        pauseCumulation = 0
        isPaused = false
    }
    
    /// Stop the clock.
    public func stop() {
        stopTime = now()
    }
    
    /// The total time that the clock is/was running.
    public func runningDuration(timestamp: SystemUptime) -> SecondDuration {
        (stopTime ?? timestamp) - startTime - pauseCumulation
    }
    
    public func runningDuration() -> SecondDuration {
        runningDuration(timestamp: ProcessInfo.processInfo.systemUptime)
    }
    
    /// How long the clock has been stopped.
    public func stoppedDuration(timestamp: SystemUptime = ProcessInfo.processInfo.systemUptime) -> SecondDuration {
        stopTime.map { timestamp - $0 } ?? 0
    }
    
    /// Get the clock uptime for a system awake time. This could be either a ``ClockUptime`` (ie. computer clock) or
    /// a ``SystemUptime`` (ie. processor clock).
    public func relativeUptime(to timestamp: SystemUptime) -> TimeInterval {
        timestamp
    }
    
    /// Get the duration (in seconds) between the given `ProcessInfo.processInfo.systemUptime` and when
    /// the clock was started. This is different from ``runningDuration(timestamp:)`` in that it does not subtract
    /// ``pauseCumulation`` or look at whether or not the clock has been stopped.
    public func zeroRelativeTime(to timestamp: SystemUptime) -> SecondDuration {
        timestamp - startTime
    }

    public func pause() {
        guard pauseStartTime == nil else { return }
        pauseStartTime = SystemClock.uptime()
        self.isPaused = true
    }
    
    public func resume() {
        guard let pauseStartTime = pauseStartTime else { return }
        pauseCumulation += (SystemClock.uptime() - pauseStartTime)
        self.pauseStartTime = nil
        self.isPaused = false
    }
}

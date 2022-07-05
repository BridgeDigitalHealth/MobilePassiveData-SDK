//
//  SimpleClock.swift
//  
//
//  Copyright © 2022 Sage Bionetworks. All rights reserved.
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
            self?.pause()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.resume()
        }
        // Pause/resume the clock when the participant answers a phone call.
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] (notification) in
            guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawValue)
                else {
                    return
            }
            
            if type == .began {
                self?.pause()
            }
            else if type == .ended {
                self?.resume()
            }
        }
#endif
    }
    
    private(set) var pauseStartTime: ClockUptime? = nil
    
    /// Reset the clock (zero).
    public func reset() {
        startTime = ProcessInfo.processInfo.systemUptime
        stopTime = nil
        pauseStartTime = nil
        pauseCumulation = 0
        isPaused = false
    }
    
    /// Stop the clock.
    public func stop() {
        stopTime = ProcessInfo.processInfo.systemUptime
    }
    
    /// The total time that the clock is/was running.
    public func runningDuration(timestamp: SystemUptime = ProcessInfo.processInfo.systemUptime) -> SecondDuration {
        (stopTime ?? timestamp) - startTime - pauseCumulation
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

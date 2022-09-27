//
//  SystemClock.swift
//
//  Copyright © 2018-2021 Sage Bionetworks. All rights reserved.
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
#endif

/// A marker for the time (in seconds) that the processor has been awake. This is equivalent to the value returned by `ProcessInfo.processInfo.systemUptime`.
public typealias SystemUptime = Double

/// A marker for the monotonic clock time (in seconds).
public typealias ClockUptime = Double

/// A duration of time in seconds.
public typealias SecondDuration = Double

/// The purpose of this class is to allow using a normalized "uptime" for processes that may need
/// to track the time while the device is asleep. This clock "stopwatch" will keep running even
/// when the device has gone to sleep.
///
/// - seealso: https://stackoverflow.com/questions/12488481/getting-ios-system-uptime-that-doesnt-pause-when-asleep/45068046#45068046
public class SystemClock : ObservableObject, ClockProxy {

    public init() {
        let clock = SystemClock.uptime()
        let system = ProcessInfo.processInfo.systemUptime
        self.startDate = Date()
        self.startUptime = clock
        self.marker = .init(clock: clock, system: system)
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] (_) in
            guard let strongSelf = self else { return }
            let clock = SystemClock.uptime()
            let system = ProcessInfo.processInfo.systemUptime
            Task {
                await strongSelf.marker.addTimeMarkers(clock, system)
            }
        }
        #endif
    }
    
    private var marker: TimeMarker
    @MainActor class TimeMarker {
        var timeMarkers: [(clock: ClockUptime, system: SystemUptime)]
        var pauseStartTime: ClockUptime? = nil
        var pauseCumulation: SecondDuration = 0
        
        nonisolated init(clock: ClockUptime, system: SystemUptime) {
            self.timeMarkers = [(clock, system)]
        }
        
        func runningDuration(for uptime: ClockUptime) -> SecondDuration {
            uptime - timeMarkers[0].clock - pauseCumulation
        }
        
        func pause(uptime: ClockUptime) {
            pauseStartTime = uptime
        }
        
        func resume(uptime: ClockUptime) {
            guard let pauseTime = pauseStartTime else { return }
            pauseCumulation += (uptime - pauseTime)
            pauseStartTime = nil
        }
        
        func relativeUptime(to systemUptime: SystemUptime) -> ClockUptime {
            let marker = timeMarkers.last { systemUptime >= $0.system } ?? timeMarkers.first!
            return marker.clock + (systemUptime - marker.system)
        }
        
        func zeroRelativeTime(to systemUptime: SystemUptime) -> SecondDuration {
            let marker = timeMarkers.last { systemUptime >= $0.system } ?? timeMarkers.first!
            return (systemUptime - marker.system) + (marker.clock - timeMarkers[0].clock)
        }
        
        func addTimeMarkers(_ clock: ClockUptime, _ system: SystemUptime) {
            timeMarkers.append((clock, system))
        }
    }
    
    /// The absolute start uptime for when this clock was instantiated. This uses the clock time rather than
    /// the system uptime that is used for tasks that will only fire when the device is awake.
    public private(set) var startUptime: ClockUptime
    
    /// The date timestamp for when the clock was instantiated.
    public private(set) var startDate: Date
    
    /// Is the clock paused?
    @Published public private(set) var isPaused: Bool = false {
        didSet {
            onPauseChanged.send(isPaused)
        }
    }
    
    public let onPauseChanged = PassthroughSubject<Bool, Never>()
    
    public var startTime: TimeInterval {
        startUptime
    }
    
    public func now() -> TimeInterval {
        SystemClock.uptime()
    }
    
    @MainActor public func reset() {
        let clock = SystemClock.uptime()
        let system = ProcessInfo.processInfo.systemUptime
        self.startDate = Date()
        self.startUptime = clock
        self.marker = .init(clock: clock, system: system)
    }
    
    /// The time interval for how long the step has been running.
    @MainActor public func runningDuration(for uptime: ClockUptime) -> SecondDuration {
        marker.runningDuration(for: uptime)
    }
    
    @MainActor public func runningDuration() -> SecondDuration {
        runningDuration(for: SystemClock.uptime())
    }
    
    /// Pause the clock.
    @MainActor public func pause() {
        let uptime: ClockUptime = SystemClock.uptime()
        guard !isPaused else { return }
        isPaused = true
        marker.pause(uptime: uptime)
    }
    
    /// Resume the clock.
    @MainActor public func resume() {
        let uptime: ClockUptime = SystemClock.uptime()
        guard isPaused else { return }
        isPaused = false
        marker.resume(uptime: uptime)
    }
    
    /// Get the clock uptime for a system awake time.
    @MainActor public func relativeUptime(to systemUptime: SystemUptime) -> TimeInterval {
        marker.relativeUptime(to: systemUptime)
    }
    
    /// Get the duration (in seconds) between the given `ProcessInfo.processInfo.systemUptime` and when
    /// the clock was started.
    @MainActor public func zeroRelativeTime(to systemUptime: SystemUptime) -> SecondDuration {
        marker.zeroRelativeTime(to: systemUptime)
    }
    
    /// Clock time.
    public static func uptime() -> ClockUptime {
        var uptime = timespec()
        guard 0 == clock_gettime(CLOCK_MONOTONIC_RAW, &uptime) else {
            print("ERROR: Could not execute clock_gettime, errno: \(errno)")
            return 0
        }
        return Double(uptime.tv_sec) + Double(uptime.tv_nsec) * 1.0e-9
    }
    
    // MARK: Test methods
    
    // DO NOT PUBLICLY EXPOSE. Included for testing only. This is a class, not a struct. It is used to
    // allow for shared logic for tracking relative times across different view controllers and recorders
    // and is not intended to be used as a Codable model object.
    
    internal init(clock: ClockUptime, system: SystemUptime, date: Date) {
        self.startDate = date
        self.startUptime = clock
        self.marker = .init(clock: clock, system: system)
    }
    
    internal func addTimeMarkers(_ clock: ClockUptime, _ system: SystemUptime) async {
        await marker.addTimeMarkers(clock, system)
    }
}

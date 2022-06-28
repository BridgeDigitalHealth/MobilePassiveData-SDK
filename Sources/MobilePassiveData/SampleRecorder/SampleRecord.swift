//
//  SampleRecord.swift
//
//  Copyright © 2017-2021 Sage Bionetworks. All rights reserved.
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

/// The `SampleRecord` defines the properties that are included with all JSON logging samples.
/// By defining a protocol, the logger can include markers for step transitions and the records
/// are defined as `Codable` but the actual `CodingKey` implementation can be changed to match
/// the requirements of the research study.
public protocol SampleRecord : Codable {
    
    /// An identifier marking the current step.
    ///
    /// This is a path marker where the path components are separated by a '/' character. This path
    /// includes the task identifier and any sections or subtasks for the full path to the current
    /// step.
    var stepPath: String { get }
    
    /// The date timestamp when the measurement was taken (if available). This should be included
    /// for the first entry to mark the start of the recording. Other than to mark step changes,
    /// the `timestampDate` is optional and should only be included if required by the research
    /// study.
    var timestampDate: Date? { get }
    
    /// A timestamp that is relative to the system uptime.
    ///
    /// This should be included for the first entry to mark the start of the recording. Other than
    /// to mark step changes, the `timestamp` is optional and should only be included if required
    /// by the research study.
    ///
    /// On Apple devices, this is the timestamp used to mark sensors that run in the foreground
    /// only such as video processing and motion sensors.
    ///
    /// syoung 04/24/2019 Per request from Sage Bionetworks' research scientists, this timestamp is
    /// "zeroed" to when the recorder is started. It should be calculated by offsetting the
    /// `ProcessInfo.processInfo.systemUptime` from the monotonic clock time to account for gaps in
    /// the sampling due to the application becoming inactive. For example, if the participant
    /// accepts a phone call while the recorder is running.
    ///
    /// -seealso: `ProcessInfo.processInfo.systemUptime`
    var timestamp: SecondDuration? { get }
}

extension SampleRecord {
    
    /// All sample records should include either `timestampDate` or `timestamp`.
    func validate() throws {
        guard (timestampDate != nil) || (timestamp != nil) else {
            let message = "Expected either timestamp or timestampDate to be non-nil"
            assertionFailure(message)
            throw ValidationError.unexpectedNullObject(message)
        }
    }
}

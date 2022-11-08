//
//  SampleRecord.swift
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

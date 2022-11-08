//
//  RecordMarker.swift
//  
//


import Foundation
import JsonModel

/// `RecordMarker` is a concrete implementation of `SampleRecord` that can be used to mark the
/// step transitions for a recording.
public struct RecordMarker : SampleRecord {
    
    /// MARK: `Codable` protocol implementation
    ///
    /// - example:
    ///
    ///     ```
    ///        {
    ///            "uptime": 1234.56,
    ///            "stepPath": "/Foo Task/sectionA/step1",
    ///            "timestampDate": "2017-10-16T22:28:09.000-07:00",
    ///            "timestamp": 0
    ///        }
    ///     ```
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case uptime, stepPath, timestampDate, timestamp
    }
    
    public let uptime: ClockUptime
    public let stepPath: String
    public let timestampDate: Date?
    public let timestamp: SecondDuration?
    
    /// Default initializer.
    /// - parameters:
    ///     - uptime: The clock uptime.
    ///     - stepPath: An identifier marking the current step.
    ///     - timestampDate: The date timestamp when the measurement was taken (if available).
    ///     - timestamp: Relative time to when the recorder was started.
    public init(uptime: ClockUptime, timestamp: SecondDuration, date: Date, stepPath: String) {
        self.uptime = uptime
        self.timestamp = timestamp
        self.stepPath = stepPath
        self.timestampDate = date
    }
}

extension RecordMarker : DocumentableStruct {
    public static func examples() -> [RecordMarker] {
        [RecordMarker(uptime: 123456789, timestamp: 0, date: Date(), stepPath: "foo/baroo")]
    }
    
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw ValidationError.invalidType("\(codingKey) is not of type \(CodingKeys.self)")
        }
        switch key {
        case .timestamp:
            return .init(propertyType: .primitive(.number),
                         propertyDescription: "Duration (in seconds) from when the recording was started.")
        case .uptime:
            return .init(propertyType: .primitive(.number),
                         propertyDescription: "System clock uptime.")
        case .timestampDate:
            return .init(propertyType: .format(.dateTime),
                         propertyDescription: "The date timestamp when the measurement was taken.")
        case .stepPath:
            return .init(propertyType: .primitive(.string),
                         propertyDescription: "An identifier marking the current step.")
        }
    }
}

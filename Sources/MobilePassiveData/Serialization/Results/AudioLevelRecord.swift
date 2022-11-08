//
//  AudioLevelRecord.swift
//  
//

import Foundation
import JsonModel

public let audioLevelRecordSchema = DocumentableRootArray(rootDocumentType: AudioLevelRecord.self,
                                              jsonSchema: .init(string: "\(AudioLevelRecord.self).json", relativeTo: kSageJsonSchemaBaseURL)!,
                                              documentDescription: "A list of timestamped dbFS audio level records recorded for the duration of an assessment.")

public struct AudioLevelRecord : SampleRecord, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case uptime, timestamp, stepPath, timestampDate, timeInterval, average, peak, unit
    }

    /// System clock time.
    public let uptime: ClockUptime?

    /// Time that the system has been awake since last reboot.
    public let timestamp: SecondDuration?

    /// An identifier marking the current step.
    public let stepPath: String

    /// The date timestamp when the measurement was taken (if available).
    public var timestampDate: Date?

    /// The sampling time interval.
    public let timeInterval: TimeInterval?

    /// The average meter level over the time interval.
    public let average: Float?

    /// The peak meter level for the time interval.
    public let peak: Float?

    /// The unit of measurement for the decibel levels.
    public let unit: String?
    
    public init(uptime: ClockUptime?,
                timestamp: SecondDuration?,
                stepPath: String,
                timestampDate: Date? = nil,
                timeInterval: TimeInterval?,
                average: Float?,
                peak: Float?,
                unit: String?) {
        self.uptime = uptime
        self.timestamp = timestamp
        self.stepPath = stepPath
        self.timestampDate = timestampDate
        self.timeInterval = timeInterval
        self.average = average
        self.peak = peak
        self.unit = unit
    }
}

extension AudioLevelRecord : DocumentableStruct {
    
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys) == CodingKeys.stepPath
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .average:
            return .init(propertyType: .primitive(.number), propertyDescription: "The average meter level over the time interval.")
        case .peak:
            return .init(propertyType: .primitive(.number), propertyDescription: "The peak meter level for the time interval.")
        case .timeInterval:
            return .init(propertyType: .primitive(.number), propertyDescription: "The sampling time interval.")
        case .unit:
            return .init(propertyType: .primitive(.string), propertyDescription: "The unit of measurement for the decibel levels.")
        case .uptime:
            return .init(propertyType: .primitive(.number), propertyDescription: "System clock time.")
        case .timestamp:
            return .init(propertyType: .primitive(.number), propertyDescription: "Time that the system has been awake since last reboot.")
        case .stepPath:
            return .init(propertyType: .primitive(.string), propertyDescription: "An identifier marking the current step.")
        case .timestampDate:
            return .init(propertyType: .format(.dateTime), propertyDescription: "The date timestamp when the measurement was taken (if available).")
        }
    }
    
    public static func examples() -> [AudioLevelRecord] {
        [AudioLevelRecord(uptime: 1234567, timestamp: 0, stepPath: "foo/one", timestampDate: nil, timeInterval: 1, average: 40.5, peak: 56.7, unit: "dbFS")]
    }
}

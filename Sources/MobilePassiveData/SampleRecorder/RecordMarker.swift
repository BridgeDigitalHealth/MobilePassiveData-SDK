//
//  RecordMarker.swift
//  
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

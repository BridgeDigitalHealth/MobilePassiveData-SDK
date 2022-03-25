//
//  AsyncActionType.swift
//  
//
//  Copyright © 2021-2022 Sage Bionetworks. All rights reserved.
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
import AssessmentModel


/// `AsyncActionType` is an extendable string enum used by the `SerializationFactory` to
/// create the appropriate result type.
public struct AsyncActionType : TypeRepresentable, Codable, Hashable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Distance Recorder Configuration
    public static let distance: AsyncActionType = "distance"
    
    /// Microphone Recorder Configuration.
    public static let microphone: AsyncActionType = "microphone"

    /// Motion Recorder Configuration.
    public static let motion: AsyncActionType = "motion"
    
    /// Weather Services Configuration
    public static let weather: AsyncActionType = "weather"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [AsyncActionType] {
        [.distance, .microphone, .motion, .weather]
    }
}

extension AsyncActionType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension AsyncActionType : DocumentableStringLiteral {
    public static func examples() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

/// `SerializableAsyncActionConfiguration` is the base implementation for `AsyncActionConfiguration`
/// that is serialized using the `Codable` protocol and the polymorphic serialization defined by
/// this framework.
///
public protocol SerializableAsyncActionConfiguration : AsyncActionConfiguration, PolymorphicRepresentable, Encodable {
    var asyncActionType: AsyncActionType { get }
}

extension SerializableAsyncActionConfiguration {
    public var typeName: String { asyncActionType.stringValue }
}


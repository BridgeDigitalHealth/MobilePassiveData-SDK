//
//  WeatherConfigurationObject.swift
//  
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

import Foundation
import JsonModel

public struct WeatherConfigurationObject : WeatherConfiguration {
    private enum CodingKeys: String, OrderedEnumCodingKey {
        case asyncActionType = "type", identifier, startStepIdentifier, _services = "services"
    }

    public private(set) var asyncActionType: AsyncActionType = .weather
    
    public init(identifier: String, services: [WeatherServiceConfigurationObject], startStepIdentifier: String? = nil) {
        self.identifier = identifier
        self._services = services
        self.startStepIdentifier = startStepIdentifier
    }

    public let identifier: String
    public let startStepIdentifier: String?
    
    public var services: [WeatherServiceConfiguration] {
        _services
    }
    private let _services: [WeatherServiceConfigurationObject]
    
    public var permissionTypes: [PermissionType] {
        [StandardPermissionType.locationWhenInUse]
    }
    
    public func validate() throws {
    }
}

extension WeatherConfigurationObject : SerializableAsyncActionConfiguration {
}

public struct WeatherServiceConfigurationObject : Codable, WeatherServiceConfiguration {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case identifier, apiKey = "key", providerName = "provider"
    }

    public let identifier: String
    public let providerName: WeatherServiceProviderName
    public let apiKey: String
    
    public init(identifier: String, providerName: WeatherServiceProviderName, apiKey: String) {
        self.identifier = identifier
        self.providerName = providerName
        self.apiKey = apiKey
    }
}

extension WeatherConfigurationObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription: "Identifier for the weather services.")
        case .asyncActionType:
            return .init(constValue: AsyncActionType.weather)
        case .startStepIdentifier:
            return .init(propertyType: .primitive(.string), propertyDescription: "Identifier for the step (if any) that should be used for starting services.")
        case ._services:
            return .init(propertyType: .referenceArray(WeatherServiceConfigurationObject.documentableType()), propertyDescription: "The configuration for each of the weather services used by this recorder.")
        }
    }
    
    public static func examples() -> [WeatherConfigurationObject] {
        [WeatherConfigurationObject(identifier: "weather",
                                    services: WeatherServiceConfigurationObject.examples(),
                                    startStepIdentifier: "countdown")]
    }
}

extension WeatherServiceConfigurationObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription: "Identifier for the service (weather or air quality)")
        case .providerName:
            return .init(propertyType: .primitive(.string), propertyDescription: "Name of service provider. For example, openWeather")
        case .apiKey:
            return .init(propertyType: .primitive(.string), propertyDescription: "The API key to use when accessing the service.")
        }
    }
    
    public static func examples() -> [WeatherServiceConfigurationObject] {
        [
            WeatherServiceConfigurationObject(identifier: "weather", providerName: "openWeather", apiKey: "ABCD"),
            WeatherServiceConfigurationObject(identifier: "airQuality", providerName: "airNow", apiKey: "ABCD"),
        ]
    }
}

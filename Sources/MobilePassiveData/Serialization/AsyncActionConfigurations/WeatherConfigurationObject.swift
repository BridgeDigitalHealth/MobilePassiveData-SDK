//
//  WeatherConfigurationObject.swift
//  
//

import Foundation
import JsonModel

@Serializable
@SerialName("weather")
public struct WeatherConfigurationObject : WeatherConfiguration, Codable {
    
    public init(identifier: String, services: [WeatherServiceConfigurationObject], startStepIdentifier: String? = nil) {
        self.identifier = identifier
        self._services = services
        self.startStepIdentifier = startStepIdentifier
    }

    public let identifier: String
    public let startStepIdentifier: String?
    
    public var services: [WeatherServiceConfiguration] {
        return  _services
    }
    @SerialName("services") private let _services: [WeatherServiceConfigurationObject]
    
    public var permissionTypes: [PermissionType] {
        [StandardPermissionType.locationWhenInUse]
    }
    
    public func validate() throws {
    }
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
        case .typeName:
            return .init(constValue: serialTypeName)
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

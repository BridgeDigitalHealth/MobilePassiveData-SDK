//
//  WeatherConfiguration.swift
//  
//

import Foundation
import JsonModel

public protocol WeatherConfiguration : AsyncActionConfiguration {
    var services: [WeatherServiceConfiguration] { get }
}

public protocol WeatherServiceConfiguration {
    var identifier: String { get }
    var providerName: WeatherServiceProviderName { get }
    var apiKey: String { get }
}

/// What is the "type" of weather service provided? This is either "weather" or "air quality".
public enum WeatherServiceType : String, Codable, StringEnumSet, DocumentableStringEnum {
    case weather, airQuality
}

/// An identifier name for the name of the weather service provider.
public struct WeatherServiceProviderName : TypeRepresentable, Codable, Hashable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let airNow: WeatherServiceProviderName = "airNow"
    public static let openWeather: WeatherServiceProviderName = "openWeather"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [WeatherServiceProviderName] {
        [.airNow, .openWeather]
    }
}

extension WeatherServiceProviderName : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension WeatherServiceProviderName : DocumentableStringLiteral {
    public static func examples() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

//
//  WeatherServiceConfiguration.swift
//

import Foundation
import MobilePassiveData

extension WeatherConfigurationObject : AsyncActionVendor {
    public func instantiateController(outputDirectory: URL, initialStepPath: String?, sectionIdentifier: String?) -> AsyncActionController? {
        WeatherRecorder(self, initialStepPath: initialStepPath)
    }
}

extension WeatherServiceConfiguration {
    func instantiateDefaultService() -> WeatherService? {
        switch self.providerName {
        case .airNow:
            return AirNowService(configuration: self)
        case .openWeather:
            return OpenWeatherService(configuration: self)
        default:
            return nil
        }
    }
}

// TODO: syoung 01/14/2021 Create a Kotlin/Native model object and implement extensions.

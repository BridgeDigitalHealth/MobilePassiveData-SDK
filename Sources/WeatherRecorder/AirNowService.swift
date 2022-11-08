//
//  AirNowService.swift
//

import Foundation
import JsonModel
import MobilePassiveData
import CoreLocation

public class AirNowService : WeatherService {

    public let configuration: WeatherServiceConfiguration
    
    init(configuration: WeatherServiceConfiguration) {
        self.configuration = configuration
    }
        
    public func fetchResult(for coordinates: CLLocation, _ completion: @escaping WeatherServiceCompletionHandler) {
        let date = Date()
        let dateString = ISO8601DateOnlyFormatter.string(from: date)
        let url = URL(string: "https://www.airnowapi.org/aq/forecast/latLong/?format=application/json&latitude=\(coordinates.coordinate.latitude)&longitude=\(coordinates.coordinate.longitude)&date=\(dateString)&distance=25&API_KEY=\(configuration.apiKey)")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            self?.processResponse(url, dateString, date, data, error, completion)
        }
        task.resume()
    }
    
    func processResponse(_ url: URL, _ dateString: String, _ date: Date, _ data: Data?, _ error: Error?, _ completion: @escaping WeatherServiceCompletionHandler) {
        guard error == nil, let json = data else {
            completion(self, nil, error)
            return
        }
        do {
            let decoder = JSONDecoder()
            let responses = try decoder.decode([ResponseObject].self, from: json)
            guard let responseObject = responses.first(where: { $0.dateForecast.trimmingCharacters(in: .whitespaces) == dateString }) else {
                print("WARNING! Failed to find valid response from \(self.configuration.providerName): dateString=\(dateString)\n\(responses)")
                let err = ValidationError.unexpectedNullObject("No valid dateForecast was returned.")
                completion(self, nil, err)
                return
            }
            let result = AirQualityServiceResult(identifier: configuration.identifier,
                                                 providerName: .airNow,
                                                 startDate: date,
                                                 aqi: responseObject.aqi,
                                                 category: responseObject.category?.copyTo())
            completion(self, [result], nil)
        }
        catch let err {
            let jsonString = String(data: json, encoding: .utf8)
            print("WARNING! \(configuration.providerName) service response decoding failed.\n\(url)\n\(String(describing: jsonString))\n")
            completion(self, nil, err)
        }
    }
    
    private struct ResponseObject : Codable {
        private enum CodingKeys : String, CodingKey {
            case dateIssue = "DateIssue", dateForecast = "DateForecast", stateCode = "StateCode", aqi = "AQI", category = "Category"
        }
        let dateIssue: String
        let dateForecast: String
        let stateCode: String?
        let aqi: Int?
        let category: Category?
        
        struct Category : Codable {
            private enum CodingKeys : String, CodingKey {
                case number = "Number", name = "Name"
            }
            let number: Int
            let name: String
            
            func copyTo() -> AirQualityServiceResult.Category {
                .init(number: self.number, name: self.name)
            }
        }
    }
}

fileprivate let exampleResponse =
    """
    [{"DateIssue":"2020-11-20 ","DateForecast":"2020-11-20 ","ReportingArea":"Yuba City/Marysville","StateCode":"CA","Latitude":39.1389,"Longitude":-121.6175,"ParameterName":"PM2.5","AQI":46,"Category":{"Number":1,"Name":"Good"},"ActionDay":false,"Discussion":"Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."},
    {"DateIssue":"2020-11-20 ","DateForecast":"2020-11-21 ","ReportingArea":"Yuba City/Marysville","StateCode":"CA","Latitude":39.1389,"Longitude":-121.6175,"ParameterName":"PM2.5","AQI":57,"Category":{"Number":2,"Name":"Moderate"},"ActionDay":false,"Discussion":"Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."},
    {"DateIssue":"2020-11-20 ","DateForecast":"2020-11-22 ","ReportingArea":"Yuba City/Marysville","StateCode":"CA","Latitude":39.1389,"Longitude":-121.6175,"ParameterName":"PM2.5","AQI":66,"Category":{"Number":2,"Name":"Moderate"},"ActionDay":false,"Discussion":"Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."}]
    """

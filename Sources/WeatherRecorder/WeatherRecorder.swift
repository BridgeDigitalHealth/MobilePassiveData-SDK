//
//  WeatherRecorder.swift
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
import CoreLocation
import MobilePassiveData
import JsonModel
import AssessmentModel

public typealias WeatherServiceCompletionHandler = (WeatherService, [WeatherServiceResponse]?, Error?) -> Void

public protocol WeatherService : AnyObject {
    var configuration: WeatherServiceConfiguration { get }
    func fetchResult(for coordinates: CLLocation, _ completion: @escaping WeatherServiceCompletionHandler)
}

/// `WeatherRecorder` is used to ping the participant's location in the background and use that to
/// query weather and air quality services.
open class WeatherRecorder : NSObject, AsyncActionController, CLLocationManagerDelegate {

    public let weatherConfiguration: WeatherConfiguration

    public init(_ config: WeatherConfiguration, initialStepPath: String?) {
        self.weatherConfiguration = config
        self.weatherResult = WeatherResult(identifier: config.identifier)
        self.currentStepPath = initialStepPath ?? ""
        super.init()
    }
    
    /// The delegate used for a callback when the location service fails.
    public weak var delegate: AsyncActionControllerDelegate?
    
    /// The location manager is used to ping the participant's current location.
    public private(set) var locationManager: CLLocationManager!
    
    /// The weather result associated with this recorder.
    public private(set) var weatherResult: WeatherResult
    
    /// The current step path.
    public private(set) var currentStepPath: String

    /// Override to request GPS and motion permissions.
    public func requestPermissions(on viewController: Any, _ completion: @escaping AsyncActionCompletionHandler) {
        self.status = .permissionGranted
        completion(self, nil, nil)
    }
    
    private func _setupLocationManager() {
        guard self.locationManager == nil else { return }
        
        // setup the location manager when asking for permissions
        let manager = CLLocationManager()
        manager.delegate = self
        #if os(iOS)
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false
        #endif
        self.locationManager = manager
    }
    
    private func _serviceFailed(status: PermissionAuthorizationStatus) {
        guard self.status < .running else { return }
        self.error = PermissionError.notAuthorized(StandardPermission.location, status)
        self.status = .failed
    }
    
    public func start(_ completion: AsyncActionCompletionHandler?) {
        guard self.status < .starting else { return }
        
        // Set the status to running and then call completion.
        self.status = .starting
        
        // Set up location manager and get authorization status
        _setupLocationManager()
        let authStatus: CLAuthorizationStatus = {
            if #available(iOS 14.0, macOS 11.0, *) {
                return self.locationManager.authorizationStatus
            } else {
                return CLLocationManager.authorizationStatus()
            }
        }()
        
        // If previously denied then do not continue
        if authStatus == .denied || authStatus == .restricted {
            let failureStatus: PermissionAuthorizationStatus = (authStatus == .restricted) ? .restricted : .denied
            _serviceFailed(status: failureStatus)
            completion?(self, nil, self.error)
            return
        }
        
        if authStatus == .notDetermined {
            self.status = .starting
            self.locationManager.requestWhenInUseAuthorization()
        }
        else {
            self.status = .running
            self.locationManager.requestLocation()
        }
        
        completion?(self, nil, self.error)
    }
    
    func authorizationGranted(for authStatus: CLAuthorizationStatus) -> Bool {
        #if os(macOS)
        return authStatus == .authorizedAlways
        #else
        return authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse
        #endif
    }
    
    private func _stopLocationUpdates() {
        guard let manager = self.locationManager else { return }
        manager.stopUpdatingLocation()
        manager.delegate = nil
        self.locationManager = nil
    }

    public func stop(_ completion: AsyncActionCompletionHandler?) {
        DispatchQueue.main.async {
            self._stopLocationUpdates()
            self.status = .finished
            completion?(self, self.weatherResult, self.error)
        }
    }
    
    public func cancel() {
        DispatchQueue.main.async {
            self._stopLocationUpdates()
            self.status = .cancelled
        }
    }
    
    // MARK: AsyncActionController wrapper properties and methods
    
    @objc dynamic public private(set) var status: AsyncActionStatus = .idle
    
    public var configuration: AsyncActionConfiguration { weatherConfiguration }
    
    public var isPaused: Bool { false }
    
    public private(set) var error: Error?
    
    open var result: ResultData? { weatherResult }
    
    public func pause() {
        // ignored
    }
    
    public func resume() {
        // ignored
    }
    
    public func moveTo(stepPath: String) {
        self.currentStepPath = stepPath
    }
    
    // MARK: CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard self.status <= .running else { return }
        let authStatus: CLAuthorizationStatus = {
            if #available(iOS 14.0, macOS 11.0, *) {
                return manager.authorizationStatus
            } else {
                return CLLocationManager.authorizationStatus()
            }
        }()
        guard authStatus != .notDetermined else { return }
        if authStatus == .denied || authStatus == .restricted {
            let status: PermissionAuthorizationStatus = (authStatus == .restricted) ? .restricted : .denied
            self._serviceFailed(status: status)
        }
        else if self.status == .starting, self.authorizationGranted(for: authStatus) {
            self.status = .running
            manager.requestLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Implement the deprecated method b/c older OS versions.
        self.locationManagerDidChangeAuthorization(manager)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard self.status <= .running else { return }
        // Once the location is updated we don't need a pointer to the manager.
        guard let currentLocation = locations.last else { return }
        self.locationManager = nil
        self.queryWeatherServices(for: currentLocation)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard self.status <= .running else { return }
        self.error = error
        self.status = .failed
        self.delegate?.asyncAction(self, didFailWith: error)
        debugPrint("WARNING! Location services did fail. \(error)")
    }
    
    // MARK: Weather services management
    
    open func instantiateService(for config: WeatherServiceConfiguration) -> WeatherService? {
        config.instantiateDefaultService()
    }
    
    /// Used to keep the instantiated services from deallocating before completion.
    private var services: [String: WeatherService] = [:]
    
    func queryWeatherServices(for location: CLLocation) {
        weatherConfiguration.services.forEach { (config) in
            guard services[config.identifier] == nil,
                let service = self.instantiateService(for: config)
            else {
                return
            }
            services[config.identifier] = service
            service.fetchResult(for: location) { [weak self] (service, results, error) in
                guard let strongSelf = self else { return }
                strongSelf.services[config.identifier] = nil
                guard error == nil, let results = results else {
                    print("WARNING! Weather service failed. \(service.configuration.providerName): \(String(describing: error))")
                    return
                }
                self?.processServiceResults(results)
            }
        }
    }
    
    func processServiceResults(_ results: [WeatherServiceResponse]) {
        guard self.status <= .running else { return }
        results.forEach { (result) in
            switch result {
            case let airQuality as AirQualityServiceResult:
                self.weatherResult.airQuality = airQuality
            case let weather as WeatherServiceResult:
                self.weatherResult.weather = weather
            default:
                print("WARNING! \(result) ignored by WeatherRecorder.")
            }
        }
    }
}


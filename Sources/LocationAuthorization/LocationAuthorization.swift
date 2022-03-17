//
//  LocationAuthorization.swift
//
//  Copyright © 2018-2022 Sage Bionetworks. All rights reserved.
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
import AssessmentModel

/// `LocationAuthorization` is a wrapper for the CoreLocation library that allows a general-purpose
/// step or task to query this library for authorization if and only if that library is required by
/// the application.
///
/// Before using this adaptor, the calling application or framework will need to register the
/// adaptor using `PermissionAuthorizationHandler.registerAdaptorIfNeeded()`.
///
/// You will need to add the privacy permission for location and motion sensors to the application
/// `Info.plist` file. As of this writing (syoung 02/08/2018), those keys are:
/// - `Privacy - Location Always and When In Use Usage Description`
/// - `Privacy - Location When In Use Usage Description`
public final class LocationAuthorization : NSObject, PermissionAuthorizationAdaptor, CLLocationManagerDelegate {
    
    enum LocationAuthorizationError : Error {
        case timeout
    }
    
    public static let shared = LocationAuthorization()
        
    public let permissions: [PermissionType] = [
        .location,
        .locationWhenInUse,
        .weather,
    ]

    /// Returns the authorization status for the location manager.
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        authorizationStatus(for: .init(permission))
    }
    
    /// Returns authorization status for `.location` and `.locationWhenInUse` permissions.
    public func authorizationStatus(for permission: PermissionType) -> PermissionAuthorizationStatus {
        switch permission {
        case .location:
            return _locationAuthorizationStatus(true)
        case .locationWhenInUse, .weather:
            return _locationAuthorizationStatus(false)
        default:
            return .notDetermined
        }
    }
    
    private func _locationAuthorizationStatus(_ requiresBackground: Bool) -> PermissionAuthorizationStatus {
        Self.authorization(for: self.locationManager, requiresBackground: requiresBackground)
    }
    
    public static func authorization(for manager: CLLocationManager, requiresBackground: Bool) -> PermissionAuthorizationStatus {
        var status: CLAuthorizationStatus!
        if Thread.isMainThread {
            status = _getAuthStatus(manager)
        }
        else {
            DispatchQueue.main.sync {
                status = _getAuthStatus(manager)
            }
        }
        return _convertAuthStatus(status, requiresBackground: requiresBackground)
    }
    
    private static func _getAuthStatus(_ manager: CLLocationManager) -> CLAuthorizationStatus {
        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
            return manager.authorizationStatus
        }
        else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    private var locationManager: CLLocationManager = CLLocationManager()
    
    private var _completion: ((PermissionAuthorizationStatus, Error?) -> Void)?
    private var _requestingType: PermissionType?
    
    /// Requests permission to access the device location.
    public func requestAuthorization(for permission: PermissionInfo, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        DispatchQueue.main.async {
            let permissionType = permission.permissionType
            let status = self.authorizationStatus(for: permissionType)
            guard status == .notDetermined, self.permissions.contains(permissionType) else {
                completion(status, nil)
                return
            }
            
            self._completion = completion
            self._requestingType = permissionType
            self.locationManager.delegate = self
            
            #if os(macOS)
            self.locationManager.requestAlwaysAuthorization()
            #elseif os(tvOS)
            self.locationManager.requestWhenInUseAuthorization()
            #else
            switch permissionType {
            case .location:
                self.locationManager.requestAlwaysAuthorization()
            default:
                self.locationManager.requestWhenInUseAuthorization()
            }
            #endif
        }
    }
    
    private static func _convertAuthStatus(_ clAuthStatus: CLAuthorizationStatus, requiresBackground: Bool) -> PermissionAuthorizationStatus {
        switch clAuthStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedWhenInUse:
            return requiresBackground ? .denied : .authorized
        default:
            return .authorized
        }
    }
    
    @available(iOS 14.0, macOS 11, tvOS 14, watchOS 7, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let rsdStatus = Self._convertAuthStatus(manager.authorizationStatus, requiresBackground: _requestingType == .location )
        _completeRequest(rsdStatus, nil)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let rsdStatus = Self._convertAuthStatus(status, requiresBackground: _requestingType == .location )
        _completeRequest(rsdStatus, nil)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _completeRequest(.denied, error)
    }
    
    private func _completeRequest(_ status: PermissionAuthorizationStatus, _ error: Error?) {
        guard status != .notDetermined else { return }
        DispatchQueue.main.async {
            self._completion?(status, error)
            self._completion = nil
        }
    }
}


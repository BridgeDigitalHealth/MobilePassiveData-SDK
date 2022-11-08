//
//  LocationAuthorization.swift
//

import Foundation
import CoreLocation
import MobilePassiveData

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
        StandardPermissionType.location,
        StandardPermissionType.locationWhenInUse,
    ]

    /// Returns the authorization status for the location manager.
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        _authStatus(for: permission).status
    }
    
    private func _authStatus(for permission: String) -> (status: PermissionAuthorizationStatus, permissionType: StandardPermissionType?) {
        guard let permissionType = StandardPermissionType(rawValue: permission),
              self.permissions.contains(where: { $0.identifier == permissionType.identifier })
            else {
                return (.notDetermined, nil)
        }
        return (authorizationStatus(for: permissionType), permissionType)
    }
    
    /// Returns authorization status for `.location` and `.locationWhenInUse` permissions.
    public func authorizationStatus(for permission: StandardPermissionType) -> PermissionAuthorizationStatus {
        switch permission {
        case .location:
            return _locationAuthorizationStatus(true)
        case .locationWhenInUse:
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
    private var _requestingType: StandardPermissionType?
    
    /// Requests permission to access the device location.
    public func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        DispatchQueue.main.async {
            let (status, pType) = self._authStatus(for: permission.identifier)
            guard status == .notDetermined, let permissionType = pType else {
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


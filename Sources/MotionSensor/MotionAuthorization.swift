//
//  MotionAuthorization.swift
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

#if os(iOS)

import UIKit
import Foundation
import CoreMotion
import MobilePassiveData
import AssessmentModel

fileprivate let _userDefaultsKey = "rsd_MotionAuthorizationStatus"

/// `MotionAuthorization` is a wrapper for the CoreMotion library that allows a general-purpose
/// step or task to query this library for authorization if and only if that library is required by
/// the application.
///
/// Before using this adaptor, the calling application or framework will need to register the
/// adaptor using `PermissionAuthorizationHandler.registerAdaptorIfNeeded()`.
///
/// You will need to add the privacy permission for  motion sensors to the application `Info.plist`
/// file. As of this writing (syoung 02/09/2018), the required key is:
/// - `Privacy - Motion Usage Description`
///
public final class MotionAuthorization : PermissionAuthorizationAdaptor {
    
    public static let shared = MotionAuthorization()
    
    init() {
        let observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] (_) in
            self?.refreshCachedAuthorization()
        }
        self._activeAppObserver = observer
        refreshCachedAuthorization()
    }
    
    deinit {
        if let observer = self._activeAppObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self._activeAppObserver = nil
    }
    
    private var _activeAppObserver: Any?
    func refreshCachedAuthorization() {
        if MotionAuthorization._cachedAuthorizationStatus() == .authorized {
            MotionAuthorization.requestAuthorization { (_, _) in
            }
        }
    }
    
    /// This adaptor is intended for checking for motion sensor permissions.
    public let permissions: [PermissionType] = [.motion]
    
    /// Returns the authorization status for the motion sensors.
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        return MotionAuthorization.authorizationStatus()
    }
    
    /// Requests permission to access the motion sensors.
    public func requestAuthorization(for permission: PermissionInfo, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        return MotionAuthorization.requestAuthorization(completion)
    }
    
    /// Returns authorization status for `.motion` permission.
    public static func authorizationStatus() -> PermissionAuthorizationStatus {
        return _cachedAuthorizationStatus()
    }
    
    /// Retain the pedometer while it's being queried.
    private static var pedometer: CMPedometer?

    /// Request authorization for access to the motion and fitness sensors.
    static public func requestAuthorization(_ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        DispatchQueue.main.async {
            // Request permission to use the pedometer.
            pedometer = CMPedometer()
            let now = Date()
            pedometer!.queryPedometerData(from: now.addingTimeInterval(-2*60), to: now) { (_, error) in
                DispatchQueue.main.async {
                    // Brittle work around for limitations of getting "motion & fitness" authorization status. The 104 code is sometimes thrown
                    // even if the app has the proper permissions. Ignore it. syoung 03/22/2018
                    if let err = error, (err as NSError).code != 104 {
                        debugPrint("Failed to query pedometer: \(err)")
                        self.setCachedAuthorization(false)
                        let error = PermissionError.notAuthorized(StandardPermission.motion, .denied)
                        completion(.denied, error)
                    } else {
                        self.pedometer = nil
                        self.setCachedAuthorization(true)
                        completion(.authorized, nil)
                    }
                }
            }
        }
    }
    
    /// Looks for a cached value and returns that if found.
    static private func _cachedAuthorizationStatus() -> PermissionAuthorizationStatus {
        if let cachedStatus = UserDefaults.standard.object(forKey: _userDefaultsKey) as? NSNumber {
            return cachedStatus.boolValue ? .authorized : .previouslyDenied
        } else {
            return .notDetermined
        }
    }
    
    /// Set the state of the cached authorization.
    static func setCachedAuthorization(_ authorized: Bool) {
        UserDefaults.standard.set(authorized, forKey: _userDefaultsKey)
    }
}

#endif

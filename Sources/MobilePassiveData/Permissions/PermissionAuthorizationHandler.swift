//
//  PermissionAuthorizationHandler.swift
//
//  Copyright © 2019-2022 Sage Bionetworks. All rights reserved.
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
import AssessmentModel

/// An authorization adapter is a class that can manage requesting authorization for a given permission.
public protocol PermissionAuthorizationAdaptor : AnyObject {
    
    /// A list of the permissions that this adaptor can manage.
    var permissions: [PermissionType] { get }
    
    /// The current status of the authorization.
    func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus
    
    /// Requesting the authorization.
    func requestAuthorization(for permission: PermissionInfo, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void))
}

public final class PermissionAuthorizationHandler : NSObject {
    
    private static var adaptors: [String : PermissionAuthorizationAdaptor] = [:]
    
    /// Register the given adaptor as the authorization adapter to use. This will only register the
    /// adaptor if another adator with the same `identifier` has not already been set. Otherwise, the
    /// state that may be held by the adaptor could be lost.
    public static func registerAdaptorIfNeeded(_ adaptor: PermissionAuthorizationAdaptor) {
        adaptor.permissions.forEach {
            guard adaptors[$0.name] == nil else { return }
            adaptors[$0.name] = adaptor
        }
    }
    
    /// Returns authorization status the given permission.
    public static func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        guard let adaptor = adaptors[permission]
            else {
                // "Starting Spring 2019, all apps submitted to the App Store that access user data will
                //  be required to include a purpose string. If you're using external libraries or SDKs,
                //  they may reference APIs that require a purpose string. While your app might not use
                //  these APIs, a purpose string is still required. You can contact the developer of the
                //  library or SDK and request they release a version of their code that doesn't contain
                //  the APIs." - syoung 05/15/2019 Message from Apple's App Store Connect.
                //
                // As a consequence of this, any permissions referenced by the recorders and view
                // controllers used by the Sage Bionetworks frameworks must be registered with the
                // authorization handler.
                assertionFailure("\(permission) was not recognized as a registered permission.")
                return .denied
        }
        return adaptor.authorizationStatus(for: permission)
    }
    
    /// Request authorization for the given permission.
    public static func requestAuthorization(for permission: PermissionInfo, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        guard let adaptor = adaptors[permission.permissionType.name]
            else {
                completion(.denied, PermissionError.notHandled("\(permission.permissionType.name) was not recognized as a registered permission."))
                return
        }
        adaptor.requestAuthorization(for: permission, completion)
    }
}

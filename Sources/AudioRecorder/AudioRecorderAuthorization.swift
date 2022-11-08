//
//  AudioRecorderAuthorization.swift
//

import Foundation
import MobilePassiveData

#if canImport(AVFoundation)
import AVFoundation
#endif

fileprivate let _userDefaultsKey = "rsd_AudioRecorderStatus"

/// `AudioRecorderAuthorization` is a wrapper for requestion permission to record audio.
///
/// Before using this adaptor, the calling application or framework will need to  register the
/// adaptor using `PermissionAuthorizationHandler.registerAdaptorIfNeeded()`.
///
/// You will need to add the privacy permission for using the microphone to the application `Info.plist`
/// file. As of this writing (syoung 09/02/2020), the required key is:
/// - `Privacy - Microphone Usage Description`
public final class AudioRecorderAuthorization : PermissionAuthorizationAdaptor {
    
    public static let shared = AudioRecorderAuthorization()
    
    /// This adaptor is intended for checking for audio recording permission.
    public let permissions: [PermissionType] = [StandardPermissionType.microphone]
    
    /// Returns the authorization status for recording audio.
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        guard permission == StandardPermissionType.microphone.rawValue else { return .notDetermined }
        return AudioRecorderAuthorization.authorizationStatus()
    }
    
    static public func authorizationStatus() -> PermissionAuthorizationStatus {
        #if os(iOS)
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .denied:
            return .denied
        case .granted:
            return .authorized
        default:
            return .notDetermined
        }
        #else
        return .authorized
        #endif
    }
    
    /// Requests permission to record.
    public func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        guard permission.identifier == StandardPermissionType.microphone.rawValue else {
            completion(.notDetermined, nil)
            return
        }
        return AudioRecorderAuthorization.requestAuthorization(completion)
    }

    /// Request authorization to record.
    static public func requestAuthorization(_ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        DispatchQueue.main.async {
            #if os(iOS)
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    completion(.authorized, nil)
                } else {
                    completion(.denied, nil)
                }
            }
            #else
            completion(.authorized, nil)
            #endif
        }
    }
}

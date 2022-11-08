//
//  NotificationsAuthorization.swift
//  
//

import Foundation
import UserNotifications

/// An authorization adapator for use when requesting permission to send local notifications. Typically, this will
/// be used during onboarding to request sending the participant notifications.
public final class NotificationsAuthorization : PermissionAuthorizationAdaptor {
    
    public init() {
    }
    
    public static let shared = NotificationsAuthorization()
        
    public let permissions: [PermissionType] = [StandardPermissionType.notifications]
    
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        .notDetermined
    }
    
    public func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (status, error) in
            DispatchQueue.main.async {
                completion(status ? .authorized : .denied, error)
            }
        }
    }
}

//
//  NotificationHandler.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import Foundation
import CloudKit
import SwiftData

#if os(iOS)
import UIKit

/// Handles remote push notifications from CloudKit to keep shared data in sync.
///
/// When a shared shopping list is modified by another user, CloudKit sends a
/// silent push notification. This handler processes the notification and triggers
/// a data refresh.
class NotificationHandler: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // CloudKit uses this token internally for push notifications.
        // No additional setup needed — CKSubscription handles it.
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            completionHandler(.noData)
            return
        }

        if notification.notificationType == .database {
            // CloudKit database changed — trigger sync
            NotificationCenter.default.post(name: .sharedDataDidChange, object: nil)
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}
#elseif os(macOS)
import AppKit

/// macOS equivalent for handling remote notifications.
class NotificationHandler: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // CloudKit uses this token internally.
    }

    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            return
        }

        if notification.notificationType == .database {
            NotificationCenter.default.post(name: .sharedDataDidChange, object: nil)
        }
    }
}
#endif

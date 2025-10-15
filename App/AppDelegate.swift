//
//  AppDelegate.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/15/25.
//

import UIKit
import UserNotifications

extension Notification.Name {
    static let incomingDeepLink = Notification.Name("incomingDeepLink")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 알림 도착 시 포그라운드 표시(원하면 배지/사운드 조절)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    // ✅ 사용자가 알림을 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        if let deeplink = info["deeplink"] as? String, let url = URL(string: deeplink) {
            DispatchQueue.main.async {
                DeepLinkCenter.shared.url = url   // ✅ 중계로 전달
            }
        }
    }
}

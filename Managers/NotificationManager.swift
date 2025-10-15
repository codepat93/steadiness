//
//  NotificationManager.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/15/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // 🔔 알림 권한 요청
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 에러: \(error.localizedDescription)")
            } else {
                print("알림 권한 상태: \(granted)")
            }
        }
    }

    // 🔔 약속 알림 스케줄 (이게 5번 코드야)
    func scheduleReminder(for habit: Habit, at components: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "꾸준앱"
        content.body = "\(habit.title) 시간이에요 ⏰"
        // Universal Link or Custom URL 사용 가능
        content.userInfo = [
            "deeplink": "https://kkujune.app/habit/\(habit.id.uuidString)"
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "reminder.\(habit.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

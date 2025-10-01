//
//  Utils.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI
import UserNotifications

extension Color {
    // 살구빛 주황 팔레트
    static let peach = Color(hex: 0xF2B184)
    static let peachDark = Color(hex: 0xE08E62)
    static let bgLight = Color(hex: 0xF5F5F7)
    static let textDark = Color(hex: 0x333333)
    static let textMid = Color(hex: 0x666666)

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF)/255,
                  green: Double((hex >> 8) & 0xFF)/255,
                  blue: Double(hex & 0xFF)/255,
                  opacity: alpha)
    }
}

enum Noti {
    static func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _,_ in }
    }

    static func scheduleDaily20() {
        var date = DateComponents()
        date.hour = 20
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "꾸준앱"
        content.body = "오늘의 약속을 확인해볼까요?"
        let req = UNNotificationRequest(identifier: "daily20", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}

enum ReminderScheduler {

    /// recurrence + scheduleDays를 해석해 실제 요일 집합을 만든다.
    static func resolvedDays(for habit: Habit) -> Set<Weekday> {
        switch habit.recurrence {
        case .daily:
            return Set(Weekday.allCases) // 매일 전체
        case .custom(let days):
            return days
        case .daysPerWeek:
            // 주3/주5의 실제 선택 요일은 scheduleDays를 사용
            if let days = habit.scheduleDays, !days.isEmpty {
                return days
            } else {
                return [] // 선택 안 되어있으면 예약하지 않음
            }
        }
    }

    static func reschedule(for habit: Habit) {
        cancel(for: habit)

        guard habit.reminderEnabled, let time = habit.reminderTime else { return }
        let days = resolvedDays(for: habit)
        guard !days.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        let hour = Calendar.current.component(.hour, from: time)
        let minute = Calendar.current.component(.minute, from: time)

        for d in days {
            var comp = DateComponents()
            comp.weekday = d.rawValue // 1=일 ... 7=토
            comp.hour = hour
            comp.minute = minute

            let trig = UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "꾸준앱"
            content.body = "\(habit.title) 시간이에요"
            content.sound = .default

            let id = "reminder.\(habit.id.uuidString).\(d.rawValue)"
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trig)
            center.add(req)
        }
    }

    static func cancel(for habit: Habit) {
        let ids = Weekday.allCases.map { "reminder.\(habit.id.uuidString).\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

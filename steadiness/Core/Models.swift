//
//  Models.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import Foundation

enum Recurrence: Hashable, Codable {
    case daily
    case daysPerWeek(Int)
    case custom(Set<Weekday>)   // Set으로 변경 (Hashable)
}

enum PeriodType: Codable, CaseIterable, Hashable {
    case monthly, quarter, halfyear
}
enum Weekday: Int, CaseIterable, Codable, Hashable {
    case sun=1, mon, tue, wed, thu, fri, sat
    var symbol: String {
        switch self {
        case .sun: "일"; case .mon: "월"; case .tue: "화"
        case .wed: "수"; case .thu: "목"; case .fri: "금"; case .sat: "토"
        }
    }
}

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var durationMin: Int
    var recurrence: Recurrence
    var periodType: PeriodType
    var createdAt: Date
    var isActive: Bool
    
    // 알림/요일
    var reminderEnabled: Bool = false
    var reminderTime: Date? = nil
    var scheduleDays: Set<Weekday>? = nil // 요일 칩 선택 결과 저장(매일이면 All)

    // ✅ 업데이트된 생성자 (새 필드까지 모두 받도록)
    init(
        id: UUID = UUID(),
        title: String,
        durationMin: Int = 5,
        recurrence: Recurrence,
        periodType: PeriodType,
        createdAt: Date = .now,
        isActive: Bool = true,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        scheduleDays: Set<Weekday>? = nil
    ) {
        self.id = id
        self.title = title
        self.durationMin = durationMin
        self.recurrence = recurrence
        self.periodType = periodType
        self.createdAt = createdAt
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.scheduleDays = scheduleDays
    }
}

struct DayRecord: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var completed: Bool
    var minutes: Int
    var note: String?

    init(id: UUID = UUID(), habitId: UUID, date: Date, completed: Bool, minutes: Int, note: String? = nil) {
        self.id = id
        self.habitId = habitId
        self.date = date
        self.completed = completed
        self.minutes = minutes
        self.note = note
    }
}

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let threshold: Int  // 필요한 스트릭 일수
    var earnedAt: Date?
}

enum DefaultBadges {
    static let all: [Achievement] = [
        .init(id: "streak_3",  title: "3일 연속",  threshold: 3),
        .init(id: "streak_7",  title: "7일 연속",  threshold: 7),
        .init(id: "streak_30", title: "30일 연속", threshold: 30)
    ]
}

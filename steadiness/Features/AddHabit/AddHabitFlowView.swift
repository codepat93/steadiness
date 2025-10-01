//
//  AddHabitFlowView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct AddHabitFlowView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var durationMin: Int = 5
    @State private var recurrence: Recurrence = .daily
    @State private var periodType: PeriodType = .monthly
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases) // daily 기본
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!

    var body: some View {
        TabView {
            StepNameView(title: $title, durationMin: $durationMin)
                .tabItem { Text("1") }.tag(0)

            // ✅ selectedDays 바인딩 전달
            StepRecurrenceView(
                recurrence: $recurrence,
                selectedDays: $selectedDays
            )
            .tabItem { Text("2") }
            .tag(1)

            // ✅ 알림 설정 토글/시간을 함께 입력
            StepGoalAndReminderView(
                periodType: $periodType,
                reminderEnabled: $reminderEnabled,
                reminderTime: $reminderTime,
                onDone: {
                    let habit = Habit(
                        title: title,
                        durationMin: durationMin,
                        recurrence: recurrence,
                        periodType: periodType,
                        createdAt: .now,
                        isActive: true,
                        reminderEnabled: reminderEnabled,
                        reminderTime: reminderEnabled ? reminderTime : nil,
                        scheduleDays: resolvedScheduleDays()
                    )
                    store.addHabit(habit)
                    ReminderScheduler.reschedule(for: habit)
                    dismiss()
                }
            )
            .tabItem { Text("3") }
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .presentationDragIndicator(.visible)
        .navigationTitle("새 약속 만들기")
    }
    
    private func resolvedScheduleDays() -> Set<Weekday>? {
        switch recurrence {
        case .daily: return Set(Weekday.allCases)
        case .custom(let days): return days
        case .daysPerWeek:
            return selectedDays.isEmpty ? nil : selectedDays
        }
    }
}

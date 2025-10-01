//
//  HomeView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @Binding var showAddFlow: Bool

    var body: some View {
        VStack(spacing: 12) {
            if store.habits.isEmpty {
                ContentUnavailableView(
                    "아직 약속이 없어요",
                    systemImage: "calendar.badge.plus",
                    description: Text("작은 약속부터 시작해볼까요?")
                )
                Button {
                    showAddFlow = true
                } label: {
                    Text("첫 약속 만들기")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.peach)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
            } else {
                List {
                    Section("오늘의 약속") {
                        ForEach(store.habits) { habit in
                            HabitCardView(habit: habit) {
                                store.toggleToday(habit)
                                // TODO: haptic / animation
                                
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAddFlow = true
                } label: { Label("새 약속", systemImage: "plus.circle.fill") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    HabitManageView()
                } label: {
                    Text("약속 관리")
                }
            }
        }
        
    }
}

struct HabitCardView: View {
    let habit: Habit
    var onToggle: () -> Void

    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack {
            Text(habit.title).font(.headline)
            Spacer()
            Button(action: {
                onToggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Image(systemName: store.isCompletedToday(habit) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(store.isCompletedToday(habit) ? .green : .gray)
                    .scaleEffect(store.isCompletedToday(habit) ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: store.isCompletedToday(habit))
            }
        }
        .padding(.vertical, 8)
    }
}

struct HabitManageView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        List {
            ForEach(store.habits) { h in
                HStack {
                    VStack(alignment: .leading) {
                        Text(h.title).font(.headline)
                        Text("\(describe(h.recurrence)) · \(h.periodTypeLabel)")
                            .font(.caption).foregroundStyle(Color.textMid)
                    }
                    Spacer()
                    NavigationLink("수정") {
                        EditHabitView(habit: h)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.peach)
                }
            }
            .onDelete { idxSet in
                idxSet.forEach { store.deleteHabit(store.habits[$0]) }
            }
        }
        .navigationTitle("내 약속 관리")
    }

    private func describe(_ r: Recurrence) -> String {
        switch r {
        case .daily: return "매일"
        case .daysPerWeek(let n): return "주 \(n)회"
        case .custom(let days):
            return days.sorted { $0.rawValue < $1.rawValue }.map(\.symbol).joined()
        }
    }
}

extension Habit {
    var periodTypeLabel: String {
        switch periodType {
        case .monthly: "월간"
        case .quarter: "분기"
        case .halfyear: "반기"
        }
    }
}

struct EditHabitView: View {
    @EnvironmentObject var store: DataStore
    @State var habit: Habit
    @Environment(\.dismiss) private var dismiss
    
    // 편집용 상태
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = .now

    var body: some View {
        Form {
            Section("약속") {
                TextField("약속 이름", text: $habit.title)
                Picker("목표 단위", selection: $habit.periodType) {
                    Text("월간").tag(PeriodType.monthly)
                    Text("분기").tag(PeriodType.quarter)
                    Text("반기").tag(PeriodType.halfyear)
                }
            }

            Section("알림") {
                Toggle("리마인더 사용", isOn: $reminderEnabled)
                if reminderEnabled {
                    DatePicker("알림 시간", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
        }
        .onAppear {
            reminderEnabled = habit.reminderEnabled
            reminderTime = habit.reminderTime ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    habit.reminderEnabled = reminderEnabled
                    habit.reminderTime = reminderEnabled ? reminderTime : nil
                    store.updateHabit(habit)
                    ReminderScheduler.reschedule(for: habit)
                    dismiss()
                }
            }
        }
    }
}

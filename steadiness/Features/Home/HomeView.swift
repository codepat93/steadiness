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

    // ✅ 바인딩 편의 이니셜라이저 (인자 없이도 컴파일되게)
    init(showAddFlow: Binding<Bool> = .constant(false)) {
        self._showAddFlow = showAddFlow
    }

    // 오늘 스냅샷
    private var summary: (done: Int, total: Int) {
        store.todayCounts()
    }
    private var todayHabits: [Habit] {
        store.todayScheduledHabits()
    }
    private var progress: Double {
        guard summary.total > 0 else { return 0 }
        return Double(summary.done) / Double(summary.total)
    }

    var body: some View {
        VStack(spacing: 0) {

            // 헤더: 날짜 + 타이틀 + 추가 버튼
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date(), format: .dateTime.year().month().day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("오늘의 약속")
                        .font(.largeTitle.bold())
                }
                Spacer()
                Button {
                    showAddFlow = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.orange)
                }
                .accessibilityLabel("약속 추가")
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // ✨ 오늘 요약 바 (작은 링 + 분수)
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.18), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress.isFinite ? progress : 0)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int((progress.isFinite ? progress : 0) * 100))%")
                        .font(.caption).bold()
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("오늘 진행률")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(summary.done) / \(summary.total) 완료")
                        .font(.headline)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            // 리스트 or 빈 상태
            if todayHabits.isEmpty {
                VStack(spacing: 12) {
                    Spacer(minLength: 24)
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 38))
                        .foregroundStyle(.gray.opacity(0.5))
                    Text("오늘은 예정된 약속이 없어요")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(todayHabits) { habit in
                        // ✅ destination 방식으로 변경 (navigationDestination 불필요)
                        NavigationLink {
                            HabitDetailView(habit: habit)   // 없으면 임시로 Text("상세 준비 중") 사용 가능
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(habit.title)
                                        .font(.headline)
                                    // 필요 시 서브텍스트(기간/시간 등) 여기에 추가
                                }
                                Spacer()
                                
                                
                                // ✅ 오른쪽: 체크 버튼 (NavigationLink와 분리)
                                Button {
                                    store.toggle(habit)
                                } label: {
                                    Image(systemName: store.isHabitCompleted(habit)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .foregroundStyle(store.isHabitCompleted(habit) ? .green : .gray.opacity(0.5))
                                        .font(.system(size: 22))
                                }
                                .buttonStyle(.plain) // 중요: 버튼 누를 때 셀 하이라이트 방지
                                
//                                // 완료 아이콘(실시간 반영)
//                                if store.isHabitCompleted(habit) {
//                                    Image(systemName: "checkmark.circle.fill")
//                                        .foregroundStyle(.green)
//                                        .font(.system(size: 22))
//                                } else {
//                                    Image(systemName: "circle")
//                                        .foregroundStyle(.gray.opacity(0.5))
//                                        .font(.system(size: 22))
//                                }
                            }
                            .padding(.vertical, 4)
                        }
                        // ✅ 스와이프 액션: 완료/취소 토글
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            let done = store.isHabitCompleted(habit)
                            Button {
                                store.toggle(habit)  // 오늘 완료/취소
                            } label: {
                                Label(done ? "취소" : "완료",
                                      systemImage: done ? "arrow.uturn.left" : "checkmark.circle.fill")
                            }
                            .tint(done ? .gray : .green)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $showAddFlow) {
            // 약속 추가 플로우 (형 프로젝트의 실제 뷰로 교체)
            AddHabitFlowView()
                .environmentObject(store)
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

//struct HabitManageView: View {
//    @EnvironmentObject var store: DataStore
//
//    var body: some View {
//        List {
//            ForEach(store.habits) { h in
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(h.title).font(.headline)
//                        Text("\(describe(h.recurrence)) · \(h.periodTypeLabel)")
//                            .font(.caption).foregroundStyle(Color.textMid)
//                    }
//                    Spacer()
//                    NavigationLink("") {
//                        EditHabitView(habit: h)
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.peach)
//                }
//            }
//            .onDelete { idxSet in
//                idxSet.forEach { store.deleteHabit(store.habits[$0]) }
//            }
//        }
//        .navigationTitle("내 약속 관리")
//    }
//
//    private func describe(_ r: Recurrence) -> String {
//        switch r {
//        case .daily: return "매일"
//        case .daysPerWeek(let n): return "주 \(n)회"
//        case .custom(let days):
//            return days.sorted { $0.rawValue < $1.rawValue }.map(\.symbol).joined()
//        }
//    }
//}

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

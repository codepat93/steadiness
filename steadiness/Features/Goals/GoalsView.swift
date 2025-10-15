//
//  GoalsView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: DataStore
    @State private var period: PeriodType = .monthly

    // 필터: 특정 약속 or 전체
    @State private var selectedHabitId: UUID? = nil
    var selectedHabit: Habit? {
        store.habits.first(where: { $0.id == selectedHabitId })
    }

    // 날짜 탭 시 상세 시트
    @State private var sheetDay: DayItem? = nil
    
    var body: some View {
        let (start, end) = store.periodDatesRolling(for: period)
        let allDays = store.days(in: start, end)

        // 히트맵 스케일용 최대 강도 계산 (선택 습관 기준)
        let maxIntensity = max(1, allDays.map { store.completedCount(on: $0, for: selectedHabit) }.max() ?? 1)

        ScrollView {
            VStack(spacing: 16) {
                // 기간 선택
                Picker("기간", selection: $period) {
                    Text("월간").tag(PeriodType.monthly)
                    Text("분기").tag(PeriodType.quarter)
                    Text("반기").tag(PeriodType.halfyear)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 습관 필터
                HStack {
                    Text("보기")
                        .font(.caption).foregroundStyle(.secondary)
                    Menu {
                        Button("전체", action: { selectedHabitId = nil })
                        ForEach(store.habits) { h in
                            Button(h.title, action: { selectedHabitId = h.id })
                        }
                    } label: {
                        Label(selectedHabit?.title ?? "전체", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // 요약 카드: 연속/최대
                HStack(spacing: 16) {
                    SummaryCard(title: "연속", value: "\(store.currentStreak())일")
                    SummaryCard(title: "최대", value: "\(store.maxStreak())일")
                }
                .padding(.horizontal)

                // 진행 링 (전체 기준 유지)
                ProgressRing(progress: store.completionRate(for: period))
                    .frame(width: 160, height: 160)

                // 히트맵 + 범례 + 탭 상세
                VStack(spacing: 8) {
                    HStack {
                        Text("히트맵").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        HeatmapLegend()
                    }
                    HeatmapView(
                        dates: allDays,
                        intensity: { d in store.completedCount(on: d, for: selectedHabit) },
                        maxIntensity: maxIntensity,
                        onTap: { d in sheetDay = DayItem(date: d) }
                    )
                }
                .padding(.horizontal)

                // 주간 막대 + 목표선
                VStack(alignment: .leading, spacing: 8) {
                    Text("주간 달성률").font(.subheadline).foregroundStyle(.secondary)
                    WeeklyBarsView(
                        items: store.weeklyRates(for: period, habit: selectedHabit),
                        weeklyTargetDays: store.weeklyTargetDays(for: selectedHabit)
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
        }
        .background(Color.bgLight.ignoresSafeArea())
        .sheet(item: $sheetDay) { item in
            DayDetailSheet(date: item.date, habit: selectedHabit)
                .environmentObject(store)
        }
    }
}

// 날짜 상세 시트
private struct DayDetailSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let habit: Habit?

    @State private var generalNote: String = ""  // 전체 메모
    @State private var habitNotes: [UUID:String] = [:] // 습관별 메모

    var body: some View {
        let cal = Calendar.current
        let title = date.formatted(date: .complete, time: .omitted)
        let items: [Habit] = {
            if let habit { return [habit] }
            return store.habits.sorted { $0.title < $1.title }
        }()

        NavigationView {
            List {
                // 전체 메모
                Section(header: Text("오늘 메모")) {
                    TextEditor(text: $generalNote)
                        .frame(minHeight: 80)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                        .onChange(of: generalNote) { txt in
                            store.upsertNote(date: date, habitId: nil, text: txt)
                        }
                }

                // 습관별 토글 & 메모
                Section(header: Text("약속")) {
                    ForEach(items) { h in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(h.title)
                                Spacer()
                                let isDone = store.records.contains {
                                    $0.habitId == h.id && $0.completed && cal.isDate($0.date, inSameDayAs: date)
                                }
                                Button {
                                    store.toggle(date: date, habit: h)
                                } label: {
                                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isDone ? .green : .gray)
                                        .font(.system(size: 22))
                                }
                            }
                            // 습관별 메모
                            TextField("이 약속에 대한 메모", text: Binding(
                                get: { habitNotes[h.id, default: store.note(for: date, habitId: h.id)?.text ?? "" ] },
                                set: { new in
                                    habitNotes[h.id] = new
                                    store.upsertNote(date: date, habitId: h.id, text: new)
                                })
                            )
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } }
            }
            .onAppear {
                generalNote = store.note(for: date, habitId: nil)?.text ?? ""
                // 초기 습관 메모 프리로드
                for h in items {
                    habitNotes[h.id] = store.note(for: date, habitId: h.id)?.text ?? ""
                }
            }
        }
    }
}

private struct DayItem: Identifiable, Equatable {
    let date: Date
    var id: Date { date }   // Date는 Hashable이라 id로 쓸 수 있음
}

// 기존 SummaryCard / ProgressRing은 그대로 사용

struct ProgressRing: View {
    let progress: Double // 0.0 ~ 1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.peach, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.title3).bold()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2).bold()
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct BadgeView: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(achievement.earnedAt == nil ? Color.gray.opacity(0.15) : .peach)
                    .frame(width: 64, height: 64)
                Image(systemName: achievementIcon)
                    .foregroundStyle(achievement.earnedAt == nil ? .gray : .white)
            }
            Text(achievement.title)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .opacity(achievement.earnedAt == nil ? 0.6 : 1.0)
    }

    private var achievementIcon: String {
        switch achievement.threshold {
        case 3: return "sparkles"
        case 7: return "flame.fill"
        default: return "medal.fill"
        }
    }
}

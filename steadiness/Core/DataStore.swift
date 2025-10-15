//
//  DataStore.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import Foundation
import SwiftUI

final class DataStore: ObservableObject {
    @Published var habits: [Habit] = [] { didSet { save() } }
    @Published var records: [DayRecord] = [] { didSet { save() } }
    @Published var achievements: [Achievement] = DefaultBadges.all { didSet { save() } }
    
    // ✅ 메모 저장
    @Published var notes: [DayNote] = [] { didSet { save() } }
    
    private let habitsFile = "habits.json"
    private let recordsFile = "records.json"
    
    // 해당 날짜+습관 완료 토글
    func toggle(date: Date, habit: Habit) {
        let cal = Calendar.current
        let key = cal.startOfDay(for: date)
        if let i = records.firstIndex(where: { $0.habitId == habit.id && cal.isDate($0.date, inSameDayAs: key) }) {
            records[i].completed.toggle()
        } else {
            records.append(.init(habitId: habit.id, date: key, completed: true, minutes: habit.durationMin))
        }
        checkAchievements()
    }

    // 메모 읽기/쓰기
    func note(for date: Date, habitId: UUID?) -> DayNote? {
        let key = Calendar.current.startOfDay(for: date)
        return notes.first { $0.habitId == habitId && Calendar.current.isDate($0.date, inSameDayAs: key) }
    }
    func upsertNote(date: Date, habitId: UUID?, text: String) {
        let key = Calendar.current.startOfDay(for: date)
        if let idx = notes.firstIndex(where: { $0.habitId == habitId && Calendar.current.isDate($0.date, inSameDayAs: key) }) {
            notes[idx].text = text
        } else {
            notes.append(DayNote(date: key, habitId: habitId, text: text))
        }
    }

    private func documentsURL(_ file: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file)
    }
    
    private func updateTodaySummary() {
//        let cal = Calendar.current
//        let todayKey = ISO8601DateFormatter().string(from: cal.startOfDay(for: .now)).prefix(10) // yyyy-mm-dd
//        // 오늘 할 일들: 단순히 모든 활성 약속 기준 (원하면 오늘 요일 필터를 추가)
//        let active = habits.filter { $0.isActive }
//        let remaining = active.filter { !isCompletedToday($0) }
//        let titles = remaining.prefix(3).map { $0.title }
//
//        let summary = TodaySummary(
//            date: String(todayKey),
//            remainingCount: remaining.count,
//            topTitles: titles
//        )
//        SharedSummary.save(summary)
    }

    // MARK: - Habit CRUD
    func addHabit(_ habit: Habit) {
        habits.append(habit)
    }

    func updateHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx] = habit
        save()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        records.removeAll { $0.habitId == habit.id }
        save()
    }

    // MARK: - Completion
    // 체크 토글 시 스트릭 기반 배지 획득 검사
    func toggleToday(_ habit: Habit) {
        let key = Calendar.current.startOfDay(for: Date())
        if let idx = records.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: key) }) {
            records[idx].completed.toggle()
        } else {
            records.append(.init(habitId: habit.id, date: key, completed: true, minutes: habit.durationMin))
        }
        checkAchievements()
    }
    
    func checkAchievements(ref: Date = .now) {
        let streak = currentStreak(ref: ref)
        for i in achievements.indices {
            if achievements[i].earnedAt == nil && streak >= achievements[i].threshold {
                achievements[i].earnedAt = Date()
                // TODO: 축하 애니메이션/알림 등
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                print("🎉 배지 획득: \(achievements[i].title)")
            }
        }
    }

    func isCompletedToday(_ habit: Habit) -> Bool {
        let key = Calendar.current.startOfDay(for: Date())
        return records.contains { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: key) && $0.completed }
    }

    // MARK: - Simple progress (period stub)
    func periodDates(for type: PeriodType, ref: Date = .now) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch type {
        case .monthly:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: ref))!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .quarter:
            // 12주 기준(단순화)
            let start = cal.date(byAdding: .weekOfYear, value: -12, to: ref)!
            return (start, ref)
        case .halfyear:
            let start = cal.date(byAdding: .weekOfYear, value: -26, to: ref)!
            return (start, ref)
        }
    }
    
    func periodDatesRolling(for type: PeriodType, ref: Date = .now) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let end = cal.startOfDay(for: ref)
        let startBase: Date
        switch type {
        case .monthly:
            startBase = cal.date(byAdding: .month, value: -1, to: end)!
        case .quarter:
            startBase = cal.date(byAdding: .month, value: -3, to: end)!
        case .halfyear:
            startBase = cal.date(byAdding: .month, value: -6, to: end)!
        }
        let start = cal.startOfDay(for: startBase)
        return (start, end)
    }

    // 사용 함수들도 롤링 버전 사용하도록 수정
    func completionRate(for type: PeriodType) -> Double {
        let (start, end) = periodDatesRolling(for: type)
        let allDays = self.days(in: start, end)                // inclusive 날짜 배열
        let total = max(1, allDays.count)                      // 분모 (0 방지)
        let completed = allDays.filter { completedCount(on: $0) > 0 }.count
        return Double(completed) / Double(total)
    }
}

extension DataStore {

    /// 특정 날짜가 완료되었는지(하루에 1개라도 완료면 true)
    func isDayCompleted(_ day: Date, cal: Calendar = .current) -> Bool {
        let key = cal.startOfDay(for: day)
        return records.contains { $0.completed && cal.isDate($0.date, inSameDayAs: key) }
    }
    
    /// 오늘 기준 현재 연속 일수 (오늘 미완료면 어제부터 카운트)
    func currentStreak(ref: Date = .now, cal: Calendar = .current) -> Int {
        var count = 0
        var d = cal.startOfDay(for: ref)
        // 오늘부터 뒤로 가며 연속 true를 누적
        while isDayCompleted(d, cal: cal) || (count == 0 && !isDayCompleted(d, cal: cal)) {
            if isDayCompleted(d, cal: cal) {
                count += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
                d = prev
            } else {
                // 오늘 미완료면 0일 스트릭
                break
            }
        }
        return count
    }
    
    /// 최대 스트릭 (히스토리 전체)
    func maxStreak(cal: Calendar = .current) -> Int {
        // 모든 기록 날짜 범위에서 스캔
        let allDays = records.map { cal.startOfDay(for: $0.date) }.uniqued().sorted()
        guard let first = allDays.first, let last = allDays.last else { return 0 }
        var d = first
        var best = 0, cur = 0
        while d <= last {
            if isDayCompleted(d, cal: cal) {
                cur += 1
                best = max(best, cur)
            } else {
                cur = 0
            }
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        return best
    }
    
    // 기간 내 일자 배열 생성
    func days(in start: Date, _ end: Date, cal: Calendar = .current) -> [Date] {
        var d = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        var result: [Date] = []
        while d <= endDay {
            result.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        return result
    }
    
    // 특정 날짜의 완료 횟수(모든 약속 합계)
    func completedCount(on day: Date, cal: Calendar = .current) -> Int {
        let key = cal.startOfDay(for: day)
        return records.filter { $0.completed && cal.isDate($0.date, inSameDayAs: key) }.count
    }
    
    // 주간 달성률(주별 완료일수/총일수) – 단순 집계
    func weeklyRates(for type: PeriodType, cal: Calendar = .current) -> [(weekOfYear: Int, rate: Double)] {
        let (start, end) = periodDatesRolling(for: type)
        let allDays = days(in: start, end)
        let grouped = Dictionary(grouping: allDays) { cal.component(.weekOfYear, from: $0) }
        return grouped.keys.sorted().map { w in
            let daysOfWeek = grouped[w] ?? []
            let completedDays = daysOfWeek.filter { completedCount(on: $0) > 0 }.count
            let rate = daysOfWeek.isEmpty ? 0 : Double(completedDays) / Double(daysOfWeek.count)
            return (weekOfYear: w, rate: rate)
        }
    }
    
    func seedIfNeeded() {
        guard habits.isEmpty else { return }
        let h1 = Habit(title: "독서 10분",
                       durationMin: 10,
                       recurrence: .daily,
                       periodType: .monthly)
        let h2 = Habit(title: "스트레칭 3분",
                       durationMin: 3,
                       recurrence: .daysPerWeek(5),
                       periodType: .quarter)
        addHabit(h1)
        addHabit(h2)
    }
    
    func save() {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted]
            try enc.encode(habits).write(to: documentsURL(habitsFile), options: .atomic)
            try enc.encode(records).write(to: documentsURL(recordsFile), options: .atomic)
            try enc.encode(achievements).write(to: documentsURL("achievements.json"), options: .atomic)
            try enc.encode(notes).write(to: documentsURL("notes.json"), options: .atomic)

        } catch {
            print("Save error:", error)
        }
        
    }

    func load() {
        do {
            let dec = JSONDecoder()
            let hURL = documentsURL(habitsFile)
            let rURL = documentsURL(recordsFile)
            let aURL = documentsURL("achievements.json")
            let nURL = documentsURL("notes.json")
            if FileManager.default.fileExists(atPath: hURL.path) {
                habits = try dec.decode([Habit].self, from: Data(contentsOf: hURL))
            }
            if FileManager.default.fileExists(atPath: rURL.path) {
                records = try dec.decode([DayRecord].self, from: Data(contentsOf: rURL))
            }
            if FileManager.default.fileExists(atPath: aURL.path) {
                achievements = try dec.decode([Achievement].self, from: Data(contentsOf: aURL))
            }
            if FileManager.default.fileExists(atPath: nURL.path) {
                notes = try dec.decode([DayNote].self, from: Data(contentsOf: nURL))
            }
        } catch {
            print("Load error:", error)
        }
        updateTodaySummary()
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] { Array(Set(self)) }
}

// MARK: - Goals analytics helpers

extension DataStore {
    // 특정 습관에 한정해 완료 카운트 (nil이면 전체)
    func completedCount(on day: Date, for habit: Habit?) -> Int {
        let cal = Calendar.current
        let key = cal.startOfDay(for: day)
        if let habit {
            return records.filter { $0.habitId == habit.id && $0.completed && cal.isDate($0.date, inSameDayAs: key) }.count
        } else {
            return records.filter { $0.completed && cal.isDate($0.date, inSameDayAs: key) }.count
        }
    }

    // 주간 달성률 (선택 습관 기준)
    func weeklyRates(for type: PeriodType, habit: Habit? = nil, cal: Calendar = .current) -> [(weekOfYear: Int, rate: Double)] {
        let (start, end) = periodDatesRolling(for: type)
        let allDays = days(in: start, end)
        let grouped = Dictionary(grouping: allDays) { cal.component(.weekOfYear, from: $0) }
        return grouped.keys.sorted().map { w in
            let daysOfWeek = grouped[w] ?? []
            let completedDays = daysOfWeek.filter { completedCount(on: $0, for: habit) > 0 }.count
            let rate = daysOfWeek.isEmpty ? 0 : Double(completedDays) / Double(daysOfWeek.count)
            return (w, rate)
        }
    }

    // 해당 습관의 "주 목표 일수" 추출 (주간 목표선 용)
    func weeklyTargetDays(for habit: Habit?) -> Int {
        guard let habit else { return 7 } // 전체 보기면 최대 7
        switch habit.recurrence {
        case .daily: return 7
        case .daysPerWeek(let n): return max(1, min(7, n))
        case .custom(let days): return max(1, min(7, days.count))
        }
    }
}

extension DataStore {
    func isHabitCompleted(_ habit: Habit, on day: Date = .now) -> Bool { // ADD
        let cal = Calendar.current
        let key = cal.startOfDay(for: day)
        return records.contains { $0.habitId == habit.id && $0.completed && cal.isDate($0.date, inSameDayAs: key) }
    }

    func todayScheduledHabits(on day: Date = .now) -> [Habit] { // ADD
        let cal = Calendar.current
        return habits.filter { $0.isActive && $0.isScheduled(on: day, calendar: cal) }
    }

    func todayCounts(on day: Date = .now) -> (done: Int, total: Int) { // ADD
        let list = todayScheduledHabits(on: day)
        let done = list.filter { isHabitCompleted($0, on: day) }.count
        return (done, list.count)
    }

    func toggle(_ habit: Habit, on day: Date = .now) { // ADD: 홈에서 빠른 토글
        let cal = Calendar.current
        let key = cal.startOfDay(for: day)
        if let i = records.firstIndex(where: { $0.habitId == habit.id && cal.isDate($0.date, inSameDayAs: key) }) {
            records[i].completed.toggle()
        } else {
            records.append(.init(habitId: habit.id, date: key, completed: true, minutes: habit.durationMin))
        }
        checkAchievements()
    }
}


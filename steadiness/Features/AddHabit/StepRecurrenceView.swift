//
//  StepRecurrenceView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct StepRecurrenceView: View {
    @Binding var recurrence: Recurrence
    @Binding var selectedDays: Set<Weekday>  // ✅ 상위로 전달
    
    @State private var mode: Mode = .daily
//    @State private var selectedDays: Set<Weekday> = []
    @State private var quota: Int = 3 // daysPerWeek용 기본값

    enum Mode { case daily, three, five, custom }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                optionButton("매일", isOn: mode == .daily) { setMode(.daily) }
                optionButton("주 3회", isOn: mode == .three) { setMode(.three) }
                optionButton("주 5회", isOn: mode == .five) { setMode(.five) }
                optionButton("사용자 지정", isOn: mode == .custom) { setMode(.custom) }
            }
            .padding(.horizontal)

            // ✅ 칩: 주3/주5는 최대 선택 수를 제한
            WeekdayChips(selected: $selectedDays,
                         maxSelectable: mode == .three ? 3 : (mode == .five ? 5 : nil))

            Spacer()

            Text(helpText)
                .font(.footnote)
                .foregroundStyle(Color.textMid)
                .padding(.horizontal)
        }
        .onAppear { setMode(.daily) }
        .onChange(of: mode) { _ in syncRecurrence() }
        .onChange(of: selectedDays) { _ in syncRecurrence() }
        .navigationTitle("반복 주기")
    }

    private func optionButton(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isOn ? Color.peach : .white)
                .foregroundStyle(isOn ? .white : .black)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.peach))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var helpText: String {
        switch mode {
        case .daily:  return "매일 반복: 모든 요일이 자동 선택됩니다."
        case .three:  return "주 3회: 요일 칩 중 3개를 선택하세요."
        case .five:   return "주 5회: 요일 칩 중 5개를 선택하세요."
        case .custom: return "사용자 지정: 원하는 요일을 자유롭게 선택하세요."
        }
    }

    private func setMode(_ m: Mode) {
        mode = m
        switch m {
        case .daily:
            selectedDays = Set(Weekday.allCases)
        case .three, .five, .custom:
            selectedDays = []
        }
        syncRecurrence()
    }

    private func syncRecurrence() {
        switch mode {
        case .daily:
            recurrence = .daily
        case .three:
            recurrence = .daysPerWeek(3)
        case .five:
            recurrence = .daysPerWeek(5)
        case .custom:
            recurrence = .custom(selectedDays)
        }
    }
}

struct WeekdayChips: View {
    @Binding var selected: Set<Weekday>
    let maxSelectable: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases, id: \.self) { day in
                let isOn = selected.contains(day)
                Button {
                    toggle(day)
                } label: {
                    Text(day.symbol)
                        .frame(width: 40, height: 40)
                        .background(isOn ? Color.peach : .white)
                        .foregroundStyle(isOn ? .white : .black)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.peach))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .disabled(maxSelectable != nil && !isOn && selected.count >= (maxSelectable ?? .max))
            }
        }
        .padding(.top, 8)
    }

    private func toggle(_ day: Weekday) {
        if selected.contains(day) {
            selected.remove(day)
        } else {
            if let limit = maxSelectable {
                guard selected.count < limit else { return }
            }
            selected.insert(day)
        }
    }
}

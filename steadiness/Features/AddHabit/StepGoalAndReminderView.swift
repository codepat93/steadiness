//
//  StepPeriodView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct StepGoalAndReminderView: View {
    @Binding var periodType: PeriodType
    @Binding var reminderEnabled: Bool
    @Binding var reminderTime: Date
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("이 약속을 얼마나 이어가고 싶나요?").font(.headline)

            Picker("목표 단위", selection: $periodType) {
                Text("월간").tag(PeriodType.monthly)
                Text("분기").tag(PeriodType.quarter)
                Text("반기").tag(PeriodType.halfyear)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Form {
                Section(header: Text("알림")) {
                    Toggle("이 약속에 리마인더 사용", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("알림 시간", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    Text("선택한 요일에 위 시간으로 알림이 전송됩니다.")
                        .font(.footnote)
                        .foregroundStyle(Color.textMid)
                }
            }
            .frame(height: 200)

            Spacer()

            Button {
                onDone()
            } label: {
                Text("약속 저장하기")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.peach)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
        }
        .navigationTitle("목표 단위")
    }
}

//
//  HabitsDetailView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/15/25.
//

import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject var store: DataStore
    let habit: Habit

    var body: some View {
        List {
            Section {
                Text(habit.title)
                    .font(.title2.bold())
                HStack {
                    Text("ID")
                    Spacer()
                    Text(habit.id.uuidString).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section("오늘 상태") {
                let done = store.isHabitCompleted(habit)
                HStack {
                    Text(done ? "완료" : "미완료")
                    Spacer()
                    Button(done ? "취소" : "완료") {
                        store.toggle(habit)
                    }
                }
            }
        }
        .navigationTitle("약속 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//#Preview {
//    // 미리보기용 가짜 데이터
//    let habit = Habit(id: UUID(), title: "예시 약속" /* 나머지 필드는 네 모델에 맞춰 채워도 됨 */)
//    return HabitDetailView(habit: habit)
//        .environmentObject(DataStore())
//}

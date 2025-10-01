//
//  StepNameView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct StepNameView: View {
    @Binding var title: String
    @Binding var durationMin: Int

    var body: some View {
        Form {
            Section("약속 이름") {
                TextField("예: 아침 스트레칭 5분", text: $title)
            }
            Section("시간 (분)") {
                Stepper(value: $durationMin, in: 1...120, step: 1) {
                    Text("\(durationMin)분")
                }
            }
        }
    }
}

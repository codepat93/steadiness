//
//  SettingsView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("알림") {
                Toggle("리마인더 알림", isOn: .constant(true))
            }
            Section("정보") {
                Text("꾸준앱 v0.1.0")
            }
        }
    }
}

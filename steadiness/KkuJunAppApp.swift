//
//  KkuJunAppApp.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

@main
struct KkuJunAppApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onAppear {
                    store.load()       // ← 3번에서 만드는 로드
                    store.seedIfNeeded()
                    Noti.request()
//                    Noti.scheduleDaily20()
                }
                .environmentObject(store)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddFlow = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(showAddFlow: $showAddFlow)
            }
            .tabItem { Label("홈", systemImage: "house.fill") }

            NavigationStack {
                GoalsView()
                    .navigationTitle("목표")
            }
            .tabItem { Label("목표", systemImage: "target") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("설정")
            }
            .tabItem { Label("설정", systemImage: "gearshape.fill") }
        }
        .sheet(isPresented: $showAddFlow) {
            NavigationStack { AddHabitFlowView() }
                .presentationDetents([.large])
        }
    }
}

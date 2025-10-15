//
//  KkuJunAppApp.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI
import Combine

@main
struct KkuJunAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var store = DataStore()
    @StateObject var deepLinkCenter = DeepLinkCenter.shared

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
                .environmentObject(deepLinkCenter)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var deepLinkCenter: DeepLinkCenter
    
    @State private var selection = 0 // 0 홈, 1 목표, 2 설정
    @State private var showManage = false
    @State private var openHabitId: UUID?
    @State private var showAddFlow = false
    @State private var homePath = NavigationPath()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $homePath){
                HomeView(showAddFlow: $showAddFlow)
//                    .navigationTitle("오늘의 약속")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("약속 관리") { showManage = true }
                        }
                    }
                    .sheet(isPresented: $showManage) {
                        HabitManageView()
                            .environmentObject(store)
                    }
                    .onChange(of: openHabitId) { id in
                        // 필요하면 특정 약속 상세로 push하는 로직 배치
                    }
            }
            // 딥링크로 푸시될 대상 등록 (UUID로 푸시)
//            .navigationDestination(for: UUID.self) { id in
//                if let habit = store.habits.first(where: { $0.id == id }) {
//                    HabitDetailView(habit: habit)
//                } else {
//                    Text("해당 약속을 찾을 수 없어요.")
//                        .foregroundStyle(.secondary)
//                }
//            }
            .tabItem { Label("홈", systemImage: "house.fill") }
            .tag(0)

            NavigationStack { GoalsView().navigationTitle("목표") }
                .tabItem { Label("목표", systemImage: "target") }
                .tag(1)

            NavigationStack { SettingsView().navigationTitle("설정") }
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .onOpenURL { url in
            // 커스텀/웹 링크 모두 여기로 옴
            if let route = DeepLinkRouter.parse(url) {
                handle(route)
            }
        }
        .onChange(of: deepLinkCenter.url) { url in
            guard let url, let route = DeepLinkRouter.parse(url) else { return }
            handle(route)
            deepLinkCenter.url = nil // 한 번 처리 후 초기화
        }
    }

    private func handle(_ route: AppRoute) {
        switch route {
        case .home:
            selection = 0
        case .goals:
            selection = 1
        case .manage:
            selection = 0
            showManage = true
        case .habit(let id):
            selection = 0
            homePath = NavigationPath()    // (선택) 기존 스택 리셋
            homePath.append(id)
        }
    }
}


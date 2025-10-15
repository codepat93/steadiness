//
//  HabitManageView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/15/25.
//
import SwiftUI

struct HabitManageView: View {
    @EnvironmentObject var store: DataStore

    // UI 상태
    @State private var query: String = ""
    @State private var sort: Sort = .titleAsc
    @State private var editing: Habit? = nil   // 탭 시 수정 시트 표시

    enum Sort: String, CaseIterable, Identifiable {
        case titleAsc, createdDesc, activeFirst
        var id: String { rawValue }
        var label: String {
            switch self {
            case .titleAsc:    return "제목"
            case .createdDesc: return "최근 생성"
            case .activeFirst: return "활성 우선"
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            listView                  // ← 리스트만 별도 뷰로 분리
                .searchable(text: $query, prompt: "약속 검색")
                .navigationTitle("약속 관리")
                .toolbar { sortToolbar }  // ← 툴바도 분리
                .sheet(item: $editing) { habit in
                    HabitEditSheet(habit: habit) { updated in
                        store.updateHabit(updated)
                    }
                    .presentationDetents([.medium, .large])
                }
        }
    }

    // MARK: - Subviews

    /// 리스트 영역 (분리해서 타입 추론 단순화)
    @ViewBuilder
    private var listView: some View {
        List {
            ForEach(filteredAndSortedHabits, id: \.id) { habit in
                HabitRow(habit: habit)  // 간단한 행 뷰
                    .contentShape(Rectangle())
                    .onTapGesture { editing = habit } // 탭→수정
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.deleteHabit(habit)
                        } label: {
                            Label("삭제", systemImage: "trash.fill")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// 정렬 메뉴 (분리)
    @ToolbarContentBuilder
    private var sortToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("정렬", selection: $sort) {
                    ForEach(Sort.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
        }
    }

    // MARK: - Data helpers

    /// 검색 + 정렬 적용된 목록 (명시 타입으로 추론 부담 완화)
    private var filteredAndSortedHabits: [Habit] {
        var result: [Habit] = store.habits

        if !query.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        switch sort {
        case .titleAsc:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }

        case .createdDesc:
            // createdAt이 없으면 nil 병합 연산자로 안전 처리
            result.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }

        case .activeFirst:
            // isActive가 없으면 true로 가정하거나 해당 줄을 주석 처리
            result.sort {
                let lhsKey = ($0.isActive ? 0 : 1, $0.title)
                let rhsKey = ($1.isActive ? 0 : 1, $1.title)
                return lhsKey < rhsKey
            }
        }

        return result
    }
}

// MARK: - 간단한 행 뷰 (타입 추론 부담 줄이기용)
private struct HabitRow: View {
    let habit: Habit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title).font(.headline)
                HStack(spacing: 8) {
                    Text(habit.periodType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // isActive가 없으면 아래 배지를 제거하세요.
                    if !habit.isActive {
                        Text("비활성")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 편집 시트 (그대로 사용)
private struct HabitEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var habit: Habit
    let onSave: (Habit) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("기본 정보")) {
                    TextField("제목", text: $habit.title)
                    // isActive 없으면 토글 제거
                    Toggle("활성화", isOn: $habit.isActive)
                }
                Section(header: Text("기간/반복")) {
                    Picker("기간", selection: $habit.periodType) {
                        Text("월간").tag(PeriodType.monthly)
                        Text("분기").tag(PeriodType.quarter)
                        Text("반기").tag(PeriodType.halfyear)
                    }
                    // 반복/요일 선택 UI는 추후 추가
                }
            }
            .navigationTitle("약속 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(habit)
                        dismiss()
                    }
                    .disabled(habit.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

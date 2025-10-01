//
//  HeatmapView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct HeatmapView: View {
    let dates: [Date]             // 기간 내 모든 날짜
    let intensity: (Date) -> Int  // 0 = 미완료, 1+ = 완료 강도

    // 스타일 상수
    private let cell: CGSize = .init(width: 16, height: 16)
    private let vSpacing: CGFloat = 6
    private let hSpacing: CGFloat = 6
    private let corner: CGFloat = 3

    var body: some View {
        let weeks = groupByWeek(dates: dates) // [[Date]]
        GeometryReader { geo in
            // 전체 콘텐츠 너비 계산 = (주 개수 * 셀폭) + (주-1) * 간격
            let weeksCount = weeks.count
            let contentWidth = CGFloat(weeksCount) * cell.width + max(0, CGFloat(weeksCount - 1)) * hSpacing
            let extra = max(0, (geo.size.width - contentWidth) / 2) // 가운데 정렬용 좌/우 여백

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: hSpacing) {
                    ForEach(weeks.indices, id: \.self) { wi in
                        let week = weeks[wi]
                        VStack(spacing: vSpacing) {
                            ForEach(0..<7, id: \.self) { idx in
                                if let d = dayForWeek(week, weekdayIndex: idx) {
                                    let level = min(intensity(d), 4)
                                    Rectangle()
                                        .fill(color(for: level))
                                        .frame(width: cell.width, height: cell.height)
                                        .cornerRadius(corner)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: corner)
                                                .stroke(Color.gray.opacity(0.15))
                                        )
                                        .accessibilityLabel(Text("\(d.formatted(date: .abbreviated, time: .omitted)) \(level > 0 ? "완료" : "미완료")"))
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: cell.width, height: cell.height)
                                }
                            }
                        }
                    }
                }
                // 화면보다 좁으면 좌우 여백을 넣어 **가운데 정렬처럼 보이게**
                .padding(.horizontal, extra)
            }
        }
        .frame(height: 7 * cell.height + 6 * vSpacing + 12) // 적당한 고정 높이
    }

    // MARK: - Helpers

    private func groupByWeek(dates: [Date]) -> [[Date]] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: dates) { cal.component(.weekOfYear, from: $0) }
        // 주차 순서대로 + 각 주는 날짜 오름차순
        return grouped.keys.sorted().compactMap { grouped[$0]?.sorted() }
    }

    // 0=일 … 6=토 에 해당하는 날짜
    private func dayForWeek(_ week: [Date], weekdayIndex: Int) -> Date? {
        let cal = Calendar.current
        return week.first { cal.component(.weekday, from: $0) - 1 == weekdayIndex }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.peach.opacity(0.4)
        case 2: return Color.peach.opacity(0.6)
        case 3: return Color.peach.opacity(0.8)
        default: return Color.peach
        }
    }
}

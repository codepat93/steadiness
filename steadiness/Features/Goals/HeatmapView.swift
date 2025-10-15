//
//  HeatmapView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//
import SwiftUI

struct HeatmapView: View {
    let dates: [Date]                      // 표시할 날짜들 (롤링 범위)
    let intensity: (Date) -> Int           // 날짜별 강도 함수 (0 이상)
    let maxIntensity: Int                  // 스케일 최댓값 (0이면 자동 1)
    var onTap: ((Date) -> Void)? = nil     // 셀 탭 콜백(옵션)

    // 스타일
    private let cell: CGSize = .init(width: 16, height: 16)
    private let vSpacing: CGFloat = 6
    private let hSpacing: CGFloat = 6
    private let corner: CGFloat = 3

    var body: some View {
        let weeks = groupByWeek(dates: dates) // 과거→현재로 오른쪽으로 (GitHub 스타일)
        GeometryReader { geo in
            let weeksCount = weeks.count
            let contentWidth = CGFloat(weeksCount) * cell.width + max(0, CGFloat(weeksCount - 1)) * hSpacing
            let extra = max(0, (geo.size.width - contentWidth) / 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: hSpacing) {
                    ForEach(weeks.indices, id: \.self) { wi in
                        let week = weeks[wi]
                        VStack(spacing: vSpacing) {
                            ForEach(0..<7, id: \.self) { idx in
                                if let d = dayForWeek(week, weekdayIndex: idx) {
                                    let raw = intensity(d)
                                    let level = scaledLevel(raw, maxIntensity: maxIntensity)
                                    Rectangle()
                                        .fill(color(for: level))
                                        .frame(width: cell.width, height: cell.height)
                                        .cornerRadius(corner)
                                        .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.gray.opacity(0.12)))
                                        .contentShape(Rectangle())
                                        .onTapGesture { onTap?(d) }
                                        .accessibilityLabel(Text("\(d.formatted(date: .abbreviated, time: .omitted)) \(raw > 0 ? "완료" : "미완료")"))
                                } else {
                                    Rectangle().fill(Color.clear).frame(width: cell.width, height: cell.height)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, extra)
            }
        }
        .frame(height: 7 * cell.height + 6 * vSpacing + 12)
    }

    // 0..1로 정규화된 레벨을 0..4로 양자화
    private func scaledLevel(_ value: Int, maxIntensity: Int) -> Int {
        let maxI = max(1, maxIntensity) // 0 방지
        let ratio = Double(value) / Double(maxI)
        switch ratio {
        case 0: return 0
        case ..<0.25: return 1
        case ..<0.5: return 2
        case ..<0.75: return 3
        default: return 4
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.peach.opacity(0.35)
        case 2: return Color.peach.opacity(0.55)
        case 3: return Color.peach.opacity(0.75)
        default: return Color.peach
        }
    }

    private func groupByWeek(dates: [Date]) -> [[Date]] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: dates) { cal.component(.weekOfYear, from: $0) }
        return grouped.keys.sorted().compactMap { grouped[$0]?.sorted() }
    }

    private func dayForWeek(_ week: [Date], weekdayIndex: Int) -> Date? {
        let cal = Calendar.current
        return week.first { cal.component(.weekday, from: $0) - 1 == weekdayIndex }
    }
}

// 작은 범례 뷰
struct HeatmapLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("적음").font(.caption2).foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(i == 0 ? Color.gray.opacity(0.15) :
                          i == 1 ? Color.peach.opacity(0.35) :
                          i == 2 ? Color.peach.opacity(0.55) :
                          i == 3 ? Color.peach.opacity(0.75) :
                                   Color.peach)
                    .frame(width: 14, height: 14)
                    .cornerRadius(3)
            }
            Text("많음").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

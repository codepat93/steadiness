//
//  GoalsView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: DataStore
    @State private var period: PeriodType = .monthly

    var body: some View {
        let (start, end) = store.periodDatesRolling(for: period)
        let allDays = store.days(in: start, end)

        ScrollView {
            VStack(spacing: 16) {
                Picker("기간", selection: $period) {
                    Text("월간").tag(PeriodType.monthly)
                    Text("분기").tag(PeriodType.quarter)
                    Text("반기").tag(PeriodType.halfyear)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // ✅ 스트릭 카드
                HStack(spacing: 16) {
                    SummaryCard(title: "연속", value: "\(store.currentStreak())일")
                    SummaryCard(title: "최대", value: "\(store.maxStreak())일")
                }
                .padding(.horizontal)

                ProgressRing(progress: store.completionRate(for: period))
                    .frame(width: 160, height: 160)

                // 히트맵
                VStack(alignment: .center, spacing: 8) {
                    Text("히트맵").font(.subheadline).foregroundStyle(.secondary)
                    HeatmapView(
                        dates: allDays,
                        intensity: { d in store.completedCount(on: d) }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                // 주간 막대
                VStack(alignment: .leading, spacing: 8) {
                    Text("주간 달성률").font(.subheadline).foregroundStyle(.secondary)
                    WeeklyBarsView(items: store.weeklyRates(for: period))
                }
                .padding(.horizontal)

                // ✅ 배지 캐러셀
                VStack(alignment: .leading, spacing: 8) {
                    Text("배지").font(.subheadline).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(store.achievements) { a in
                                BadgeView(achievement: a)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
        }
        .background(Color.bgLight.ignoresSafeArea())
    }
}

struct ProgressRing: View {
    let progress: Double // 0.0 ~ 1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.peach, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.title3).bold()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2).bold()
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct BadgeView: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(achievement.earnedAt == nil ? Color.gray.opacity(0.15) : .peach)
                    .frame(width: 64, height: 64)
                Image(systemName: achievementIcon)
                    .foregroundStyle(achievement.earnedAt == nil ? .gray : .white)
            }
            Text(achievement.title)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .opacity(achievement.earnedAt == nil ? 0.6 : 1.0)
    }

    private var achievementIcon: String {
        switch achievement.threshold {
        case 3: return "sparkles"
        case 7: return "flame.fill"
        default: return "medal.fill"
        }
    }
}

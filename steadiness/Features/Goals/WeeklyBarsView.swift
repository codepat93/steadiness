//
//  WeeklyBarsView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct WeeklyBarsView: View {
    let items: [(weekOfYear: Int, rate: Double)] // 0.0~1.0
    let weeklyTargetDays: Int                    // 목표 일수(1~7)

    var body: some View {
        let targetRatio = Double(max(1, min(7, weeklyTargetDays))) / 7.0

        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .bottomLeading) {
                // 목표선
                GeometryReader { geo in
                    let height: CGFloat = 140
                    let y = height * (1 - targetRatio)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: height)
                        .overlay(
                            Rectangle()
                                .fill(Color.peach.opacity(0.25))
                                .frame(height: 2)
                                .offset(y: y - height)
                            , alignment: .bottom
                        )
                }
                .frame(height: 140)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(items, id: \.weekOfYear) { item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.peach)
                                .frame(width: 20, height: max(8, CGFloat(item.rate) * 140))
                                .overlay(
                                    Text("\(Int(item.rate * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .padding(.bottom, 2),
                                    alignment: .bottom
                                )
                            Text("W\(item.weekOfYear)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 160)
    }
}

//
//  WeeklyBarsView.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

struct WeeklyBarsView: View {
    let items: [(weekOfYear: Int, rate: Double)]  // ← 라벨명 맞춤

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(items, id: \.weekOfYear) { item in
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.peach)
                            .frame(width: 20, height: max(8, CGFloat(item.rate) * 120))
                        Text("W\(item.weekOfYear)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

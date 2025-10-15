//
//  Untitled.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

public extension Color {
    static let peach      = Color(hex: 0xF2B184)
    static let peachDark  = Color(hex: 0xE08E62)
    static let bgLight    = Color(hex: 0xF5F5F7)
    static let textDark   = Color(hex: 0x333333)
    static let textMid    = Color(hex: 0x666666)

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >>  8) & 0xFF) / 255.0,
                  blue:  Double( hex        & 0xFF) / 255.0,
                  opacity: alpha)
    }
}

//
//  DeepLinkCenter.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/15/25.
//

import Foundation
import Combine

final class DeepLinkCenter: ObservableObject {
    static let shared = DeepLinkCenter()
    @Published var url: URL? = nil
    private init() {}
}

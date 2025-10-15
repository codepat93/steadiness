//
//  DeepLinkRouter.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/15/25.
//

import Foundation

enum AppRoute: Equatable {
    case home
    case goals
    case manage
    case habit(UUID)
}

struct DeepLinkRouter {
    static func parse(_ url: URL) -> AppRoute? {
        // 1) 스킴/호스트 체크
        let isCustom = (url.scheme == "kkujun")
        let isWeb = (url.scheme == "https" && (url.host == "kkujune.app"))
        guard isCustom || isWeb else { return nil }

        // 2) path 세그먼트 파싱
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let comps = path.split(separator: "/").map(String.init)

        // kkujun://home, https://kkujune.app/home
        if comps.first == "home" { return .home }
        if comps.first == "goals" { return .goals }
        if comps.first == "manage" { return .manage }

        // habit/<uuid>
        if comps.first == "habit", comps.count >= 2, let id = UUID(uuidString: comps[1]) {
            return .habit(id)
        }
        return nil
    }
}

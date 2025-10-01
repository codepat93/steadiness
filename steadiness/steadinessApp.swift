//
//  steadinessApp.swift
//  steadiness
//
//  Created by Donggeun Lee on 10/1/25.
//

import SwiftUI

@main
struct steadinessApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

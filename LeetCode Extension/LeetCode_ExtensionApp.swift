//
//  LeetCode_ExtensionApp.swift
//  LeetCode Extension
//
//  Created by Tyler Sahagun on 1/30/25.
//

import SwiftUI
import SwiftData

@main
struct LeetCode_ExtensionApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

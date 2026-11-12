//
//  EarthOnlineGuideApp.swift
//  EarthOnlineGuide
//
//  Created by cczij on 2026/8/24.
//

import SwiftUI
import SwiftData

@main
struct EarthOnlineGuideApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [modelConfiguration])
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

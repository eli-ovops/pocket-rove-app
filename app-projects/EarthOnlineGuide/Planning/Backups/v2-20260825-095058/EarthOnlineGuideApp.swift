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
        let schema = Schema(EarthOnlineSchemaV1.models)
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

//
//  ContentView.swift
//  EarthOnlineGuide
//
//  Created by cczij on 2026/8/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [LocalProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                AppShell(profile: profile, modelContext: modelContext)
            } else {
                OnboardingView(modelContext: modelContext)
            }
        }
    }
}

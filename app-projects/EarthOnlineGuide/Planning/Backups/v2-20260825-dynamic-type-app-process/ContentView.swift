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
    @State private var taskPackError: String?
    @State private var isPreparingTaskPack = true

    var body: some View {
        Group {
            if let taskPackError {
                ContentUnavailableView {
                    Label("任务包暂时无法准备", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("应用没有删除、替换或重建任何本机数据。请保留现场后再处理。")
                } actions: {
                    Text(taskPackError)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                .padding()
            } else if isPreparingTaskPack {
                ProgressView("正在准备本地任务包")
                    .accessibilityLabel("正在准备本地任务包")
            } else if let profile = profiles.first {
                AppShell(profile: profile, modelContext: modelContext)
            } else {
                OnboardingView(modelContext: modelContext)
            }
        }
        .task {
            defer { isPreparingTaskPack = false }
            do {
                try ProductionTaskPackBootstrap.ensure(in: modelContext)
            } catch {
                taskPackError = error.localizedDescription
            }
        }
        .transaction { transaction in
            if UITestConfiguration.runID(environment: ProcessInfo.processInfo.environment, arguments: ProcessInfo.processInfo.arguments) != nil {
                transaction.disablesAnimations = true
            }
        }
    }
}

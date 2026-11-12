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

#if DEBUG
struct DynamicTypeVerificationRoot: View {
    let configuration: DynamicTypeVerificationConfiguration
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [LocalProfile]
    @State private var preparationError: String?

    var body: some View {
        Group {
            if configuration.route == .onboarding {
                OnboardingView(modelContext: modelContext)
            } else if let preparationError {
                ContentUnavailableView("验证 fixture 无法准备", systemImage: "exclamationmark.triangle", description: Text(preparationError))
            } else if let profile = profiles.first {
                switch configuration.route {
                case .onboarding:
                    EmptyView()
                case .today:
                    TodayView(profile: profile, modelContext: modelContext)
                case .history:
                    HistoryView(profile: profile)
                case .settings:
                    SettingsView(profile: profile, modelContext: modelContext)
                }
            } else {
                ProgressView("正在准备大字号验证页面")
            }
        }
        .dynamicTypeSize(.accessibility3)
        .overlay {
            DynamicTypeEvidenceProbe(route: configuration.route)
                .allowsHitTesting(false)
        }
        .task { prepareFixtureIfNeeded() }
    }

    private func prepareFixtureIfNeeded() {
        guard configuration.route != .onboarding, profiles.isEmpty else { return }
        do {
            try ProductionTaskPackBootstrap.ensure(in: modelContext)
            let profile = LocalProfile(guideID: "大字号验证向导")
            modelContext.insert(profile)
            try modelContext.save()
            if configuration.route == .history,
               let plan = try DailyTaskService(context: modelContext, profile: profile).today(),
               let instance = plan.instances.first {
                try DailyTaskService(context: modelContext, profile: profile).markCompleted(instance)
            }
        } catch {
            preparationError = error.localizedDescription
        }
    }
}

private struct DynamicTypeEvidenceProbe: View {
    let route: DynamicTypeVerificationRoute
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
            .onAppear(perform: writeEvidence)
            .onChange(of: dynamicTypeSize) { _, _ in writeEvidence() }
    }

    private func writeEvidence() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("EarthOnlineGuideDynamicTypeVerification", isDirectory: true)
        let url = directory.appendingPathComponent("\(route.rawValue)-accessibility3.txt")
        let observed = String(describing: dynamicTypeSize)
        let body = "route=\(route.rawValue)\nexpected=accessibility3\nobserved=\(observed)\nmatch=\(observed == "accessibility3")\n"
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try body.write(to: url, atomically: true, encoding: .utf8)
            print("EARTH_GUIDE_DYNAMIC_TYPE_PROBE route=\(route.rawValue) observed=\(observed) file=\(url.path)")
        } catch {
            print("EARTH_GUIDE_DYNAMIC_TYPE_PROBE_WRITE_FAILED route=\(route.rawValue) error=\(error.localizedDescription)")
        }
    }
}
#endif

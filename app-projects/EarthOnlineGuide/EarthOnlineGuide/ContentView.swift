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
                if let profile = profiles.first {
                    _ = try DailyTaskService(context: modelContext, profile: profile).reconcile()
                }
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
    let configuration: VisualVerificationConfiguration
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
                AppShell(profile: profile, modelContext: modelContext, initialTab: tab)
            } else {
                ProgressView("正在准备验证页面")
            }
        }
        .overlay {
            DynamicTypeEvidenceProbe(configuration: configuration)
                .allowsHitTesting(false)
        }
        .dynamicTypeSize(configuration.requestedDynamicType)
        .task { prepareFixtureIfNeeded() }
    }

    private var tab: AppTab {
        switch configuration.route {
        case .onboarding: .today
        case .today: .today
        case .history: .history
        case .settings: .settings
        }
    }

    private func prepareFixtureIfNeeded() {
        guard configuration.route != .onboarding, profiles.isEmpty else { return }
        do {
            let profile = LocalProfile(guideID: "视觉验证向导", languageCode: "zh-Hans")
            modelContext.insert(profile)
            if configuration.route == .today || configuration.route == .history {
                let fixtureTimestamp = Date(timeIntervalSince1970: 1_787_637_600)
                let plan = DailyPlan(key: "2026-08-25", sequence: 9367, zone: "UTC", startAtUTC: .distantPast, refreshAtUTC: .distantFuture, installID: profile.installID, version: "visual-fixture-v1", seed: "visual-fixture", profile: nil)
                plan.expectedCoreCount = 1
                plan.expectedEggCount = 1
                modelContext.insert(plan)
                plan.profile = profile
                let core = DailyInstance(card: TaskCard(id: "visual-core", family: "action", zh: "完成一件拖延很久的事", en: "Finish something you have delayed"), plan: plan)
                let egg = DailyInstance(card: TaskCard(id: "visual-egg", type: "egg", family: "easter-egg", zh: "找到一个紫色的东西", en: "Find something purple"), plan: plan)
                plan.instances = [core, egg]
                if configuration.route == .history {
                    let coreCompletion = Completion(instance: core, at: fixtureTimestamp)
                    let eggCompletion = Completion(instance: egg, at: fixtureTimestamp.addingTimeInterval(60))
                    modelContext.insert(coreCompletion)
                    modelContext.insert(eggCompletion)
                    core.completion = coreCompletion
                    egg.completion = eggCompletion
                }
            }
            try modelContext.save()
        } catch {
            preparationError = error.localizedDescription
        }
    }
}

private struct DynamicTypeEvidenceProbe: View {
    let configuration: VisualVerificationConfiguration
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Text(String(describing: dynamicTypeSize))
            .foregroundStyle(.clear)
            .frame(width: 1, height: 1)
            .accessibilityIdentifier("ui-test-dynamic-type")
            .accessibilityLabel(String(describing: dynamicTypeSize))
            .accessibilityValue(String(describing: dynamicTypeSize))
            .accessibilityHint("DEBUG dynamic type verification probe")
            .onAppear(perform: writeEvidence)
            .onChange(of: dynamicTypeSize) { _, _ in writeEvidence() }
    }

    private func writeEvidence() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("EarthOnlineGuideDynamicTypeVerification", isDirectory: true)
        let url = directory.appendingPathComponent("\(configuration.route.rawValue)-\(configuration.expectedDynamicType).txt")
        let observed = String(describing: dynamicTypeSize)
        let body = "route=\(configuration.route.rawValue)\nexpected=\(configuration.expectedDynamicType)\nobserved=\(observed)\nmatch=\(observed == configuration.expectedDynamicType)\n"
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try body.write(to: url, atomically: true, encoding: .utf8)
            print("EARTH_GUIDE_DYNAMIC_TYPE_PROBE route=\(configuration.route.rawValue) expected=\(configuration.expectedDynamicType) observed=\(observed) file=\(url.path)")
        } catch {
            print("EARTH_GUIDE_DYNAMIC_TYPE_PROBE_WRITE_FAILED route=\(configuration.route.rawValue) error=\(error.localizedDescription)")
        }
    }
}
#endif

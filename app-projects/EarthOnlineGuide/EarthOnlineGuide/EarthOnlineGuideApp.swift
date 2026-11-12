//
//  EarthOnlineGuideApp.swift
//  EarthOnlineGuide
//
//  Created by cczij on 2026/8/24.
//

import Foundation
import SwiftUI
import SwiftData

enum AppContainerStorageMode: Equatable {
    case persistent
    case hostedTest
    case uiTest(runID: String)
#if DEBUG
    case unitTestInMemory
    case verification
#endif
}

#if DEBUG
enum DynamicTypeVerificationRoute: String, CaseIterable {
    case onboarding
    case today
    case history
    case settings
}

struct VisualVerificationConfiguration: Equatable {
    let route: DynamicTypeVerificationRoute
    let requestedDynamicType: DynamicTypeSize
    let expectedDynamicType: String

    static func current(environment: [String: String] = ProcessInfo.processInfo.environment, arguments: [String] = ProcessInfo.processInfo.arguments) -> Self? {
        guard let routeFlag = arguments.firstIndex(of: "-EarthGuideDebugRoute"),
              arguments.indices.contains(routeFlag + 1),
              let route = DynamicTypeVerificationRoute(rawValue: arguments[routeFlag + 1]) else {
            return nil
        }
        if environment["EARTH_GUIDE_DYNAMIC_TYPE_VERIFY"] == "1" {
            return Self(route: route, requestedDynamicType: .accessibility3, expectedDynamicType: "accessibility3")
        }
        if environment["EARTH_GUIDE_VISUAL_VERIFY"] == "1" {
            return Self(route: route, requestedDynamicType: .large, expectedDynamicType: "large")
        }
        return nil
    }
}
#endif

enum UITestConfiguration {
    static let fixedInstallID = "ui-fixed-install-v1"
    static let fixedNow = Date(timeIntervalSince1970: 1_787_637_600)
    static let fixedTimeZone = TimeZone(secondsFromGMT: 0)!
    static var fixedCalendar: Calendar { var calendar = Calendar(identifier: .gregorian); calendar.timeZone = fixedTimeZone; return calendar }
    static var testRootURL: URL { FileManager.default.temporaryDirectory.appendingPathComponent("EarthOnlineGuideUITestStores", isDirectory: true) }

    static func runID(environment: [String: String], arguments: [String]) -> String? {
        guard environment["UI_TESTING"] == "1" || arguments.contains("-UI_TESTING") else { return nil }
        guard let runID = environment["EARTH_GUIDE_UI_TEST_RUN_ID"], !runID.isEmpty else { return nil }
        let allowed = runID.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        guard runID == allowed else { return nil }
        return runID
    }

    static func storeURL(runID: String) -> URL {
        testRootURL.appendingPathComponent(runID, isDirectory: true).appendingPathComponent("earth.sqlite")
    }

    static func isTestStore(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(testRootURL.standardizedFileURL.path + "/")
    }

    static func resetIfRequested(environment: [String: String], arguments: [String]) throws {
        guard environment["UI_TEST_RESET"] == "1", let runID = runID(environment: environment, arguments: arguments) else { return }
        let url = storeURL(runID: runID)
        guard isTestStore(url), url.lastPathComponent == "earth.sqlite" else { throw UITestStoreError.invalidStorePath }
        let directory = url.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }

}

enum UITestStoreError: Error { case invalidStorePath }

struct UITestFixedClock: BusinessDayClock { let now: Date }

struct AppContainerBootstrap {
    struct Result {
        let container: ModelContainer?
        let storageMode: AppContainerStorageMode
        let recoveryErrorDescription: String?
    }

    static func storageMode(environment: [String: String], arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainerStorageMode {
#if DEBUG
        if environment["EARTH_GUIDE_UNIT_TEST_IN_MEMORY"] == "1", environment["XCTestBundlePath"] != nil { return .unitTestInMemory }
        if VisualVerificationConfiguration.current(environment: environment, arguments: arguments) != nil { return .verification }
#endif
        if let runID = UITestConfiguration.runID(environment: environment, arguments: arguments) { return .uiTest(runID: runID) }
        return environment["XCTestBundlePath"] == nil ? .persistent : .hostedTest
    }

    static func make(environment: [String: String] = ProcessInfo.processInfo.environment) -> Result {
        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let mode = storageMode(environment: environment)

        do {
            try UITestConfiguration.resetIfRequested(environment: environment, arguments: ProcessInfo.processInfo.arguments)
            let configuration: ModelConfiguration
            switch mode {
            case .persistent: configuration = ModelConfiguration(schema: schema)
            case .hostedTest: configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            case let .uiTest(runID): configuration = ModelConfiguration(schema: schema, url: UITestConfiguration.storeURL(runID: runID))
#if DEBUG
            case .unitTestInMemory: configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            case .verification: configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
#endif
            }
            let container: ModelContainer
            if mode == .hostedTest || mode == .unitTestInMemory {
                container = try ModelContainer(for: schema, configurations: [configuration])
            } else {
                container = try ModelContainer(for: schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [configuration])
            }
            return Result(container: container, storageMode: mode, recoveryErrorDescription: nil)
        } catch {
            return Result(container: nil, storageMode: mode, recoveryErrorDescription: String(describing: error))
        }
    }
}

@main
struct EarthOnlineGuideApp: App {
    private let bootstrap = AppContainerBootstrap.make()

    var body: some Scene {
        WindowGroup {
            if let container = bootstrap.container {
#if DEBUG
                if let configuration = VisualVerificationConfiguration.current() {
                    DynamicTypeVerificationRoot(configuration: configuration)
                        .modelContainer(container)
                } else {
                    ContentView()
                        .modelContainer(container)
                }
#else
                ContentView()
                    .modelContainer(container)
#endif
            } else {
                StorageRecoveryView(errorDescription: bootstrap.recoveryErrorDescription ?? "Unknown SwiftData container error")
            }
        }
    }
}

private struct StorageRecoveryView: View {
    let errorDescription: String

    var body: some View {
        ContentUnavailableView {
            Label("本机数据暂时无法打开", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("应用没有清除、替换或重建你的本机数据。请保留现场并联系支持后再决定恢复操作。")
        } actions: {
            Text(errorDescription)
                .font(.caption)
                .textSelection(.enabled)
                .accessibilityLabel("存储错误详情：\(errorDescription)")
        }
        .padding()
    }
}

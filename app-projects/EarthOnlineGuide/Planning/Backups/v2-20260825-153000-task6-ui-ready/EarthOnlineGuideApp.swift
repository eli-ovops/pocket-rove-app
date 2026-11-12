//
//  EarthOnlineGuideApp.swift
//  EarthOnlineGuide
//
//  Created by cczij on 2026/8/24.
//

import SwiftUI
import SwiftData

enum AppContainerStorageMode: Equatable {
    case persistent
    case hostedTest
    case uiTest(runID: String)
}

enum UITestConfiguration {
    static func runID(environment: [String: String], arguments: [String]) -> String? {
        guard environment["UI_TESTING"] == "1" || arguments.contains("-UI_TESTING") else { return nil }
        guard let runID = environment["EARTH_GUIDE_UI_TEST_RUN_ID"], !runID.isEmpty else { return nil }
        return runID.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    static func storeURL(runID: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("EarthOnlineGuide-UI-\(runID).sqlite")
    }
}

struct AppContainerBootstrap {
    struct Result {
        let container: ModelContainer?
        let storageMode: AppContainerStorageMode
        let recoveryErrorDescription: String?
    }

    static func storageMode(environment: [String: String], arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainerStorageMode {
        if let runID = UITestConfiguration.runID(environment: environment, arguments: arguments) { return .uiTest(runID: runID) }
        return environment["XCTestBundlePath"] == nil ? .persistent : .hostedTest
    }

    static func make(environment: [String: String] = ProcessInfo.processInfo.environment) -> Result {
        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let mode = storageMode(environment: environment)

        do {
            let configuration: ModelConfiguration
            switch mode {
            case .persistent: configuration = ModelConfiguration(schema: schema)
            case .hostedTest: configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            case let .uiTest(runID): configuration = ModelConfiguration(schema: schema, url: UITestConfiguration.storeURL(runID: runID))
            }
            let container: ModelContainer
            if mode == .hostedTest {
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
                ContentView()
                    .modelContainer(container)
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

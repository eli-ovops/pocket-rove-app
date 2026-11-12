import Foundation
import SwiftData

// V1 retains the exact persisted shape used by the first test build.
enum EarthOnlineSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [LocalProfile.self, TaskPack.self, TaskCard.self, DailyPlan.self, DailyInstance.self, Completion.self, NotificationSchedule.self, ContentAsset.self, EngineState.self] }
    @Model final class LocalProfile { @Attribute(.unique) var installID: String; var guideID: String; var languageCode: String; var musicEnabled: Bool; var soundEffectsEnabled: Bool; @Relationship(deleteRule: .cascade, inverse: \DailyPlan.profile) var dailyPlans: [DailyPlan]; init(installID: String, guideID: String) { self.installID = installID; self.guideID = guideID; languageCode = "zh-Hans"; musicEnabled = false; soundEffectsEnabled = false; dailyPlans = [] } }
    @Model final class TaskPack { @Attribute(.unique) var version: String; var isDevelopmentOnly: Bool; @Relationship(deleteRule: .cascade, inverse: \TaskCard.pack) var cards: [TaskCard]; init(version: String, isDevelopmentOnly: Bool) { self.version = version; self.isDevelopmentOnly = isDevelopmentOnly; cards = [] } }
    @Model final class TaskCard { @Attribute(.unique) var revisionID: String; var canonicalTaskID: String; var type: String; var experienceFamilyKey: String; var titleZh: String; var titleEn: String; var contentStatus: String; var safetyStatus: String; var localizationStatus: String; var licenseStatus: String; var pack: TaskPack?; init(id: String, type: String = "core", family: String, zh: String, en: String) { revisionID = "debug-\(id)-v1"; canonicalTaskID = id; self.type = type; experienceFamilyKey = family; titleZh = zh; titleEn = en; contentStatus = "approved"; safetyStatus = "approved"; localizationStatus = "development"; licenseStatus = "verified" } }
    @Model final class DailyPlan { @Attribute(.unique) var businessDayKey: String; var timeZoneIdentifier: String; var taskPackVersion: String; var algorithmVersion: String; var seed: String; var createdAt: Date; var profile: LocalProfile?; @Relationship(deleteRule: .cascade, inverse: \DailyInstance.plan) var instances: [DailyInstance]; init(key: String, zone: String, version: String, seed: String, profile: LocalProfile?) { businessDayKey = key; timeZoneIdentifier = zone; taskPackVersion = version; algorithmVersion = "v1"; self.seed = seed; createdAt = .now; self.profile = profile; instances = [] } }
    @Model final class DailyInstance { @Attribute(.unique) var instanceID: String; var canonicalTaskID: String; var type: String; var snapshotZh: String; var snapshotEn: String; var iconKey: String; var plan: DailyPlan?; @Relationship(deleteRule: .cascade, inverse: \Completion.instance) var completion: Completion?; init(card: TaskCard, plan: DailyPlan) { instanceID = "\(plan.businessDayKey)-\(card.canonicalTaskID)"; canonicalTaskID = card.canonicalTaskID; type = card.type; snapshotZh = card.titleZh; snapshotEn = card.titleEn; iconKey = card.experienceFamilyKey; self.plan = plan } }
    @Model final class Completion { @Attribute(.unique) var completionID: String; var completedAt: Date; var revokedAt: Date?; var instance: DailyInstance?; init(instance: DailyInstance, at: Date = .now) { completionID = "\(instance.instanceID)-completion"; completedAt = at; self.instance = instance } }
    @Model final class NotificationSchedule { @Attribute(.unique) var identifier: String; var hour: Int; var minute: Int; init(identifier: String, hour: Int, minute: Int) { self.identifier = identifier; self.hour = hour; self.minute = minute } }
    @Model final class ContentAsset { @Attribute(.unique) var assetKey: String; var licenseStatus: String; init(assetKey: String, licenseStatus: String = "verified") { self.assetKey = assetKey; self.licenseStatus = licenseStatus } }
    @Model final class EngineState { @Attribute(.unique) var stateKey: String; var lastBusinessDayKey: String; init(lastBusinessDayKey: String = "") { stateKey = "engine"; self.lastBusinessDayKey = lastBusinessDayKey } }
}

enum EarthOnlineSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [LocalProfile.self, TaskPack.self, TaskCard.self, DailyPlan.self, DailyInstance.self, Completion.self, NotificationSchedule.self, ContentAsset.self, EngineState.self] }
    @Model final class LocalProfile { @Attribute(.unique) var installID: String; var guideID: String; var languageCode: String; var musicEnabled: Bool; var soundEffectsEnabled: Bool; @Relationship(deleteRule: .cascade, inverse: \DailyPlan.profile) var dailyPlans: [DailyPlan]; init(guideID: String, languageCode: String = "zh-Hans") { installID = UUID().uuidString; self.guideID = guideID; self.languageCode = languageCode; musicEnabled = false; soundEffectsEnabled = false; dailyPlans = [] } }
    @Model final class TaskPack { @Attribute(.unique) var version: String; var isDevelopmentOnly: Bool; @Relationship(deleteRule: .cascade, inverse: \TaskCard.pack) var cards: [TaskCard]; init(version: String, isDevelopmentOnly: Bool, cards: [TaskCard] = []) { self.version = version; self.isDevelopmentOnly = isDevelopmentOnly; self.cards = cards } }
    @Model final class TaskCard { @Attribute(.unique) var revisionID: String; var canonicalTaskID: String; var type: String; var experienceFamilyKey: String; var titleZh: String; var titleEn: String; var contentStatus: String; var safetyStatus: String; var localizationStatus: String; var licenseStatus: String; var pack: TaskPack?; init(id: String, type: String = "core", family: String, zh: String, en: String) { revisionID = "debug-\(id)-v1"; canonicalTaskID = id; self.type = type; experienceFamilyKey = family; titleZh = zh; titleEn = en; contentStatus = "approved"; safetyStatus = "approved"; localizationStatus = "development"; licenseStatus = "verified" } }
    @Model final class DailyPlan { @Attribute(.unique) var planKey: String = Foundation.UUID().uuidString; var installID: String = ""; var businessDaySequence: Int = 0; var businessDayKey: String = ""; var timeZoneIdentifier: String = ""; var startAtUTC: Date = Foundation.Date.distantPast; var refreshAtUTC: Date = Foundation.Date.distantPast; var taskPackVersion: String = ""; var algorithmVersion: String = "v2"; var lifecycleState: String = "generating"; var expectedCoreCount: Int = 3; var expectedEggCount: Int = 0; var seed: String = ""; var createdAt: Date = Foundation.Date.now; var profile: LocalProfile?; @Relationship(deleteRule: .cascade, inverse: \DailyInstance.plan) var instances: [DailyInstance]; init(key: String, sequence: Int, zone: String, startAtUTC: Date, refreshAtUTC: Date, installID: String, version: String, seed: String, profile: LocalProfile?) { businessDayKey = key; businessDaySequence = sequence; self.installID = installID; planKey = "\(installID)|\(sequence)"; timeZoneIdentifier = zone; self.startAtUTC = startAtUTC; self.refreshAtUTC = refreshAtUTC; taskPackVersion = version; self.seed = seed; lifecycleState = "active"; self.profile = profile; instances = [] } }
    @Model final class DailyInstance { @Attribute(.unique) var instanceID: String; var canonicalTaskID: String; var type: String; var snapshotZh: String; var snapshotEn: String; var iconKey: String; var plan: DailyPlan?; @Relationship(deleteRule: .cascade, inverse: \Completion.instance) var completion: Completion?; init(card: TaskCard, plan: DailyPlan) { instanceID = "\(plan.planKey)-\(card.canonicalTaskID)"; canonicalTaskID = card.canonicalTaskID; type = card.type; snapshotZh = card.titleZh; snapshotEn = card.titleEn; iconKey = card.experienceFamilyKey; self.plan = plan } }
    @Model final class Completion { @Attribute(.unique) var completionID: String; var completedAt: Date; var revokedAt: Date?; var updatedAtUTC: Date = Foundation.Date.distantPast; var lastMutationID: String = "migration-pending"; var instance: DailyInstance?; init(instance: DailyInstance, at: Date = .now) { completionID = "\(instance.instanceID)-completion"; completedAt = at; updatedAtUTC = at; lastMutationID = UUID().uuidString; self.instance = instance } }
    @Model final class NotificationSchedule { @Attribute(.unique) var identifier: String; var hour: Int; var minute: Int; init(identifier: String, hour: Int, minute: Int) { self.identifier = identifier; self.hour = hour; self.minute = minute } }
    @Model final class ContentAsset { @Attribute(.unique) var assetKey: String; var licenseStatus: String; init(assetKey: String, licenseStatus: String = "verified") { self.assetKey = assetKey; self.licenseStatus = licenseStatus } }
    @Model final class EngineState { @Attribute(.unique) var stateKey: String; var lastBusinessDayKey: String; init(lastBusinessDayKey: String = "") { stateKey = "engine"; self.lastBusinessDayKey = lastBusinessDayKey } }
}

nonisolated struct LegacyV1MigrationResolution: Equatable {
    let sequence: Int
    let timeZoneIdentifier: String
    let startAtUTC: Date
    let refreshAtUTC: Date
    let algorithmVersion: String
    let usedSafetyRecovery: Bool
}

nonisolated enum LegacyV1Migration {
    private static let recoveryAlgorithmVersion = "v2-legacy-recovered-unparseable-business-day"
    private static let migratedAlgorithmVersion = "v2-migrated-v1"

    static func resolve(businessDayKey: String, timeZoneIdentifier: String) -> LegacyV1MigrationResolution {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier), let dayStart = localDayStart(key: businessDayKey, timeZone: timeZone) else {
            return safetyRecovery()
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        let reference = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1))!
        let sequence = calendar.dateComponents([.day], from: reference, to: dayStart).day!
        let refresh = calendar.date(byAdding: .hour, value: 5, to: dayStart)!
        return LegacyV1MigrationResolution(sequence: sequence, timeZoneIdentifier: timeZone.identifier, startAtUTC: dayStart, refreshAtUTC: refresh, algorithmVersion: migratedAlgorithmVersion, usedSafetyRecovery: false)
    }

    private static func localDayStart(key: String, timeZone: TimeZone) -> Date? {
        let fields = key.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 3, let year = Int(fields[0]), let month = Int(fields[1]), let day = Int(fields[2]) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else { return nil }
        return date
    }

    private static func safetyRecovery() -> LegacyV1MigrationResolution {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        let start = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1))!
        let refresh = calendar.date(byAdding: .hour, value: 5, to: start)!
        return LegacyV1MigrationResolution(sequence: 0, timeZoneIdentifier: timeZone.identifier, startAtUTC: start, refreshAtUTC: refresh, algorithmVersion: recoveryAlgorithmVersion, usedSafetyRecovery: true)
    }
}

enum EarthOnlineMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [EarthOnlineSchemaV1.self, EarthOnlineSchemaV2.self] }
    static var stages: [MigrationStage] { [.custom(fromVersion: EarthOnlineSchemaV1.self, toVersion: EarthOnlineSchemaV2.self, willMigrate: nil, didMigrate: { context in
        for plan in try context.fetch(FetchDescriptor<EarthOnlineSchemaV2.DailyPlan>()) {
            let resolvedDay = LegacyV1Migration.resolve(businessDayKey: plan.businessDayKey, timeZoneIdentifier: plan.timeZoneIdentifier)
            plan.businessDaySequence = resolvedDay.sequence
            plan.timeZoneIdentifier = resolvedDay.timeZoneIdentifier
            plan.startAtUTC = resolvedDay.startAtUTC
            plan.refreshAtUTC = resolvedDay.refreshAtUTC
            plan.algorithmVersion = resolvedDay.algorithmVersion
            plan.installID = plan.profile?.installID ?? plan.installID
            plan.planKey = "\(plan.installID)|\(plan.businessDaySequence)"
            plan.lifecycleState = plan.instances.count >= plan.expectedCoreCount ? "active" : "failed"
        }
        for item in try context.fetch(FetchDescriptor<EarthOnlineSchemaV2.DailyInstance>()) {
            if let completion = item.completion {
                completion.updatedAtUTC = max(completion.completedAt, completion.revokedAt ?? completion.completedAt)
                completion.lastMutationID = "migrated-v1|\(completion.completionID)"
            }
        }
        try context.save()
    })] }
}

typealias LocalProfile = EarthOnlineSchemaV2.LocalProfile
typealias TaskPack = EarthOnlineSchemaV2.TaskPack
typealias TaskCard = EarthOnlineSchemaV2.TaskCard
typealias DailyPlan = EarthOnlineSchemaV2.DailyPlan
typealias DailyInstance = EarthOnlineSchemaV2.DailyInstance
typealias Completion = EarthOnlineSchemaV2.Completion
typealias NotificationSchedule = EarthOnlineSchemaV2.NotificationSchedule
typealias ContentAsset = EarthOnlineSchemaV2.ContentAsset
typealias EngineState = EarthOnlineSchemaV2.EngineState

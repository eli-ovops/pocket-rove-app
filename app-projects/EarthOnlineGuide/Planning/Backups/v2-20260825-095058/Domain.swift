import Foundation
import SwiftData

enum EarthOnlineSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [LocalProfile.self, TaskPack.self, TaskCard.self, DailyPlan.self,
         DailyInstance.self, Completion.self, NotificationSchedule.self,
         ContentAsset.self, EngineState.self]
    }
}

enum EarthOnlineMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [EarthOnlineSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

@Model final class LocalProfile {
    @Attribute(.unique) var installID: String
    var guideID: String
    var languageCode: String
    var musicEnabled: Bool
    var soundEffectsEnabled: Bool
    @Relationship(deleteRule: .cascade, inverse: \DailyPlan.profile) var dailyPlans: [DailyPlan]
    init(guideID: String, languageCode: String = "zh-Hans") {
        installID = UUID().uuidString; self.guideID = guideID; self.languageCode = languageCode
        musicEnabled = false; soundEffectsEnabled = false; dailyPlans = []
    }
}

@Model final class TaskPack {
    @Attribute(.unique) var version: String
    var isDevelopmentOnly: Bool
    @Relationship(deleteRule: .cascade, inverse: \TaskCard.pack) var cards: [TaskCard]
    init(version: String, isDevelopmentOnly: Bool, cards: [TaskCard] = []) { self.version = version; self.isDevelopmentOnly = isDevelopmentOnly; self.cards = cards }
}

@Model final class TaskCard {
    @Attribute(.unique) var revisionID: String
    var canonicalTaskID: String; var type: String; var experienceFamilyKey: String
    var titleZh: String; var titleEn: String
    var contentStatus: String; var safetyStatus: String; var localizationStatus: String; var licenseStatus: String
    var pack: TaskPack?
    init(id: String, type: String = "core", family: String, zh: String, en: String) {
        revisionID = "debug-\(id)-v1"; canonicalTaskID = id; self.type = type; experienceFamilyKey = family
        titleZh = zh; titleEn = en; contentStatus = "approved"; safetyStatus = "approved"; localizationStatus = "development"; licenseStatus = "verified"
    }
}

@Model final class DailyPlan {
    @Attribute(.unique) var businessDayKey: String
    var timeZoneIdentifier: String; var taskPackVersion: String; var algorithmVersion: String; var seed: String; var createdAt: Date
    var profile: LocalProfile?
    @Relationship(deleteRule: .cascade, inverse: \DailyInstance.plan) var instances: [DailyInstance]
    init(key: String, zone: String, version: String, seed: String, profile: LocalProfile?) { businessDayKey = key; timeZoneIdentifier = zone; taskPackVersion = version; algorithmVersion = "v1"; self.seed = seed; createdAt = .now; self.profile = profile; instances = [] }
}

@Model final class DailyInstance {
    @Attribute(.unique) var instanceID: String
    var canonicalTaskID: String; var type: String; var snapshotZh: String; var snapshotEn: String; var iconKey: String
    var plan: DailyPlan?
    @Relationship(deleteRule: .cascade, inverse: \Completion.instance) var completion: Completion?
    init(card: TaskCard, plan: DailyPlan) { instanceID = "\(plan.businessDayKey)-\(card.canonicalTaskID)"; canonicalTaskID = card.canonicalTaskID; type = card.type; snapshotZh = card.titleZh; snapshotEn = card.titleEn; iconKey = card.experienceFamilyKey; self.plan = plan }
}

@Model final class Completion {
    @Attribute(.unique) var completionID: String
    var completedAt: Date; var revokedAt: Date?
    var instance: DailyInstance?
    init(instance: DailyInstance, at: Date = .now) { completionID = "\(instance.instanceID)-completion"; completedAt = at; self.instance = instance }
}

@Model final class NotificationSchedule { @Attribute(.unique) var identifier: String; var hour: Int; var minute: Int; init(identifier: String, hour: Int, minute: Int) { self.identifier = identifier; self.hour = hour; self.minute = minute } }
@Model final class ContentAsset { @Attribute(.unique) var assetKey: String; var licenseStatus: String; init(assetKey: String, licenseStatus: String = "verified") { self.assetKey = assetKey; self.licenseStatus = licenseStatus } }
@Model final class EngineState { @Attribute(.unique) var stateKey: String; var lastBusinessDayKey: String; init(lastBusinessDayKey: String = "") { stateKey = "engine"; self.lastBusinessDayKey = lastBusinessDayKey } }

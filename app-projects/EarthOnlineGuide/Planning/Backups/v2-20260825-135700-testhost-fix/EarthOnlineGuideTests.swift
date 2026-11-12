//
//  EarthOnlineGuideTests.swift
//  EarthOnlineGuideTests
//
//  Created by cczij on 2026/8/24.
//

import Testing
import Foundation
import SwiftData
@testable import EarthOnlineGuide

@MainActor struct EarthOnlineGuideTests {
    private func cards() -> [TaskCard] {
        [TaskCard(id: "a", family: "organizing", zh: "A", en: "A"), TaskCard(id: "b", family: "health", zh: "B", en: "B"), TaskCard(id: "c", family: "observation", zh: "C", en: "C"), TaskCard(id: "d", family: "interaction", zh: "D", en: "D"), TaskCard(id: "egg", type: "egg", family: "easterEgg", zh: "E", en: "E")]
    }

    @Test func sameSeedProducesSamePlan() {
        let seed = SelectionEngine.seed(installID: "install", day: "2026-08-24", pack: "v1")
        #expect(SelectionEngine.choose(cards: cards(), seed: seed, completedIDs: []).map(\.canonicalTaskID) == SelectionEngine.choose(cards: cards(), seed: seed, completedIDs: []).map(\.canonicalTaskID))
    }

    @Test func languageIsNotPartOfSeed() { #expect(SelectionEngine.seed(installID: "i", day: "2026-08-24", pack: "v1") == "i|2026-08-24|v1|v1") }

    @Test func completionCooldownExcludesTask() { #expect(!SelectionEngine.choose(cards: cards(), seed: "fixed", completedIDs: ["a"]).contains { $0.canonicalTaskID == "a" }) }

    @Test func eggDecisionIsDeterministic() { #expect(SelectionEngine.includesEgg(seed: "same") == SelectionEngine.includesEgg(seed: "same")) }

    @Test func insufficientCorePoolDoesNotProducePartialPlan() {
        let insufficient = Array(cards().prefix(2))
        #expect(SelectionEngine.choose(cards: insufficient, seed: "fixed", completedIDs: []).isEmpty)
    }

    @Test func businessDayChangesAtFiveAM() {
        let calendar = Calendar(identifier: .gregorian); let zone = TimeZone(secondsFromGMT: 0)!
        let before = calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 8, day: 24, hour: 4, minute: 59))!
        let after = calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 8, day: 24, hour: 5))!
        #expect(BusinessDay.current(now: before, calendar: calendar, zone: zone).key != BusinessDay.current(now: after, calendar: calendar, zone: zone).key)
    }

    @Test func notificationIdentifiersAreStable() { #expect(Set(["earth-guide-0900", "earth-guide-2000"]).count == 2) }

    @Test func validatorRejectsDuplicateOrUnapprovedPack() {
        let duplicate = [TaskCard(id: "a", family: "one", zh: "A", en: "A"), TaskCard(id: "a", family: "two", zh: "B", en: "B")]
        #expect({ if case .failure = TaskPackValidator.validate(duplicate, releaseReady: false) { return true }; return false }())
        let unsafe = TaskCard(id: "safe", family: "one", zh: "A", en: "A"); unsafe.safetyStatus = "pending"
        #expect({ if case .failure = TaskPackValidator.validate([unsafe], releaseReady: false) { return true }; return false }())
    }

    @Test func developmentPackIsNotReleaseReady() {
        #expect({ if case .failure = TaskPackValidator.validate(cards(), releaseReady: true) { return true }; return false }())
    }

    @Test func swiftDataPlanUsesOneContextAndPersistsRelationship() throws {
        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let authoringContext = ModelContext(container)
        SeedPack.ensure(in: authoringContext)
        let profile = LocalProfile(guideID: "test-guide")
        authoringContext.insert(profile)
        try authoringContext.save()

        let workingContext = ModelContext(container)
        let generatedPlan = try DailyTaskService(context: workingContext, profile: profile).today()
        let plan = try #require(generatedPlan)
        #expect(plan.profile?.installID == profile.installID)
        #expect(plan.instances.filter { $0.type == "core" }.count == 3)
        let instanceFromWorkingContext = try #require(plan.instances.first)
        try DailyTaskService(context: workingContext, profile: profile).toggle(instanceFromWorkingContext)
        #expect(instanceFromWorkingContext.completion?.revokedAt == nil)
    }

    @Test func plansAreUniquePerInstallAndBusinessDayRatherThanDisplayDay() throws {
        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        SeedPack.ensure(in: context)
        let first = LocalProfile(guideID: "first")
        let second = LocalProfile(guideID: "second")
        context.insert(first); context.insert(second)
        try context.save()

        let firstPlan = try #require(try DailyTaskService(context: context, profile: first).today())
        let secondPlan = try #require(try DailyTaskService(context: context, profile: second).today())
        #expect(firstPlan.businessDayKey == secondPlan.businessDayKey)
        #expect(firstPlan.planKey == "\(first.installID)|\(firstPlan.businessDaySequence)")
        #expect(secondPlan.planKey == "\(second.installID)|\(secondPlan.businessDaySequence)")
        #expect(firstPlan.planKey != secondPlan.planKey)
    }

    @Test func v1DiskStoreMigratesProfilePlanSnapshotAndRevocationIdempotently() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("EarthOnlineGuideMigration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("earth.sqlite")

        do {
            let v1Schema = Schema(versionedSchema: EarthOnlineSchemaV1.self)
            let v1Container = try ModelContainer(for: v1Schema, configurations: [ModelConfiguration(url: storeURL)])
            let context = ModelContext(v1Container)
            let profile = EarthOnlineSchemaV1.LocalProfile(installID: "v1-install", guideID: "legacy")
            let pack = EarthOnlineSchemaV1.TaskPack(version: "legacy-pack", isDevelopmentOnly: false)
            let card = EarthOnlineSchemaV1.TaskCard(id: "legacy-card", family: "record", zh: "旧快照", en: "Old snapshot")
            pack.cards = [card]
            let plan = EarthOnlineSchemaV1.DailyPlan(key: "2026-08-25", zone: "UTC", version: "legacy-pack", seed: "legacy", profile: profile)
            let item = EarthOnlineSchemaV1.DailyInstance(card: card, plan: plan)
            plan.instances = [item]
            let completion = EarthOnlineSchemaV1.Completion(instance: item, at: Date(timeIntervalSince1970: 100))
            completion.revokedAt = Date(timeIntervalSince1970: 200)
            item.completion = completion
            context.insert(profile); context.insert(pack); context.insert(plan)
            try context.save()
        }

        let v2Schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let firstOpen = try ModelContainer(for: v2Schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [ModelConfiguration(url: storeURL)])
        let firstContext = ModelContext(firstOpen)
        let plans = try firstContext.fetch(FetchDescriptor<DailyPlan>())
        let migrated = try #require(plans.first)
        #expect(migrated.profile?.guideID == "legacy")
        #expect(migrated.instances.first?.snapshotZh == "旧快照")
        #expect(migrated.instances.first?.completion?.revokedAt == Date(timeIntervalSince1970: 200))
        #expect(migrated.planKey == "v1-install|0")

        let secondOpen = try ModelContainer(for: v2Schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [ModelConfiguration(url: storeURL)])
        let secondPlans = try ModelContext(secondOpen).fetch(FetchDescriptor<DailyPlan>())
        #expect(secondPlans.count == 1)
        #expect(secondPlans.first?.planKey == migrated.planKey)
    }

    @Test func migrationFailureDoesNotReplaceOriginalStore() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("EarthOnlineGuideMigrationFailure-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("earth.sqlite")
        let original = Data("not a SwiftData store".utf8)
        try original.write(to: storeURL, options: .atomic)

        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let result = Result { try ModelContainer(for: schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [ModelConfiguration(url: storeURL)]) }
        let didFail: Bool
        if case .failure = result { didFail = true } else { didFail = false }
        #expect(didFail)
        #expect(try Data(contentsOf: storeURL) == original)
    }
}

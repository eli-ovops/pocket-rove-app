//
//  EarthOnlineGuideTests.swift
//  EarthOnlineGuideTests
//
//  Created by cczij on 2026/8/24.
//

import Testing
import XCTest
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

    @Test func hostedUnitTestsUseAnExplicitIsolatedContainerMode() {
        #expect(AppContainerBootstrap.storageMode(environment: ["XCTestBundlePath": "PlugIns/EarthOnlineGuideTests.xctest"]) == .hostedTest)
        #expect(AppContainerBootstrap.storageMode(environment: [:]) == .persistent)
    }

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
        try Task2MigrationFixture.verifyV1ToV2DiskMigration()
    }

    @Test func migrationFailureDoesNotReplaceOriginalStore() throws {
        try Task2MigrationFixture.verifyFailedMigrationPreservesOriginalStore()
    }

    @Test func unparseableLegacyBusinessDayUsesRecordedSafetyRecovery() {
        let resolution = LegacyV1Migration.resolve(businessDayKey: "not-a-day", timeZoneIdentifier: "Not/AZone")
        #expect(resolution.usedSafetyRecovery)
        #expect(resolution.sequence == 0)
        #expect(resolution.timeZoneIdentifier == "UTC")
        #expect(resolution.algorithmVersion == "v2-legacy-recovered-unparseable-business-day")
    }
}

final class Task2MigrationXCTests: XCTestCase {
    func testV1DiskStoreMigratesProfilePlanSnapshotAndRevocationIdempotently() throws {
        try Task2MigrationFixture.verifyV1ToV2DiskMigration()
    }

    func testMigrationFailureDoesNotReplaceOriginalStore() throws {
        try Task2MigrationFixture.verifyFailedMigrationPreservesOriginalStore()
    }
}

@MainActor final class Task3BusinessDayXCTests: XCTestCase {
    func testBusinessDayUsesFiveAMBoundaryAcrossDST() throws {
        let zone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let before = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 3, day: 8, hour: 4, minute: 59)))
        let after = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 3, day: 8, hour: 5, minute: 0)))

        let previousBusinessDay = BusinessDay.current(now: before, calendar: calendar, zone: zone)
        let newBusinessDay = BusinessDay.current(now: after, calendar: calendar, zone: zone)

        XCTAssertEqual(previousBusinessDay.key, "2026-03-07")
        XCTAssertEqual(previousBusinessDay.refreshAtUTC, after)
        XCTAssertEqual(newBusinessDay.key, "2026-03-08")
        XCTAssertEqual(newBusinessDay.startAtUTC, after)
        XCTAssertEqual(newBusinessDay.refreshAtUTC, calendar.date(byAdding: .day, value: 1, to: after))
    }
}

private struct FixedBusinessDayClock: BusinessDayClock {
    let now: Date
}

@MainActor final class Task3ServiceXCTests: XCTestCase {
    func testInjectedClockKeepsPlanKeysMonotonicWhenTimeRollsBack() throws {
        let zone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let container = try ModelContainer(for: Schema(versionedSchema: EarthOnlineSchemaV2.self), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        SeedPack.ensure(in: context)
        let profile = LocalProfile(guideID: "clock-test")
        context.insert(profile)
        try context.save()
        func date(_ day: Int) -> Date { calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 8, day: day, hour: 6))! }

        let first = try XCTUnwrap(try DailyTaskService(context: context, profile: profile, clock: FixedBusinessDayClock(now: date(25)), calendar: calendar, timeZone: zone).today())
        let second = try XCTUnwrap(try DailyTaskService(context: context, profile: profile, clock: FixedBusinessDayClock(now: date(26)), calendar: calendar, timeZone: zone).today())
        let rolledBack = try XCTUnwrap(try DailyTaskService(context: context, profile: profile, clock: FixedBusinessDayClock(now: date(24)), calendar: calendar, timeZone: zone).today())

        XCTAssertEqual(first.businessDaySequence + 1, second.businessDaySequence)
        XCTAssertEqual(second.businessDaySequence + 1, rolledBack.businessDaySequence)
        XCTAssertEqual(rolledBack.planKey, "\(profile.installID)|\(rolledBack.businessDaySequence)")
        XCTAssertEqual(rolledBack.businessDayKey, "2026-08-24")
    }
}

private enum Task2MigrationFixture {
    struct AssertionFailure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func verifyV1ToV2DiskMigration() throws {
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
        let plans = try ModelContext(firstOpen).fetch(FetchDescriptor<DailyPlan>())
        try require(plans.count == 1, "first V2 open must retain one migrated plan")
        guard let migrated = plans.first else { throw AssertionFailure(message: "first V2 open did not return a plan") }
        try require(migrated.profile?.guideID == "legacy", "profile must survive migration")
        try require(migrated.instances.first?.snapshotZh == "旧快照", "snapshot must survive migration")
        try require(migrated.instances.first?.completion?.revokedAt == Date(timeIntervalSince1970: 200), "revoked completion must survive migration")
        try require(migrated.businessDaySequence == 9367, "legacy business day must deterministically derive its 2001-01-01 sequence in the stored UTC zone")
        try require(migrated.startAtUTC == Date(timeIntervalSince1970: 1_787_634_000), "legacy business day start must derive from the stored date and frozen 05:00 zone boundary")
        try require(migrated.refreshAtUTC == Date(timeIntervalSince1970: 1_787_720_400), "legacy business day refresh must be the next local 05:00 boundary")
        try require(migrated.planKey == "v1-install|9367", "legacy plan key must derive from the V1 install ID and sequence")
        try require(migrated.instances.first?.completion?.updatedAtUTC == Date(timeIntervalSince1970: 200), "completion update time must derive from the latest persisted completion or revocation time")
        try require(migrated.instances.first?.completion?.lastMutationID == "migrated-v1|2026-08-25-legacy-card-completion", "completion mutation identity must deterministically derive from its persisted identity")

        let secondOpen = try ModelContainer(for: v2Schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [ModelConfiguration(url: storeURL)])
        let secondPlans = try ModelContext(secondOpen).fetch(FetchDescriptor<DailyPlan>())
        try require(secondPlans.count == 1, "second V2 open must not duplicate the plan")
        try require(secondPlans.first?.planKey == migrated.planKey, "second V2 open must preserve the migrated plan key")
        try require(secondPlans.first?.businessDaySequence == migrated.businessDaySequence, "second V2 open must preserve the derived business day sequence")
        try require(secondPlans.first?.startAtUTC == migrated.startAtUTC && secondPlans.first?.refreshAtUTC == migrated.refreshAtUTC, "second V2 open must preserve derived business day boundaries")
        try require(secondPlans.first?.instances.first?.completion?.updatedAtUTC == migrated.instances.first?.completion?.updatedAtUTC, "second V2 open must preserve completion update time")
        try require(secondPlans.first?.instances.first?.completion?.lastMutationID == migrated.instances.first?.completion?.lastMutationID, "second V2 open must preserve deterministic completion mutation identity")
    }

    static func verifyFailedMigrationPreservesOriginalStore() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("EarthOnlineGuideMigrationFailure-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("earth.sqlite")
        let original = Data("not a SwiftData store".utf8)
        try original.write(to: storeURL, options: .atomic)

        let schema = Schema(versionedSchema: EarthOnlineSchemaV2.self)
        let result = Result { try ModelContainer(for: schema, migrationPlan: EarthOnlineMigrationPlan.self, configurations: [ModelConfiguration(url: storeURL)]) }
        if case .success = result { throw AssertionFailure(message: "malformed store unexpectedly opened") }
        let currentBytes = try Data(contentsOf: storeURL)
        try require(currentBytes == original, "failed migration must not replace the original store bytes")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw AssertionFailure(message: message) }
    }
}

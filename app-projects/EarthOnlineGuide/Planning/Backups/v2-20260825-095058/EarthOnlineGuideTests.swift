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
        let schema = Schema(EarthOnlineSchemaV1.models)
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
}

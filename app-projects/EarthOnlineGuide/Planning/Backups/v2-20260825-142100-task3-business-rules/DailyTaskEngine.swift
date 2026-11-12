import Foundation
import SwiftData

struct BusinessDay: Equatable {
    let key: String; let sequence: Int; let zoneID: String; let startAtUTC: Date; let refreshAtUTC: Date
    static func current(now: Date = .now, calendar: Calendar = .current, zone: TimeZone = .current) -> BusinessDay {
        var calendar = calendar; calendar.timeZone = zone
        let shifted = calendar.date(byAdding: .hour, value: -5, to: now) ?? now
        let components = calendar.dateComponents([.year, .month, .day], from: shifted)
        let dayStart = calendar.date(from: components) ?? shifted
        let refresh = calendar.date(byAdding: .hour, value: 5, to: dayStart) ?? now
        let reference = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1)) ?? dayStart
        let sequence = calendar.dateComponents([.day], from: reference, to: dayStart).day ?? 0
        let key = String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        return BusinessDay(key: key, sequence: sequence, zoneID: zone.identifier, startAtUTC: dayStart, refreshAtUTC: refresh)
    }
}

struct SelectionEngine {
    static func seed(installID: String, day: String, pack: String) -> String { "\(installID)|\(day)|\(pack)|v1" }
    static func stableHash(_ value: String) -> UInt64 { value.utf8.reduce(14695981039346656037) { ($0 ^ UInt64($1)) &* 1099511628211 } }
    static func includesEgg(seed: String) -> Bool { stableHash(seed) % 4 == 0 }
    static func choose(cards: [TaskCard], seed: String, completedIDs: Set<String>, coreCount: Int = 3) -> [TaskCard] {
        let qualified = cards.filter { $0.contentStatus == "approved" && $0.safetyStatus == "approved" && $0.licenseStatus == "verified" && !completedIDs.contains($0.canonicalTaskID) }
        let ranked = qualified.sorted { stableHash(seed + $0.canonicalTaskID) < stableHash(seed + $1.canonicalTaskID) }
        var families = Set<String>(); var result: [TaskCard] = []
        for card in ranked where card.type == "core" && result.count < coreCount {
            if families.insert(card.experienceFamilyKey).inserted { result.append(card) }
        }
        if result.count < coreCount { for card in ranked where card.type == "core" && !result.contains(where: { $0.canonicalTaskID == card.canonicalTaskID }) && result.count < coreCount { result.append(card) } }
        guard result.count == coreCount else { return [] }
        if includesEgg(seed: seed), let egg = ranked.first(where: { candidate in candidate.type == "egg" && !result.contains(where: { $0.canonicalTaskID == candidate.canonicalTaskID }) }) { result.append(egg) }
        return result
    }
}

enum TaskPackValidationError: Error { case emptyPack, duplicateIdentity, missingIdentity, unsupportedType, unapprovedContent, missingLocalization, notReleaseLocalized }

enum TaskPackValidator {
    static func validate(_ cards: [TaskCard], releaseReady: Bool) -> Result<Void, TaskPackValidationError> {
        guard !cards.isEmpty else { return .failure(.emptyPack) }
        guard Set(cards.map(\.canonicalTaskID)).count == cards.count else { return .failure(.duplicateIdentity) }
        for card in cards {
            guard !card.canonicalTaskID.isEmpty, !card.revisionID.isEmpty, !card.experienceFamilyKey.isEmpty else { return .failure(.missingIdentity) }
            guard ["core", "egg"].contains(card.type) else { return .failure(.unsupportedType) }
            guard card.contentStatus == "approved", card.safetyStatus == "approved", card.licenseStatus == "verified" else { return .failure(.unapprovedContent) }
            guard !card.titleZh.isEmpty, !card.titleEn.isEmpty else { return .failure(.missingLocalization) }
            if releaseReady && card.localizationStatus != "released" { return .failure(.notReleaseLocalized) }
        }
        return .success(())
    }
}

@MainActor final class DailyTaskService {
    let context: ModelContext; let profile: LocalProfile
    init(context: ModelContext, profile: LocalProfile) { self.context = context; self.profile = profile }
    func today(now: Date = .now) throws -> DailyPlan? {
        let day = BusinessDay.current(now: now)
        guard let localProfile = context.model(for: profile.persistentModelID) as? LocalProfile else { return nil }
        let planKey = "\(localProfile.installID)|\(day.sequence)"
        if let existing = localProfile.dailyPlans.first(where: { $0.planKey == planKey }) { return existing }
        guard let pack = try context.fetch(FetchDescriptor<TaskPack>()).first else { return nil }
        let seed = SelectionEngine.seed(installID: localProfile.installID, day: day.key, pack: pack.version)
        let cooldown = completedCanonicalIDs(for: localProfile, before: day.key)
        let cards = SelectionEngine.choose(cards: pack.cards, seed: seed, completedIDs: cooldown)
        guard cards.filter({ $0.type == "core" }).count == 3 else { return nil }
        let plan = DailyPlan(key: day.key, sequence: day.sequence, zone: day.zoneID, startAtUTC: day.startAtUTC, refreshAtUTC: day.refreshAtUTC, installID: localProfile.installID, version: pack.version, seed: seed, profile: nil)
        context.insert(plan)
        plan.profile = localProfile
        plan.instances = cards.map { DailyInstance(card: $0, plan: plan) }
        try context.save(); return plan
    }
    func toggle(_ instance: DailyInstance) throws {
        guard let localInstance = context.model(for: instance.persistentModelID) as? DailyInstance else { return }
        if let completion = localInstance.completion, completion.revokedAt == nil { completion.revokedAt = .now } else if let completion = localInstance.completion { completion.revokedAt = nil } else { localInstance.completion = Completion(instance: localInstance) }
        try context.save()
    }
    private func completedCanonicalIDs(for profile: LocalProfile, before currentDay: String) -> Set<String> {
        let calendar = Calendar.current; guard let current = ISO8601DateFormatter().date(from: currentDay + "T05:00:00Z") else { return [] }
        return Set(profile.dailyPlans.flatMap(\.instances).compactMap { item in
            guard let completion = item.completion, completion.revokedAt == nil, let created = item.plan?.createdAt, calendar.dateComponents([.day], from: created, to: current).day ?? 99 <= 30 else { return nil }; return item.canonicalTaskID
        })
    }
}

enum SeedPack {
    @MainActor static func ensure(in context: ModelContext) {
        guard (try? context.fetch(FetchDescriptor<TaskPack>()).isEmpty) == true else { return }
        let pack = TaskPack(version: "debug-safe-v1", isDevelopmentOnly: true)
        pack.cards = [
            TaskCard(id: "tidy", family: "organizing", zh: "整理一下床头柜", en: "Tidy your bedside table"),
            TaskCard(id: "sky", family: "observation", zh: "记下今天天空的颜色", en: "Notice the color of today's sky"),
            TaskCard(id: "water", family: "health", zh: "去喝一杯温水", en: "Drink a glass of warm water"),
            TaskCard(id: "thanks", family: "interaction", zh: "向帮助过你的人说谢谢", en: "Thank someone who helped you"),
            TaskCard(id: "leaf", type: "egg", family: "easterEgg", zh: "找到一个紫色的东西", en: "Find something purple")]
        context.insert(pack); try? context.save()
    }
}

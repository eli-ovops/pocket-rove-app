import Foundation
import SwiftData

nonisolated struct BusinessDay: Equatable {
    let key: String; let sequence: Int; let zoneID: String; let startAtUTC: Date; let refreshAtUTC: Date
    static func current(now: Date = .now, calendar: Calendar = .current, zone: TimeZone = .current) -> BusinessDay {
        var calendar = calendar; calendar.timeZone = zone
        let localDayStart = calendar.startOfDay(for: now)
        let refreshToday = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: localDayStart) ?? localDayStart
        let businessDateStart = now < refreshToday ? (calendar.date(byAdding: .day, value: -1, to: localDayStart) ?? localDayStart) : localDayStart
        let start = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: businessDateStart) ?? businessDateStart
        let refresh = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let components = calendar.dateComponents([.year, .month, .day], from: businessDateStart)
        let reference = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1)) ?? businessDateStart
        let sequence = calendar.dateComponents([.day], from: reference, to: businessDateStart).day ?? 0
        let key = String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        return BusinessDay(key: key, sequence: sequence, zoneID: zone.identifier, startAtUTC: start, refreshAtUTC: refresh)
    }

    static func persisted(key: String, calendar: Calendar = Calendar(identifier: .gregorian), zone: TimeZone) -> BusinessDay? {
        let fields = key.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 3, let year = Int(fields[0]), let month = Int(fields[1]), let day = Int(fields[2]) else { return nil }
        var calendar = calendar
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = zone
        guard let localMidnight = calendar.date(from: DateComponents(year: year, month: month, day: day)), calendar.dateComponents([.year, .month, .day], from: localMidnight) == DateComponents(year: year, month: month, day: day) else { return nil }
        let start = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: localMidnight) ?? localMidnight
        return current(now: start, calendar: calendar, zone: zone)
    }
}

nonisolated protocol BusinessDayClock {
    var now: Date { get }
}

nonisolated struct SystemBusinessDayClock: BusinessDayClock {
    var now: Date { Date.now }
}

struct SelectionEngine {
    static func seed(installID: String, businessDaySequence: Int, pack: String) -> String { "\(installID)|\(businessDaySequence)|\(pack)|v2" }
    static func stableHash(_ value: String) -> UInt64 { value.utf8.reduce(14695981039346656037) { ($0 ^ UInt64($1)) &* 1099511628211 } }
    static func includesEgg(seed: String) -> Bool { stableHash(seed) % 4 == 0 }
    static func choose(cards: [TaskCard], seed: String, completedIDs: Set<String>, recentCoreFamilies: Set<String> = [], recentEggFamilies: Set<String> = [], coreCount: Int = 3) -> [TaskCard] {
        let qualified = cards.filter { $0.contentStatus == "approved" && $0.safetyStatus == "approved" && $0.licenseStatus == "verified" && !completedIDs.contains($0.canonicalTaskID) }
        let ranked = qualified.sorted {
            let lhsPenalty = $0.type == "egg" ? recentEggFamilies.contains($0.experienceFamilyKey) : recentCoreFamilies.contains($0.experienceFamilyKey)
            let rhsPenalty = $1.type == "egg" ? recentEggFamilies.contains($1.experienceFamilyKey) : recentCoreFamilies.contains($1.experienceFamilyKey)
            if lhsPenalty != rhsPenalty { return !lhsPenalty }
            return stableHash(seed + $0.canonicalTaskID) < stableHash(seed + $1.canonicalTaskID)
        }
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
        guard Set(cards.map(\.revisionID)).count == cards.count else { return .failure(.duplicateIdentity) }
        let cardsByCanonicalID = Dictionary(grouping: cards, by: \.canonicalTaskID)
        guard cardsByCanonicalID.values.allSatisfy({ groupedCards in
            groupedCards.count == 1 || (groupedCards.count == 2 && Set(groupedCards.map(\.type)) == ["core", "egg"])
        }) else { return .failure(.duplicateIdentity) }
        for card in cards {
            guard !card.canonicalTaskID.isEmpty, !card.revisionID.isEmpty, !card.experienceFamilyKey.isEmpty else { return .failure(.missingIdentity) }
            guard ["core", "egg"].contains(card.type) else { return .failure(.unsupportedType) }
            guard card.contentStatus == "approved", card.safetyStatus == "approved", card.licenseStatus == "verified" else { return .failure(.unapprovedContent) }
            guard !card.titleZh.isEmpty else { return .failure(.missingLocalization) }
            if releaseReady && (card.titleEn.isEmpty || card.localizationStatus != "released") { return .failure(.notReleaseLocalized) }
        }
        return .success(())
    }
}

enum DailyTaskServiceError: Error, Equatable {
    case instanceNotFound
    case completionWindowExpired
    case clockRollbackDetected
    case engineStateCorrupt
}

@MainActor final class DailyTaskService {
    let context: ModelContext; let profile: LocalProfile; let clock: any BusinessDayClock; let calendar: Calendar; let timeZone: TimeZone; let includeDevelopmentPacks: Bool
    init(context: ModelContext, profile: LocalProfile, clock: any BusinessDayClock = SystemBusinessDayClock(), calendar: Calendar = Calendar(identifier: .gregorian), timeZone: TimeZone = .current, includeDevelopmentPacks: Bool = false) { self.context = context; self.profile = profile; self.clock = clock; self.calendar = calendar; self.timeZone = timeZone; self.includeDevelopmentPacks = includeDevelopmentPacks }
    func today() throws -> DailyPlan? { try today(now: clock.now) }
    func today(now: Date) throws -> DailyPlan? {
        let wallDay = BusinessDay.current(now: now, calendar: calendar, zone: timeZone)
        guard let localProfile = context.model(for: profile.persistentModelID) as? LocalProfile else { return nil }
        let state = try engineState()
        guard state.isValidRecord else { throw DailyTaskServiceError.engineStateCorrupt }
        closeExpiredPlans(for: localProfile, at: now)
        if let active = localProfile.dailyPlans.first(where: { isCompleteActive($0, at: now) }) { return active }
        // A wall-clock rollback may never manufacture a new plan or reverse the
        // monotonic identity. Existing complete plans remain readable only in
        // their own frozen interval.
        guard wallDay.sequence >= state.lastBusinessDaySequence else {
            state.clockRollbackDetected = true
            state.lastReconciledAtUTC = now
            try context.save()
            throw DailyTaskServiceError.clockRollbackDetected
        }
        let day = wallDay
        let planKey = "\(localProfile.installID)|\(day.sequence)"
        if let existing = localProfile.dailyPlans.first(where: { $0.planKey == planKey && isCompleteActive($0, at: now) }) { return existing }
        guard let pack = try context.fetch(FetchDescriptor<TaskPack>()).first(where: { includeDevelopmentPacks || !$0.isDevelopmentOnly }) else { return nil }
        let seed = SelectionEngine.seed(installID: localProfile.installID, businessDaySequence: day.sequence, pack: pack.version)
        let cooldown = completedCanonicalIDs(for: localProfile, currentSequence: day.sequence)
        let familyCooldown = recentFamilies(for: localProfile, currentSequence: day.sequence)
        let cards = SelectionEngine.choose(cards: pack.cards, seed: seed, completedIDs: cooldown, recentCoreFamilies: familyCooldown.core, recentEggFamilies: familyCooldown.egg)
        guard cards.filter({ $0.type == "core" }).count == 3 else { return nil }
        let plan = DailyPlan(key: day.key, sequence: day.sequence, zone: day.zoneID, startAtUTC: day.startAtUTC, refreshAtUTC: day.refreshAtUTC, installID: localProfile.installID, version: pack.version, seed: seed, profile: nil)
        plan.expectedEggCount = cards.filter { $0.type == "egg" }.count
        guard cards.count == plan.expectedCoreCount + plan.expectedEggCount else { return nil }
        context.insert(plan)
        plan.profile = localProfile
        plan.instances = cards.map { DailyInstance(card: $0, plan: plan) }
        state.recordBusinessDayKey(day.key)
        state.lastBusinessDaySequence = day.sequence
        state.lastReconciledAtUTC = now
        state.timeZoneIdentifier = day.zoneID
        state.clockRollbackDetected = false
        try context.save(); return plan
    }
    private func isCompleteActive(_ plan: DailyPlan, at now: Date) -> Bool { plan.lifecycleState == "active" && now >= plan.startAtUTC && now < plan.refreshAtUTC && plan.instances.filter({ $0.type == "core" }).count == plan.expectedCoreCount && plan.instances.count == plan.expectedCoreCount + plan.expectedEggCount }
    func markCompleted(_ instance: DailyInstance, at now: Date? = nil) throws {
        let mutationTime = now ?? clock.now
        let localInstance = try activeInstance(instance, at: mutationTime)
        if let completion = localInstance.completion, completion.revokedAt == nil { return }
        if let completion = localInstance.completion {
            completion.revokedAt = nil
            completion.completedAt = mutationTime
            completion.updatedAtUTC = mutationTime
            completion.lastMutationID = mutationID(for: completion, action: "completed", at: mutationTime)
        } else {
            let completion = Completion(instance: localInstance, at: mutationTime)
            context.insert(completion)
            localInstance.completion = completion
        }
        try context.save()
    }

    func revokeCompletion(_ instance: DailyInstance, at now: Date? = nil) throws {
        let mutationTime = now ?? clock.now
        let localInstance = try activeInstance(instance, at: mutationTime)
        guard let completion = localInstance.completion, completion.revokedAt == nil else { return }
        completion.revokedAt = mutationTime
        completion.updatedAtUTC = mutationTime
        completion.lastMutationID = mutationID(for: completion, action: "revoked", at: mutationTime)
        try context.save()
    }

    func setCompletion(_ instance: DailyInstance, isCompleted: Bool, at now: Date? = nil) throws {
        if isCompleted { try markCompleted(instance, at: now) } else { try revokeCompletion(instance, at: now) }
    }

    func toggle(_ instance: DailyInstance) throws {
        let isCompleted = instance.completion?.revokedAt != nil || instance.completion == nil
        try setCompletion(instance, isCompleted: isCompleted)
    }

    private func activeInstance(_ instance: DailyInstance, at now: Date) throws -> DailyInstance {
        guard let localInstance = context.model(for: instance.persistentModelID) as? DailyInstance else { throw DailyTaskServiceError.instanceNotFound }
        guard let plan = localInstance.plan, isCompleteActive(plan, at: now) else { throw DailyTaskServiceError.completionWindowExpired }
        return localInstance
    }

    private func mutationID(for completion: Completion, action: String, at timestamp: Date) -> String {
        "\(completion.completionID)|\(action)|\(Int64(timestamp.timeIntervalSince1970 * 1_000))"
    }

    private func completedCanonicalIDs(for profile: LocalProfile, currentSequence: Int) -> Set<String> {
        return Set(profile.dailyPlans.flatMap(\.instances).compactMap { item in
            guard let completion = item.completion, completion.revokedAt == nil, let sequence = item.plan?.businessDaySequence else { return nil }
            let elapsedBusinessDays = currentSequence - sequence
            guard (1...30).contains(elapsedBusinessDays) else { return nil }
            return item.canonicalTaskID
        })
    }

    private func recentFamilies(for profile: LocalProfile, currentSequence: Int) -> (core: Set<String>, egg: Set<String>) {
        var core = Set<String>(); var egg = Set<String>()
        for instance in profile.dailyPlans.flatMap(\.instances) {
            guard let sequence = instance.plan?.businessDaySequence else { continue }
            let age = currentSequence - sequence
            if instance.type == "core", (1...90).contains(age) { core.insert(instance.iconKey) }
            if instance.type == "egg", (1...30).contains(age) { egg.insert(instance.iconKey) }
        }
        return (core, egg)
    }

    // This service is MainActor-isolated. All foreground reconciliation and
    // completion mutations therefore share one serial executor.
    func reconcile() throws -> DailyPlan? { try today(now: clock.now) }

    private func engineState() throws -> EngineState {
        if let existing = try context.fetch(FetchDescriptor<EngineState>()).first(where: { $0.stateKey == "engine" }) { return existing }
        let created = EngineState()
        context.insert(created)
        return created
    }

    private func closeExpiredPlans(for profile: LocalProfile, at now: Date) {
        for plan in profile.dailyPlans where plan.lifecycleState == "active" && now >= plan.refreshAtUTC {
            plan.lifecycleState = "closed"
        }
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

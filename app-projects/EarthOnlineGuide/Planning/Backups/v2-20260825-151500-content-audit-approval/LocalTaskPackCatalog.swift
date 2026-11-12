import Foundation

nonisolated struct LocalTaskPackDocument: Codable, Equatable {
    let formatVersion: Int
    let packID: String
    let contentVersion: String
    let selectionPolicyVersion: String
    let status: String
    let cards: [LocalTaskPackCard]

    static func decode(_ data: Data) throws -> LocalTaskPackDocument {
        try JSONDecoder().decode(LocalTaskPackDocument.self, from: data)
    }

    var selectionFingerprint: String {
        cards
            .sorted { ($0.canonicalTaskID, $0.taskRevisionID) < ($1.canonicalTaskID, $1.taskRevisionID) }
            .map { "\($0.canonicalTaskID)|\($0.taskRevisionID)|\($0.eligibleTypes.joined(separator: ","))" }
            .joined(separator: "\n")
    }
}

nonisolated struct LocalTaskPackCard: Codable, Equatable {
    let canonicalTaskID: String
    let taskRevisionID: String
    let eligibleTypes: [String]
    let sourceMembership: SourceMembership
    let title: LocalizedTitle
    let contentStatus: String
    let safetyStatus: String
    let localizationStatus: String
    let licenseStatus: String
    let experienceFamilyKey: String
    let assetKeys: [String]

    nonisolated struct SourceMembership: Codable, Equatable {
        let core: [Int]
        let egg: [Int]
    }

    nonisolated struct LocalizedTitle: Codable, Equatable {
        let zhHans: String
        let en: String

        enum CodingKeys: String, CodingKey {
            case zhHans = "zh-Hans"
            case en
        }
    }
}

nonisolated enum LocalTaskPackValidationMode {
    case development
    case release
}

nonisolated enum LocalTaskPackValidationError: Error, Equatable {
    case unsupportedFormat
    case missingPackIdentity
    case missingRequiredField(String)
    case duplicateCanonicalTaskID(String)
    case duplicateRevisionID(String)
    case invalidEligibleTypes(String)
    case invalidSourceMembership(String)
    case unknownAssetKey(String)
    case insufficientApprovedCapacity(core: Int, egg: Int)
    case releaseLocalizationIncomplete(String)
}

nonisolated enum LocalTaskPackValidator {
    static let minimumApprovedCore = 93
    static let minimumApprovedEgg = 31

    static func validate(_ pack: LocalTaskPackDocument, mode: LocalTaskPackValidationMode, verifiedAssetKeys: Set<String>) throws {
        guard pack.formatVersion == 1 else { throw LocalTaskPackValidationError.unsupportedFormat }
        guard !pack.packID.isEmpty, !pack.contentVersion.isEmpty, !pack.selectionPolicyVersion.isEmpty else { throw LocalTaskPackValidationError.missingPackIdentity }

        var canonicalIDs = Set<String>()
        var revisionIDs = Set<String>()
        var approvedCore = 0
        var approvedEgg = 0

        for card in pack.cards {
            guard !card.canonicalTaskID.isEmpty, !card.taskRevisionID.isEmpty, !card.title.zhHans.isEmpty, !card.experienceFamilyKey.isEmpty else {
                throw LocalTaskPackValidationError.missingRequiredField(card.canonicalTaskID)
            }
            guard canonicalIDs.insert(card.canonicalTaskID).inserted else {
                throw LocalTaskPackValidationError.duplicateCanonicalTaskID(card.canonicalTaskID)
            }
            guard revisionIDs.insert(card.taskRevisionID).inserted else {
                throw LocalTaskPackValidationError.duplicateRevisionID(card.taskRevisionID)
            }
            try validateEligibleTypes(card)
            for assetKey in card.assetKeys where !verifiedAssetKeys.contains(assetKey) {
                throw LocalTaskPackValidationError.unknownAssetKey(assetKey)
            }
            if mode == .release && (card.title.en.isEmpty || card.localizationStatus != "release-ready") {
                throw LocalTaskPackValidationError.releaseLocalizationIncomplete(card.canonicalTaskID)
            }
            guard card.contentStatus == "approved", card.safetyStatus == "passed", card.licenseStatus == "verified" else { continue }
            if card.eligibleTypes.contains("core") { approvedCore += 1 }
            if card.eligibleTypes.contains("egg") { approvedEgg += 1 }
        }

        guard approvedCore >= minimumApprovedCore, approvedEgg >= minimumApprovedEgg else {
            throw LocalTaskPackValidationError.insufficientApprovedCapacity(core: approvedCore, egg: approvedEgg)
        }
    }

    private static func validateEligibleTypes(_ card: LocalTaskPackCard) throws {
        let types = Set(card.eligibleTypes)
        guard !types.isEmpty, types.count == card.eligibleTypes.count, types.isSubset(of: ["core", "egg"]) else {
            throw LocalTaskPackValidationError.invalidEligibleTypes(card.canonicalTaskID)
        }
        let hasCoreMembership = !card.sourceMembership.core.isEmpty
        let hasEggMembership = !card.sourceMembership.egg.isEmpty
        guard types.contains("core") == hasCoreMembership, types.contains("egg") == hasEggMembership else {
            throw LocalTaskPackValidationError.invalidSourceMembership(card.canonicalTaskID)
        }
    }
}

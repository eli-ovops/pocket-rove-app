import Foundation
import SwiftData

@MainActor
enum ProductionTaskPackBootstrap {
    static let resourceName = "earth-online-guide-source-v1"
    static let verifiedAssetKeys: Set<String> = ["generic-task-icons-v1"]

    static func ensure(in context: ModelContext, bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ProductionTaskPackBootstrapError.resourceNotFound
        }
        try install(document: LocalTaskPackDocument.decode(Data(contentsOf: url)), in: context)
    }

    static func install(document: LocalTaskPackDocument, in context: ModelContext) throws {
        guard document.status == "active" else { throw ProductionTaskPackBootstrapError.inactiveSourcePack }
        try LocalTaskPackValidator.validate(document, mode: .development, verifiedAssetKeys: verifiedAssetKeys)

        let version = "\(document.packID)-\(document.contentVersion)"
        if try context.fetch(FetchDescriptor<TaskPack>()).contains(where: { $0.version == version }) {
            return
        }

        let activeSourceCards = document.cards.filter {
            $0.contentStatus == "approved" && $0.safetyStatus == "approved" && $0.licenseStatus == "verified-user-owned"
        }
        let cards = activeSourceCards.flatMap { sourceCard in
            sourceCard.eligibleTypes.map { type in
                let card = TaskCard(
                    id: sourceCard.canonicalTaskID,
                    type: type,
                    family: GenericTaskIconKey.key(canonicalTaskID: sourceCard.canonicalTaskID, type: type),
                    zh: sourceCard.title.zhHans,
                    en: sourceCard.title.en
                )
                card.revisionID = "\(sourceCard.taskRevisionID)-\(type)"
                card.contentStatus = sourceCard.contentStatus
                card.safetyStatus = sourceCard.safetyStatus
                card.localizationStatus = sourceCard.localizationStatus
                // The source record retains the user-owned provenance; the runtime model only needs the verified gate.
                card.licenseStatus = "verified"
                return card
            }
        }

        guard case .success = TaskPackValidator.validate(cards, releaseReady: false) else {
            throw ProductionTaskPackBootstrapError.runtimeValidationFailed
        }

        let pack = TaskPack(version: version, isDevelopmentOnly: false)
        context.insert(pack)
        for card in cards {
            card.pack = pack
            context.insert(card)
        }
        try context.save()
    }
}

enum ProductionTaskPackBootstrapError: LocalizedError {
    case resourceNotFound
    case inactiveSourcePack
    case runtimeValidationFailed

    var errorDescription: String? {
        switch self {
        case .resourceNotFound: "正式任务包资源不存在。"
        case .inactiveSourcePack: "正式任务包未通过内容门禁。"
        case .runtimeValidationFailed: "正式任务包未通过运行时一致性校验。"
        }
    }
}

import Foundation

@main
struct TaskPackAuditVerifier {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { throw VerifierError.missingPath }
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let document = try LocalTaskPackDocument.decode(data)

        try LocalTaskPackValidator.validate(
            document,
            mode: .development,
            verifiedAssetKeys: ["generic-task-icons-v1"]
        )

        let counts = document.cards.reduce(into: [String: [String: Int]]()) { result, card in
            for type in card.eligibleTypes {
                result[type, default: [:]][card.contentStatus, default: 0] += 1
            }
        }
        guard counts["core"]?["approved"] == 124,
              counts["egg"]?["approved"] == 39,
              document.cards.filter({ $0.eligibleTypes == ["core", "egg"] }).count == 4 else {
            throw VerifierError.invalidAuditSummary
        }
        print("TASKPACK_AUDIT_PASS records=218 approvedCore=124 approvedEgg=39 shared=4 release=blocked-en-pending")
    }

    enum VerifierError: Error {
        case missingPath
        case invalidAuditSummary
    }
}

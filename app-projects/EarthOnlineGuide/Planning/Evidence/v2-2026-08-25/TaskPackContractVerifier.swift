import Foundation

@main
struct TaskPackContractVerifier {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { throw VerifierError.missingPath }
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let document = try LocalTaskPackDocument.decode(data)

        do {
            try LocalTaskPackValidator.validate(document, mode: .development, verifiedAssetKeys: ["generic-task-icons-v1"])
            throw VerifierError.unexpectedApproval
        } catch let error as LocalTaskPackValidationError {
            guard error == .insufficientApprovedCapacity(core: 0, egg: 0) else { throw error }
        }

        let coreMemberships = document.cards.reduce(0) { $0 + $1.sourceMembership.core.count }
        let eggMemberships = document.cards.reduce(0) { $0 + $1.sourceMembership.egg.count }
        let shared = document.cards.filter { $0.eligibleTypes == ["core", "egg"] }.count
        guard document.cards.count == 218, coreMemberships == 166, eggMemberships == 56, shared == 4 else {
            throw VerifierError.invalidSourceShape
        }
        print("TASKPACK_PARSE_PASS records=218 coreMemberships=166 eggMemberships=56 shared=4 approvedCore=0 approvedEgg=0")
    }

    enum VerifierError: Error {
        case missingPath
        case unexpectedApproval
        case invalidSourceShape
    }
}

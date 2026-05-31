import Foundation

struct Card: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var front: String
    var back: String          // raw: "hrnec / kvetinac"
    var createdAt: Date = Date()

    var backAlternatives: [String] {
        back.components(separatedBy: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func isCorrect(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return backAlternatives.contains {
            $0.lowercased() == trimmed.lowercased()
        }
    }
}

import Foundation

struct Card: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var front: String
    var back: String          // raw: "hrnec / kvetinac"
    var createdAt: Date = Date()

    init(id: UUID = UUID(), front: String, back: String, createdAt: Date = Date()) {
        self.id = id
        self.front = front
        self.back = back
        self.createdAt = createdAt
    }

    // Tolerant decoding — see Persistence.swift. front/back are the only fields
    // a card cannot exist without; everything else falls back to a default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        front     = try c.decode(String.self, forKey: .front)
        back      = try c.decode(String.self, forKey: .back)
        id        = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

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

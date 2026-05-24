import Foundation

struct WordPair: Identifiable, Codable {
    let id: UUID
    var front: String   // levá strana (před pomlčkou)
    var back: String    // pravá strana (za pomlčkou)

    init(id: UUID = UUID(), front: String, back: String) {
        self.id = id
        self.front = front
        self.back = back
    }
}

enum QuizDirection: String {
    case frontToBack = "frontToBack"
    case backToFront = "backToFront"
    case random      = "random"
}

struct WordList: Identifiable, Codable {
    let id: UUID
    var name: String
    var pairs: [WordPair]
    var createdAt: Date
    var lastStudied: Date?

    init(id: UUID = UUID(), name: String, pairs: [WordPair]) {
        self.id = id
        self.name = name
        self.pairs = pairs
        self.createdAt = Date()
        self.lastStudied = nil
    }
}

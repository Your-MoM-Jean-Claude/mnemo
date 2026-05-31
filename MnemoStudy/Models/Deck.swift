import Foundation

struct Deck: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var cards: [Card] = []
    var folderID: UUID?
    var createdAt: Date = Date()
    var lastStudied: Date?
    var isTemporary: Bool = false
    var parentDeckID: UUID?      // set when isTemporary == true
    var sortOrder: Int = 0
}

struct DeckFolder: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var sortOrder: Int = 0
    var createdAt: Date = Date()
}

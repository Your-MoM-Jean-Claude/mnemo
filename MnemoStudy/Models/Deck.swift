import Foundation

struct Deck: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var cards: [Card] = []
    var folderID: UUID?
    var createdAt: Date = Date()
    var lastStudied: Date?
    var isTemporary: Bool = false
    var parentDeckID: UUID?      // set when isTemporary == true
    var sortOrder: Int = 0
    var isBundled: Bool = false  // true for built-in starter decks (free, don't count to limit)

    init(id: UUID = UUID(), name: String, cards: [Card] = []) {
        self.id = id
        self.name = name
        self.cards = cards
    }

    // Tolerant decoding — see Persistence.swift. `isBundled` was added in build
    // 41 and, with the synthesized decoder, made every deck saved by an earlier
    // build undecodable. Only `name` is genuinely required now.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name         = try c.decode(String.self, forKey: .name)
        id           = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        cards        = try c.decodeIfPresent([Failable<Card>].self, forKey: .cards)?.compactMap { $0.value } ?? []
        folderID     = try c.decodeIfPresent(UUID.self, forKey: .folderID)
        createdAt    = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastStudied  = try c.decodeIfPresent(Date.self, forKey: .lastStudied)
        isTemporary  = try c.decodeIfPresent(Bool.self, forKey: .isTemporary) ?? false
        parentDeckID = try c.decodeIfPresent(UUID.self, forKey: .parentDeckID)
        sortOrder    = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        isBundled    = try c.decodeIfPresent(Bool.self, forKey: .isBundled) ?? false
    }
}

struct DeckFolder: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name      = try c.decode(String.self, forKey: .name)
        id        = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

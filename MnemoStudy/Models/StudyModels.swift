import Foundation

// MARK: - Study mode

enum StudyMode: String, CaseIterable, Codable {
    case typing   // user types the answer
    case show     // know / don't know flip
    case quiz     // 4 multiple choice options
}

enum CardOrder: String, CaseIterable, Codable {
    case ascending
    case descending
    case random
}

enum StudyDirection: String, CaseIterable, Codable {
    case frontToBack   // show front, answer back
    case backToFront   // show back, answer front
    case random
}

// MARK: - Session config

struct StudyConfig {
    var mode: StudyMode = .typing
    var direction: StudyDirection = .frontToBack
    var order: CardOrder = .random
    var sectionSize: Int = 10        // 2–20
    var requiredCorrect: Int = 2     // 1–5
}

// MARK: - Active session item

struct SessionItem {
    var card: Card
    var correctCount: Int = 0
    var showAfter: Int = 0           // skip counter after wrong answer
    var isComplete: Bool = false
}

// MARK: - Session result

struct SessionResult {
    var deckID: UUID
    var date: Date = Date()
    var duration: TimeInterval
    var mode: StudyMode
    var totalAnswered: Int
    var totalCorrect: Int
    var wrongCardIDs: Set<UUID>

    var accuracy: Double {
        guard totalAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswered)
    }
}

// MARK: - Per-card statistics

struct CardStats: Codable {
    var attempts: Int = 0
    var correct: Int = 0
    var consecutiveCorrect: Int = 0   // for temp-deck removal
    var lastAnswered: Date?
    // SRS
    var srsInterval: Int = 1          // days
    var srsDueDate: Date?
    var srsEaseFactor: Double = 2.5

    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correct) / Double(attempts)
    }

    var isDue: Bool {
        guard let due = srsDueDate else { return true }
        return due <= Date()
    }
}

// MARK: - Per-session record (for history)

struct SessionRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var duration: TimeInterval
    var totalAnswered: Int
    var totalCorrect: Int
    var mode: StudyMode
    var deckID: UUID

    var accuracy: Double {
        guard totalAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswered)
    }
}

// MARK: - Per-deck statistics

struct DeckStats: Codable {
    var deckID: UUID
    var sessions: [SessionRecord] = []
    var cardStats: [UUID: CardStats] = [:]

    var totalSessions: Int { sessions.count }

    var totalAnswers: Int { sessions.reduce(0) { $0 + $1.totalAnswered } }
    var totalCorrect: Int { sessions.reduce(0) { $0 + $1.totalCorrect } }

    var overallAccuracy: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswers)
    }

    mutating func apply(_ result: SessionResult) {
        sessions.append(SessionRecord(
            date: result.date,
            duration: result.duration,
            totalAnswered: result.totalAnswered,
            totalCorrect: result.totalCorrect,
            mode: result.mode,
            deckID: result.deckID
        ))
    }
}

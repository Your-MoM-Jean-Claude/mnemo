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

struct StudyConfig: Identifiable {
    let id = UUID()
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
    var reversed: Bool = false       // for .random direction: per-card fixed direction
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
    var cardAdjustedTimes: [UUID: Double] = [:]   // response time adjusted for word length

    var accuracy: Double {
        guard totalAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswered)
    }

    // Adjusted times of correctly answered cards — fed into calibration
    var correctAdjustedTimes: [Double] {
        cardAdjustedTimes.compactMap { (id, t) in wrongCardIDs.contains(id) ? nil : t }
    }
}

// MARK: - User tempo profile (behavioral SRS calibration)

struct UserTempoProfile: Codable {
    var samples: [Double] = []       // adjusted response times of correct answers (rolling)
    var sessions: Int = 0            // completed study sessions observed

    static let calibrationSessions = 5
    var isCalibrated: Bool { sessions >= UserTempoProfile.calibrationSessions }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        samples  = try c.decodeIfPresent([Double].self, forKey: .samples) ?? []
        sessions = try c.decodeIfPresent(Int.self, forKey: .sessions) ?? 0
    }

    // Median of observed times — personal baseline
    var median: Double {
        guard !samples.isEmpty else { return 4.0 }
        let s = samples.sorted()
        return s[s.count / 2]
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

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        attempts           = try c.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        correct            = try c.decodeIfPresent(Int.self, forKey: .correct) ?? 0
        consecutiveCorrect = try c.decodeIfPresent(Int.self, forKey: .consecutiveCorrect) ?? 0
        lastAnswered       = try c.decodeIfPresent(Date.self, forKey: .lastAnswered)
        srsInterval        = try c.decodeIfPresent(Int.self, forKey: .srsInterval) ?? 1
        srsDueDate         = try c.decodeIfPresent(Date.self, forKey: .srsDueDate)
        srsEaseFactor      = try c.decodeIfPresent(Double.self, forKey: .srsEaseFactor) ?? 2.5
    }

    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correct) / Double(attempts)
    }

    /// A card counts as due only once SRS has actually scheduled it. Cards that
    /// have never been studied are "new", not "due" — the daily review queue and
    /// the deck badge must agree on that.
    var isScheduled: Bool { srsDueDate != nil }

    var isDue: Bool {
        guard let due = srsDueDate else { return false }
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

    init(date: Date, duration: TimeInterval, totalAnswered: Int,
         totalCorrect: Int, mode: StudyMode, deckID: UUID) {
        self.date = date
        self.duration = duration
        self.totalAnswered = totalAnswered
        self.totalCorrect = totalCorrect
        self.mode = mode
        self.deckID = deckID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date          = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        duration      = try c.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        totalAnswered = try c.decodeIfPresent(Int.self, forKey: .totalAnswered) ?? 0
        totalCorrect  = try c.decodeIfPresent(Int.self, forKey: .totalCorrect) ?? 0
        mode          = try c.decodeIfPresent(StudyMode.self, forKey: .mode) ?? .typing
        deckID        = try c.decodeIfPresent(UUID.self, forKey: .deckID) ?? UUID()
        id            = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    }

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

    // Rolled-up totals for sessions that have aged out of `sessions`. The detail
    // history is capped because the whole stats blob has to fit inside the
    // iCloud key-value store's 1 MB budget; without a cap sync dies silently
    // once a heavy user accumulates a few hundred sessions.
    var archivedSessions: Int = 0
    var archivedAnswers: Int = 0
    var archivedCorrect: Int = 0

    static let maxStoredSessions = 200

    init(deckID: UUID) { self.deckID = deckID }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        deckID           = try c.decodeIfPresent(UUID.self, forKey: .deckID) ?? UUID()
        sessions         = try c.decodeIfPresent([Failable<SessionRecord>].self, forKey: .sessions)?.compactMap { $0.value } ?? []
        cardStats        = try c.decodeIfPresent([UUID: Failable<CardStats>].self, forKey: .cardStats)?.compactMapValues { $0.value } ?? [:]
        archivedSessions = try c.decodeIfPresent(Int.self, forKey: .archivedSessions) ?? 0
        archivedAnswers  = try c.decodeIfPresent(Int.self, forKey: .archivedAnswers) ?? 0
        archivedCorrect  = try c.decodeIfPresent(Int.self, forKey: .archivedCorrect) ?? 0
    }

    var totalSessions: Int { sessions.count + archivedSessions }

    var totalAnswers: Int { sessions.reduce(0) { $0 + $1.totalAnswered } + archivedAnswers }
    var totalCorrect: Int { sessions.reduce(0) { $0 + $1.totalCorrect } + archivedCorrect }

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
        trimHistory()
    }

    /// Fold the oldest records into the archived totals so headline statistics
    /// stay correct while the stored payload stays bounded.
    mutating func trimHistory() {
        let overflow = sessions.count - DeckStats.maxStoredSessions
        guard overflow > 0 else { return }
        for r in sessions.prefix(overflow) {
            archivedSessions += 1
            archivedAnswers  += r.totalAnswered
            archivedCorrect  += r.totalCorrect
        }
        sessions.removeFirst(overflow)
    }
}

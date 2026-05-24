import Foundation

// MARK: - Settings

enum QuizMode: String, CaseIterable {
    case typing
    case flashcard
    case multipleChoice
}

struct QuizSettings {
    var batchSize: Int = 10
    var requiredCorrect: Int = 2
    var direction: QuizDirection = .frontToBack
    var shuffleOrder: Bool = true
    var mode: QuizMode = .typing
}

// MARK: - Word-level historical stats

struct WordStats: Codable {
    var attempts: Int = 0
    var correct: Int  = 0
    var lastSeen: Date?
    var interval: Int = 0   // SRS: days until next review; 0 = always due

    var accuracy: Double { attempts > 0 ? Double(correct) / Double(attempts) : -1 }

    var dueDate: Date? {
        guard let last = lastSeen, interval > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: interval, to: last)
    }

    var isDue: Bool {
        guard let due = dueDate else { return true }
        return due <= Date()
    }

    // 0 = hard (<60%), 1 = medium or unknown (60–80%), 2 = easy (>80%)
    var difficultyTier: Int {
        guard attempts > 0 else { return 1 }
        let acc = Double(correct) / Double(attempts)
        if acc < 0.6 { return 0 }
        if acc < 0.8 { return 1 }
        return 2
    }
}

// MARK: - Session Record (stored per list, capped at 50)

struct SessionRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var correct: Int
    var total: Int
    var duration: TimeInterval

    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}

// MARK: - Quiz Result (transient — passed from QuizViewModel to LibraryViewModel)

struct QuizResult {
    let listID: UUID
    let correct: Int
    let total: Int
    let bestStreak: Int
    let wordStats: [UUID: WordStats]
    let date: Date
    let duration: TimeInterval
}

// MARK: - List Statistics

struct ListStatistics: Codable {
    var totalSessions: Int = 0
    var totalAnswers: Int  = 0
    var totalCorrect: Int  = 0
    var bestStreak: Int    = 0
    var wordStats: [UUID: WordStats]  = [:]
    var sessions: [SessionRecord]     = []

    var accuracy: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswers)
    }

    var lastSession: SessionRecord? { sessions.last }

    // Positive = last session better than overall average
    var trend: Double? {
        guard let last = sessions.last, last.total > 0, totalAnswers > 0 else { return nil }
        return last.accuracy - accuracy
    }

    var sessionsThisWeek: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.date >= cutoff }.count
    }

    mutating func apply(_ result: QuizResult) {
        totalSessions += 1
        totalAnswers  += result.total
        totalCorrect  += result.correct
        bestStreak     = max(bestStreak, result.bestStreak)

        for (id, incoming) in result.wordStats {
            var ws = wordStats[id] ?? WordStats()
            ws.attempts += incoming.attempts
            ws.correct  += incoming.correct
            ws.lastSeen  = incoming.lastSeen
            ws.interval  = incoming.interval
            wordStats[id] = ws
        }

        let record = SessionRecord(date: result.date, correct: result.correct,
                                   total: result.total, duration: result.duration)
        sessions.append(record)
        if sessions.count > 50 { sessions.removeFirst() }
    }
}

// MARK: - Card types

struct CardStats {
    var correctStreak: Int = 0
    var totalAttempts: Int = 0
    var totalCorrect: Int  = 0
}

struct QuizCard: Identifiable {
    let id: UUID
    let pair: WordPair
    let questionText: String
    let answerText: String
    var stats: CardStats
    let difficultyTier: Int

    init(pair: WordPair, direction: QuizDirection, historicalStats: WordStats?) {
        self.id             = pair.id
        self.pair           = pair
        self.stats          = CardStats()
        self.difficultyTier = historicalStats?.difficultyTier ?? 1

        let useReverse: Bool
        switch direction {
        case .frontToBack: useReverse = false
        case .backToFront: useReverse = true
        case .random:      useReverse = Bool.random()
        }

        if useReverse {
            self.questionText = pair.back
            self.answerText   = pair.front
        } else {
            self.questionText = pair.front
            self.answerText   = pair.back
        }
    }
}

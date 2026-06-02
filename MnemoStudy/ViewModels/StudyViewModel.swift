import Foundation
import Combine

class StudyViewModel: ObservableObject {
    @Published var currentItem: SessionItem?
    @Published var isSessionFinished: Bool = false
    @Published var showResult: Bool = false     // inline answer reveal
    @Published var lastAnswerCorrect: Bool = false

    private(set) var config: StudyConfig
    private(set) var deck: Deck

    private var queue: [SessionItem] = []
    private var completedCount: Int  = 0
    private var pendingCards: [Card] = []

    private(set) var wrongCardIDs: Set<UUID> = []
    private(set) var cardAdjustedTimes: [UUID: Double] = [:]
    private var totalAnswered: Int   = 0
    private var totalCorrect: Int    = 0
    private var startTime: Date      = Date()
    private var lastCardID: UUID?    = nil
    private var cardAppearTime: Date = Date()

    // Quiz options for current card
    @Published var quizOptions: [String] = []

    private let srsEnabled: Bool
    private let cardStats: [UUID: CardStats]

    init(deck: Deck, config: StudyConfig, srsEnabled: Bool = false, cardStats: [UUID: CardStats] = [:]) {
        self.deck       = deck
        self.config     = config
        self.srsEnabled = srsEnabled
        self.cardStats  = cardStats
        buildQueue()
    }

    // MARK: - Setup

    private func buildQueue() {
        startTime = Date()
        var cards = deck.cards

        if srsEnabled {
            // SRS is the primary selector: most-overdue and new cards first.
            // New cards (no due date) sort first (treated as .distantPast).
            cards.sort { a, b in
                let da = cardStats[a.id]?.srsDueDate ?? .distantPast
                let db = cardStats[b.id]?.srsDueDate ?? .distantPast
                return da < db
            }
        } else {
            switch config.order {
            case .ascending:  break
            case .descending: cards.reverse()
            case .random:     cards.shuffle()
            }
        }

        pendingCards = Array(cards.dropFirst(config.sectionSize))
        let initial  = Array(cards.prefix(config.sectionSize))
        queue = initial.map { makeItem($0) }
        currentItem = nextItem()
        if config.mode == .quiz { buildQuizOptions() }
    }

    private func makeItem(_ card: Card) -> SessionItem {
        var item = SessionItem(card: card)
        if config.direction == .random { item.reversed = Bool.random() }
        return item
    }

    // Effective direction for an item (handles .random per-card)
    private func reversed(_ item: SessionItem) -> Bool {
        switch config.direction {
        case .frontToBack: return false
        case .backToFront: return true
        case .random:      return item.reversed
        }
    }

    private func nextItem() -> SessionItem? {
        for i in queue.indices { if queue[i].showAfter > 0 { queue[i].showAfter -= 1 } }

        var ready = queue.filter { $0.showAfter == 0 && !$0.isComplete }
        guard !ready.isEmpty else { return nil }

        // avoid consecutive repeat
        if ready.count > 1, let last = lastCardID {
            let noRepeat = ready.filter { $0.card.id != last }
            if !noRepeat.isEmpty { ready = noRepeat }
        }

        return config.order == .random ? ready.randomElement() : ready.first
    }

    // MARK: - Answer

    func submitTyping(_ input: String) {
        guard let item = currentItem else { return }
        let correct = resolveAnswer(item: item, userInput: input, choice: nil)
        handleResult(item: item, correct: correct)
    }

    func submitShow(knows: Bool) {
        guard let item = currentItem else { return }
        handleResult(item: item, correct: knows)
    }

    func submitQuiz(choice: String) {
        guard let item = currentItem else { return }
        let correct = resolveAnswer(item: item, userInput: nil, choice: choice)
        handleResult(item: item, correct: correct)
    }

    private func resolveAnswer(item: SessionItem, userInput: String?, choice: String?) -> Bool {
        let rev = reversed(item)
        switch config.mode {
        case .typing:
            if rev {
                // expected answer is the FRONT side (case-insensitive exact match)
                let t = (userInput ?? "").trimmingCharacters(in: .whitespaces).lowercased()
                return !t.isEmpty && item.card.front.trimmingCharacters(in: .whitespaces).lowercased() == t
            } else {
                return item.card.isCorrect(userInput ?? "")   // back alternatives via "/"
            }
        case .show:
            return true   // "know" branch is handled in submitShow
        case .quiz:
            return (choice ?? "") == primaryAnswer(item.card, reversed: rev)
        }
    }

    // For quiz: the answer side collapsed to its primary alternative (no "/")
    private func primaryAnswer(_ card: Card, reversed: Bool) -> String {
        reversed ? card.front : (card.backAlternatives.first ?? card.back)
    }

    // Correct option text for the current quiz card (for inline highlight)
    var currentExpectedAnswer: String {
        guard let item = currentItem else { return "" }
        return primaryAnswer(item.card, reversed: reversed(item))
    }

    private func handleResult(item: SessionItem, correct: Bool) {
        lastAnswerCorrect = correct
        showResult        = true
        totalAnswered    += 1
        lastCardID        = item.card.id

        // Behavioral SRS: store word-length-adjusted response time (rating
        // is computed at save time using the user's calibrated tempo profile)
        let elapsed  = Date().timeIntervalSince(cardAppearTime)
        let wordLen  = max(item.card.front.count, item.card.back.count)
        cardAdjustedTimes[item.card.id] = SRSEngine.adjustedTime(elapsed: elapsed, wordLen: wordLen)

        guard let idx = queue.firstIndex(where: { $0.id == item.id }) else { return }

        if correct {
            totalCorrect += 1
            queue[idx].correctCount += 1
            if queue[idx].correctCount >= config.requiredCorrect {
                queue[idx].isComplete = true
                completedCount += 1
                if let next = pendingCards.first {
                    pendingCards.removeFirst()
                    queue.append(makeItem(next))
                }
            }
        } else {
            wrongCardIDs.insert(item.card.id)
            queue[idx].correctCount = 0
            queue[idx].showAfter    = Int.random(in: 3...5)
        }

        let remaining = queue.filter { !$0.isComplete }
        if remaining.isEmpty {
            isSessionFinished = true
        }
    }

    func advanceAfterResult() {
        showResult       = false
        currentItem      = nextItem()
        cardAppearTime   = Date()
        if config.mode == .quiz { buildQuizOptions() }
    }

    // MARK: - Quiz options

    private func buildQuizOptions() {
        guard let item = currentItem else { quizOptions = []; return }
        let rev = reversed(item)
        let correct = primaryAnswer(item.card, reversed: rev)

        var pool = deck.cards
            .filter { $0.id != item.card.id }
            .map { primaryAnswer($0, reversed: rev) }
        pool.removeAll { $0 == correct }      // avoid a distractor identical to the answer
        pool = Array(Set(pool))               // de-duplicate distractors
        pool.shuffle()
        var options = Array(pool.prefix(3))
        options.append(correct)
        options.shuffle()
        quizOptions = options
    }

    // MARK: - Result

    func buildResult() -> SessionResult {
        SessionResult(
            deckID:        deck.id,
            duration:      Date().timeIntervalSince(startTime),
            mode:          config.mode,
            totalAnswered: totalAnswered,
            totalCorrect:  totalCorrect,
            wrongCardIDs:  wrongCardIDs,
            cardAdjustedTimes: cardAdjustedTimes
        )
    }

    // MARK: - Display helpers

    var currentFront: String {
        guard let item = currentItem else { return "" }
        return reversed(item) ? item.card.back : item.card.front
    }

    var currentBack: String {
        guard let item = currentItem else { return "" }
        return reversed(item) ? item.card.front : item.card.back
    }

    var progress: Double {
        let total = deck.cards.count
        guard total > 0 else { return 0 }
        return Double(completedCount) / Double(total)
    }

    var completedOfTotal: String { "\(completedCount) / \(deck.cards.count)" }
}

extension SessionItem: Identifiable {
    var id: UUID { card.id }
}

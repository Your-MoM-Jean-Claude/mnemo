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
    private var totalAnswered: Int   = 0
    private var totalCorrect: Int    = 0
    private var startTime: Date      = Date()
    private var lastCardID: UUID?    = nil

    // Quiz options for current card
    @Published var quizOptions: [String] = []
    private var allDeck: Deck

    init(deck: Deck, config: StudyConfig, allDecks: [Deck]) {
        self.deck   = deck
        self.config = config
        self.allDeck = deck
        buildQueue()
    }

    // MARK: - Setup

    private func buildQueue() {
        startTime = Date()
        var cards = deck.cards
        switch config.order {
        case .ascending:  break
        case .descending: cards.reverse()
        case .random:     cards.shuffle()
        }
        pendingCards = Array(cards.dropFirst(config.sectionSize))
        let initial  = Array(cards.prefix(config.sectionSize))
        queue = initial.map { SessionItem(card: $0) }
        currentItem = nextItem()
        if config.mode == .quiz { buildQuizOptions() }
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
        switch config.mode {
        case .typing:
            return item.card.isCorrect(userInput ?? "")
        case .show:
            return true   // "know" branch is handled in submitShow
        case .quiz:
            let expected = config.direction == .backToFront ? item.card.front : item.card.back
            return (choice ?? "") == expected
        }
    }

    private func handleResult(item: SessionItem, correct: Bool) {
        lastAnswerCorrect = correct
        showResult        = true
        totalAnswered    += 1
        lastCardID        = item.card.id

        guard let idx = queue.firstIndex(where: { $0.id == item.id }) else { return }

        if correct {
            totalCorrect += 1
            queue[idx].correctCount += 1
            if queue[idx].correctCount >= config.requiredCorrect {
                queue[idx].isComplete = true
                completedCount += 1
                if let next = pendingCards.first {
                    pendingCards.removeFirst()
                    queue.append(SessionItem(card: next))
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
        showResult  = false
        currentItem = nextItem()
        if config.mode == .quiz { buildQuizOptions() }
    }

    // MARK: - Quiz options

    private func buildQuizOptions() {
        guard let item = currentItem else { quizOptions = []; return }
        let correct = config.direction == .backToFront ? item.card.front : item.card.back

        var pool = deck.cards
            .filter { $0.id != item.card.id }
            .map { config.direction == .backToFront ? $0.front : $0.back }
        pool.shuffle()
        var options = Array(pool.prefix(3))
        options.append(correct)
        options.shuffle()
        quizOptions = options
    }

    // MARK: - Result

    func buildResult() -> SessionResult {
        SessionResult(
            deckID:       deck.id,
            duration:     Date().timeIntervalSince(startTime),
            mode:         config.mode,
            totalAnswered: totalAnswered,
            totalCorrect:  totalCorrect,
            wrongCardIDs:  wrongCardIDs
        )
    }

    // MARK: - Display helpers

    var currentFront: String {
        guard let item = currentItem else { return "" }
        return config.direction == .backToFront ? item.card.back : item.card.front
    }

    var currentBack: String {
        guard let item = currentItem else { return "" }
        return config.direction == .backToFront ? item.card.front : item.card.back
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

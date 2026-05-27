import Foundation
  import Combine

  class QuizViewModel: ObservableObject {

      enum Phase: Equatable {
          case question
          case flashcardRevealed
          case srsRevealed
          case revealed(correct: Bool)
          case batchComplete(correct: Int, total: Int)
          case wrongWordsOffer
          case allDone
      }

      @Published var phase: Phase = .question
      @Published var currentCard: QuizCard?
      @Published var currentOptions: [String] = []
      @Published var lastSelectedOption: String = ""
      @Published var progress: Double = 0
      @Published var batchIndex: Int = 1
      @Published var totalBatches: Int = 1

      @Published var sessionCorrect: Int = 0
      @Published var sessionTotal: Int   = 0
      @Published var currentStreak: Int  = 0
      @Published var bestStreak: Int     = 0

      let settings: QuizSettings
      let wordList: WordList

      private let historicalWordStats: [UUID: WordStats]
      private var sessionWordStats: [UUID: WordStats] = [:]
      private let sessionStartTime = Date()

      private var allCards: [QuizCard]    = []
      private var activeCards: [QuizCard] = []
      private var cardQueue: [UUID]       = []
      private var wrongCardIDs: Set<UUID> = []
      private var requiredCorrect: Int

      var wrongWordsCount: Int { wrongCardIDs.count }
      var isSRS: Bool { settings.studyMode == .srs }
      private var effectiveBatchSize: Int { isSRS ? max(1, allCards.count) :
  settings.batchSize }

      init(wordList: WordList, settings: QuizSettings, wordStats: [UUID: WordStats] =
  [:]) {
          self.wordList            = wordList
          self.settings            = settings
          self.requiredCorrect     = settings.requiredCorrect
          self.historicalWordStats = wordStats
          setupSession()
      }

      var quizMode: QuizMode { settings.mode }

      private func setupSession() {
          let baseCards = wordList.pairs.map { pair in
              QuizCard(pair: pair, direction: settings.direction,
                       historicalStats: historicalWordStats[pair.id])
          }

          if isSRS {
              allCards     = baseCards.filter { historicalWordStats[$0.id]?.isDue ??
  true }.shuffled()
              totalBatches = 1
              if allCards.isEmpty { phase = .allDone; return }
          } else if settings.shuffleOrder {
              let due    = baseCards.filter { historicalWordStats[$0.id]?.isDue ??
  true }
              let notDue = baseCards.filter { !(historicalWordStats[$0.id]?.isDue ??
  true) }

              let dueHard   = due.filter { $0.difficultyTier == 0 }.shuffled()
              let dueMedium = due.filter { $0.difficultyTier == 1 }.shuffled()
              let dueEasy   = due.filter { $0.difficultyTier == 2 }.shuffled()

              let notDueSorted = notDue.sorted {
                  let d0 = historicalWordStats[$0.id]?.dueDate ?? .distantFuture
                  let d1 = historicalWordStats[$1.id]?.dueDate ?? .distantFuture
                  return d0 < d1
              }

              allCards     = dueHard + dueMedium + dueEasy + notDueSorted
              totalBatches = max(1, Int(ceil(Double(allCards.count) /
  Double(settings.batchSize))))
          } else {
              allCards     = baseCards
              totalBatches = max(1, Int(ceil(Double(allCards.count) /
  Double(settings.batchSize))))
          }

          loadNextBatch()
      }

      private func loadNextBatch() {
          let size  = effectiveBatchSize
          let start = (batchIndex - 1) * size
          let end   = min(start + size, allCards.count)
          guard start < allCards.count else {
              phase = (!isSRS && !wrongCardIDs.isEmpty) ? .wrongWordsOffer : .allDone
              return
          }
          activeCards = Array(allCards[start..<end])
          buildQueue()
          showNextCard()
      }

      private func buildQueue() {
          if isSRS {
              cardQueue = activeCards.map { $0.id }
          } else {
              let hard   = activeCards.filter { $0.difficultyTier == 0 }.shuffled()
              let medium = activeCards.filter { $0.difficultyTier == 1 }.shuffled()
              let easy   = activeCards.filter { $0.difficultyTier == 2 }.shuffled()
              cardQueue = (hard + medium + easy).map { $0.id }
          }
      }

      private func showNextCard() {
          cardQueue.removeAll { id in
              (activeCards.first(where: { $0.id == id })?.stats.correctStreak ?? 0) >=
   requiredCorrect
          }

          guard !cardQueue.isEmpty else {
              if isSRS {
                  phase = .allDone
              } else {
                  let batchCorrect = activeCards.reduce(0) { $0 +
  $1.stats.totalCorrect }
                  let batchTotal   = activeCards.reduce(0) { $0 +
  $1.stats.totalAttempts }
                  phase = .batchComplete(correct: batchCorrect, total: batchTotal)
              }
              return
          }

          let nextID = cardQueue.removeFirst()
          guard let next = activeCards.first(where: { $0.id == nextID }) else {
              showNextCard()
              return
          }

          currentCard = next
          if settings.mode == .multipleChoice && !isSRS {
              currentOptions = generateOptions(for: next)
          }
          updateProgress()
          phase = .question
      }

      // MARK: - SRS mode

      func srsReveal() {
          guard phase == .question else { return }
          phase = .srsRevealed
      }

      func rateSRS(rating: SRSRating) {
          guard case .srsRevealed = phase, let card = currentCard else { return }

          let prev   = historicalWordStats[card.id]
          let result = SRSEngine.next(
              repetitions: prev?.srsRepetitions ?? 0,
              easeFactor:  prev?.srsEaseFactor  ?? 2.5,
              interval:    max(1, prev?.interval ?? 1),
              rating:      rating
          )

          let isCorrect = (rating != .again)

          var ws = sessionWordStats[card.id] ?? WordStats()
          ws.attempts      += 1
          if isCorrect { ws.correct += 1 }
          ws.interval        = result.interval
          ws.srsRepetitions  = result.repetitions
          ws.srsEaseFactor   = result.easeFactor
          ws.lastSeen        = Date()
          sessionWordStats[card.id] = ws

          sessionTotal += 1
          if isCorrect {
              sessionCorrect += 1
              currentStreak  += 1
              bestStreak      = max(bestStreak, currentStreak)
          } else {
              currentStreak = 0
              wrongCardIDs.insert(card.id)
          }

          if let idx = activeCards.firstIndex(where: { $0.id == card.id }) {
              activeCards[idx].stats.correctStreak = requiredCorrect
          }

          updateProgress()
          showNextCard()
      }

      // MARK: - Flashcard mode

      func flashcardReveal() {
          guard phase == .question else { return }
          phase = .flashcardRevealed
      }

      func flashcardAnswer(knew: Bool) {
          guard case .flashcardRevealed = phase, let card = currentCard else { return
  }
          recordAnswer(card: card, isCorrect: knew)
          phase = .revealed(correct: knew)
      }

      // MARK: - Typing mode

      func submitAnswer(userInput: String) {
          guard let card = currentCard else { return }
          let normalize: (String) -> String = { $0.trimmingCharacters(in:
  .whitespaces).lowercased() }
          let alternatives = card.answerText.components(separatedBy: "/").map {
  normalize($0) }
          let isCorrect = alternatives.contains(normalize(userInput))
          recordAnswer(card: card, isCorrect: isCorrect)
          phase = .revealed(correct: isCorrect)
      }

      // MARK: - Multiple choice mode

      func selectOption(_ option: String) {
          guard let card = currentCard else { return }
          lastSelectedOption = option
          let normalize: (String) -> String = { $0.trimmingCharacters(in:
  .whitespaces).lowercased() }
          let alternatives = card.answerText.components(separatedBy: "/").map {
  normalize($0) }
          let isCorrect = alternatives.contains(normalize(option))
          recordAnswer(card: card, isCorrect: isCorrect)
          phase = .revealed(correct: isCorrect)
      }

      private func generateOptions(for card: QuizCard) -> [String] {
          let correct = card.answerText
          let useFront = card.questionText == card.pair.front
          let pool = wordList.pairs
              .filter { $0.id != card.pair.id }
              .map { useFront ? $0.back : $0.front }
              .filter { $0 != correct }
          let wrong = Array(Set(pool).shuffled().prefix(3))
          return ([correct] + wrong).shuffled()
      }

      // MARK: - Shared answer recording

      private func recordAnswer(card: QuizCard, isCorrect: Bool) {
          if let idx = activeCards.firstIndex(where: { $0.id == card.id }) {
              activeCards[idx].stats.totalAttempts += 1
              if isCorrect {
                  activeCards[idx].stats.correctStreak += 1
                  activeCards[idx].stats.totalCorrect  += 1
              } else {
                  activeCards[idx].stats.correctStreak = 0
                  wrongCardIDs.insert(card.id)
              }
              currentCard = activeCards[idx]

              let updatedStreak = activeCards[idx].stats.correctStreak
              if updatedStreak < requiredCorrect {
                  if !isCorrect {
                      let lo  = min(2, cardQueue.count)
                      let hi  = min(4, cardQueue.count)
                      let pos = lo <= hi ? Int.random(in: lo...hi) : lo
                      cardQueue.insert(card.id, at: pos)
                  } else {
                      cardQueue.append(card.id)
                  }
              }
          }

          var ws = sessionWordStats[card.id] ?? WordStats()
          ws.attempts += 1
          if isCorrect {
              ws.correct += 1
              let prev = historicalWordStats[card.id]?.interval ?? 0
              ws.interval = min(30, prev == 0 ? 1 : prev * 2)
          } else {
              ws.interval = 0
          }
          ws.lastSeen = Date()
          sessionWordStats[card.id] = ws

          sessionTotal += 1
          if isCorrect {
              sessionCorrect += 1
              currentStreak  += 1
              bestStreak      = max(bestStreak, currentStreak)
          } else {
              currentStreak = 0
          }
      }

      func advanceAfterReveal() {
          guard case .revealed = phase else { return }
          showNextCard()
      }

      func advanceBatch() {
          batchIndex += 1
          loadNextBatch()
      }

      // MARK: - Wrong words review

      func startWrongWordsReview() {
          let wrongIDs = wrongCardIDs
          let wrongCards = wordList.pairs
              .filter { wrongIDs.contains($0.id) }
              .map { QuizCard(pair: $0, direction: settings.direction,
                              historicalStats: historicalWordStats[$0.id]) }
          guard !wrongCards.isEmpty else { phase = .allDone; return }

          allCards     = wrongCards
          totalBatches = max(1, Int(ceil(Double(allCards.count) /
  Double(settings.batchSize))))
          batchIndex   = 1
          activeCards  = []
          cardQueue    = []
          wrongCardIDs = []
          loadNextBatch()
      }

      func skipWrongWordsReview() {
          phase = .allDone
      }

      func buildResult() -> QuizResult {
          QuizResult(
              listID:     wordList.id,
              correct:    sessionCorrect,
              total:      sessionTotal,
              bestStreak: bestStreak,
              wordStats:  sessionWordStats,
              date:       Date(),
              duration:   Date().timeIntervalSince(sessionStartTime)
          )
      }

      private func updateProgress() {
          let done = activeCards.filter { $0.stats.correctStreak >= requiredCorrect
  }.count
          progress = activeCards.isEmpty ? 0 : Double(done) /
  Double(activeCards.count)
      }
  }

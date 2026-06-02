import Foundation
import Combine

class LibraryViewModel: ObservableObject {
    @Published var decks: [Deck]             = []
    @Published var folders: [DeckFolder]     = []
    @Published var deckStats: [UUID: DeckStats] = [:]
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let decksKey   = "ms_decks"
    private let foldersKey = "ms_folders"
    private let statsKey   = "ms_stats"
    private let syncDateKey = "ms_syncDate"

    // iCloud sync
    private let cloud = NSUbiquitousKeyValueStore.default
    private var isApplyingCloud = false

    init() {
        load()
        // Pull from iCloud if it has newer data than local
        mergeFromCloudIfNewer()
        // Observe external iCloud changes (other devices)
        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudChanged(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud)
        cloud.synchronize()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Deck CRUD

    func addDeck(name: String, folderID: UUID? = nil) {
        var d = Deck(name: name)
        d.folderID  = folderID
        d.sortOrder = decks.count
        decks.append(d)
        save()
    }

    func deleteDeck(id: UUID) {
        decks.removeAll { $0.id == id }
        deckStats.removeValue(forKey: id)
        // also delete linked temporary decks
        decks.removeAll { $0.parentDeckID == id }
        save()
    }

    func renameDeck(id: UUID, name: String) {
        guard let i = decks.firstIndex(where: { $0.id == id }) else { return }
        decks[i].name = name
        save()
    }

    func moveDeck(id: UUID, toFolder folderID: UUID?) {
        guard let i = decks.firstIndex(where: { $0.id == id }) else { return }
        decks[i].folderID = folderID
        // keep the linked temporary deck in the same folder
        if let ti = decks.firstIndex(where: { $0.parentDeckID == id && $0.isTemporary }) {
            decks[ti].folderID = folderID
        }
        save()
    }

    func updateDeck(_ deck: Deck) {
        guard let i = decks.firstIndex(where: { $0.id == deck.id }) else { return }
        decks[i] = deck
        save()
    }

    func moveDecks(from source: IndexSet, to dest: Int) {
        decks.move(fromOffsets: source, toOffset: dest)
        for (i, _) in decks.enumerated() { decks[i].sortOrder = i }
        save()
    }

    // MARK: - Card CRUD

    func addCard(_ card: Card, toDeck deckID: UUID) {
        guard let i = decks.firstIndex(where: { $0.id == deckID }) else { return }
        decks[i].cards.append(card)
        save()
    }

    func updateCard(_ card: Card, inDeck deckID: UUID) {
        guard let di = decks.firstIndex(where: { $0.id == deckID }),
              let ci = decks[di].cards.firstIndex(where: { $0.id == card.id }) else { return }
        decks[di].cards[ci] = card
        save()
    }

    func deleteCard(id: UUID, fromDeck deckID: UUID) {
        guard let di = decks.firstIndex(where: { $0.id == deckID }) else { return }
        decks[di].cards.removeAll { $0.id == id }
        deckStats[deckID]?.cardStats.removeValue(forKey: id)
        save()
    }

    // MARK: - Folder CRUD

    func addFolder(name: String) {
        folders.append(DeckFolder(name: name, sortOrder: folders.count))
        save()
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        // move decks out of deleted folder
        for i in decks.indices where decks[i].folderID == id {
            decks[i].folderID = nil
        }
        save()
    }

    func renameFolder(id: UUID, name: String) {
        guard let i = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[i].name = name
        save()
    }

    // MARK: - Import

    func importFromURL(_ url: URL, folderID: UUID? = nil, name: String? = nil) {
        do {
            let cards = try FileParser.parse(url: url)
            let n = name ?? url.deletingPathExtension().lastPathComponent
            var deck = Deck(name: n, cards: cards)
            deck.folderID = folderID
            decks.append(deck)
            save()
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
        }
    }

    func importFromText(_ text: String, name: String, folderID: UUID? = nil) {
        do {
            let cards = try FileParser.parse(text: text)
            var deck = Deck(name: name, cards: cards)
            deck.folderID = folderID
            decks.append(deck)
            save()
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
        }
    }

    // MARK: - Statistics

    func recordSession(result: SessionResult, settings: SettingsViewModel) {
        let srsEnabled = settings.srsEnabled
        let profile    = settings.settings.tempoProfile

        var stat = deckStats[result.deckID] ?? DeckStats(deckID: result.deckID)
        stat.apply(result)

        // Update per-card stats
        for card in deck(id: result.deckID)?.cards ?? [] {
            let wasCorrect = !result.wrongCardIDs.contains(card.id)
            var cs = stat.cardStats[card.id] ?? CardStats()
            cs.attempts += 1
            if wasCorrect {
                cs.correct += 1
                cs.consecutiveCorrect += 1
            } else {
                cs.consecutiveCorrect = 0
            }
            cs.lastAnswered = result.date
            // SRS update only for cards actually answered this session
            if srsEnabled, let adjusted = result.cardAdjustedTimes[card.id] {
                let rating = SRSRating.from(correct: wasCorrect, adjusted: adjusted,
                                            median: profile.median, calibrated: profile.isCalibrated)
                cs = SRSEngine.update(cs, rating: rating)
            }
            stat.cardStats[card.id] = cs
        }

        // Feed the user's tempo profile (calibration runs over first sessions)
        settings.recordCalibration(result.correctAdjustedTimes)

        deckStats[result.deckID] = stat

        // Update lastStudied
        if let i = decks.firstIndex(where: { $0.id == result.deckID }) {
            decks[i].lastStudied = result.date
        }

        // Handle wrong cards → temporary deck
        if !result.wrongCardIDs.isEmpty {
            updateTemporaryDeck(for: result.deckID, wrongCardIDs: result.wrongCardIDs, stat: &stat)
        }

        // Remove cards from temp deck that hit 3 consecutive correct
        if let parentID = deck(id: result.deckID)?.parentDeckID {
            cleanTemporaryDeck(id: result.deckID, parentID: parentID)
        }

        save()
    }

    private func updateTemporaryDeck(for parentID: UUID, wrongCardIDs: Set<UUID>, stat: inout DeckStats) {
        guard let parent = deck(id: parentID) else { return }
        let wrongCards = parent.cards.filter { wrongCardIDs.contains($0.id) }

        if let tempIdx = decks.firstIndex(where: { $0.parentDeckID == parentID && $0.isTemporary }) {
            // Add new wrong cards not already in temp deck
            let existing = Set(decks[tempIdx].cards.map { $0.id })
            let newCards  = wrongCards.filter { !existing.contains($0.id) }
            decks[tempIdx].cards.append(contentsOf: newCards)
        } else {
            // Create new temp deck
            var temp = Deck(name: parent.name, cards: wrongCards)
            temp.isTemporary  = true
            temp.parentDeckID = parentID
            temp.folderID     = parent.folderID
            decks.append(temp)
        }
    }

    private func cleanTemporaryDeck(id: UUID, parentID: UUID) {
        guard let tempIdx = decks.firstIndex(where: { $0.id == id }) else { return }
        let parentStat = deckStats[parentID] ?? DeckStats(deckID: parentID)

        decks[tempIdx].cards.removeAll { card in
            (parentStat.cardStats[card.id]?.consecutiveCorrect ?? 0) >= 3
        }

        if decks[tempIdx].cards.isEmpty {
            decks.remove(at: tempIdx)
        }
    }

    // MARK: - Stats helpers

    func deck(id: UUID) -> Deck? { decks.first { $0.id == id } }

    func stats(for deckID: UUID) -> DeckStats { deckStats[deckID] ?? DeckStats(deckID: deckID) }

    func srueDueCount(for deck: Deck) -> Int {
        let cs = deckStats[deck.id]?.cardStats ?? [:]
        return deck.cards.filter { cs[$0.id]?.isDue ?? true }.count
    }

    func deleteStats(for deckID: UUID) {
        deckStats.removeValue(forKey: deckID)
        if let i = decks.firstIndex(where: { $0.id == deckID }) {
            decks[i].lastStudied = nil
        }
        save()
    }

    // MARK: - Global stats (for StatisticsView)

    var bestStreak: Int {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        var allDates = Set<String>()
        for s in deckStats.values { for r in s.sessions { allDates.insert(fmt.string(from: r.date)) } }
        let cal = Calendar.current
        let sorted = allDates.compactMap { fmt.date(from: $0) }.sorted()
        var best = 0, current = 0
        for (i, date) in sorted.enumerated() {
            if i == 0 { current = 1 }
            else { current = cal.dateComponents([.day], from: sorted[i-1], to: date).day == 1 ? current + 1 : 1 }
            best = max(best, current)
        }
        return best
    }

    var studyStreak: Int {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        var allDates = Set<String>()
        for s in deckStats.values { for r in s.sessions { allDates.insert(fmt.string(from: r.date)) } }
        var streak = 0
        var day    = Date()
        if !allDates.contains(fmt.string(from: day)) {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? .distantPast
        }
        while allDates.contains(fmt.string(from: day)) {
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? .distantPast
        }
        return streak
    }

    var overallAccuracy: Double {
        let total   = deckStats.values.reduce(0) { $0 + $1.totalAnswers }
        let correct = deckStats.values.reduce(0) { $0 + $1.totalCorrect }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var totalSessions: Int { deckStats.values.reduce(0) { $0 + $1.totalSessions } }

    var allSessions: [SessionRecord] {
        deckStats.values.flatMap { $0.sessions }
            .sorted { $0.date > $1.date }
    }

    var lastStudiedEntry: (deck: Deck, accuracy: Double)? {
        decks
            .filter { !$0.isTemporary }
            .compactMap { d -> (Deck, Double, Date)? in
                guard let date = d.lastStudied else { return nil }
                return (d, deckStats[d.id]?.overallAccuracy ?? 0, date)
            }
            .max { $0.2 < $1.2 }
            .map { ($0.0, $0.1) }
    }

    var todayMinutes: Double {
        allSessions
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.duration } / 60
    }

    // MARK: - Persistence

    func save() {
        let decksData   = try? JSONEncoder().encode(decks)
        let foldersData = try? JSONEncoder().encode(folders)
        let statsData   = try? JSONEncoder().encode(deckStats)

        if let d = decksData   { UserDefaults.standard.set(d, forKey: decksKey) }
        if let d = foldersData { UserDefaults.standard.set(d, forKey: foldersKey) }
        if let d = statsData   { UserDefaults.standard.set(d, forKey: statsKey) }

        // Don't push to iCloud while applying a cloud change (avoids ping-pong)
        guard !isApplyingCloud else { return }
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: syncDateKey)
        if let d = decksData   { cloud.set(d, forKey: decksKey) }
        if let d = foldersData { cloud.set(d, forKey: foldersKey) }
        if let d = statsData   { cloud.set(d, forKey: statsKey) }
        cloud.set(now, forKey: syncDateKey)
        cloud.synchronize()
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: decksKey),
           let v = try? JSONDecoder().decode([Deck].self, from: d)         { decks     = v }
        if let d = UserDefaults.standard.data(forKey: foldersKey),
           let v = try? JSONDecoder().decode([DeckFolder].self, from: d)   { folders   = v }
        if let d = UserDefaults.standard.data(forKey: statsKey),
           let v = try? JSONDecoder().decode([UUID: DeckStats].self, from: d) { deckStats = v }
    }

    // MARK: - iCloud sync

    private func mergeFromCloudIfNewer() {
        let cloudDate = cloud.double(forKey: syncDateKey)
        let localDate = UserDefaults.standard.double(forKey: syncDateKey)
        guard cloudDate > localDate, cloudDate > 0 else { return }
        applyCloudData()
    }

    @objc private func cloudChanged(_ note: Notification) {
        // External change from another device — pull if newer
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let cloudDate = self.cloud.double(forKey: self.syncDateKey)
            let localDate = UserDefaults.standard.double(forKey: self.syncDateKey)
            guard cloudDate > localDate else { return }
            self.applyCloudData()
        }
    }

    private func applyCloudData() {
        isApplyingCloud = true
        defer { isApplyingCloud = false }

        if let d = cloud.data(forKey: decksKey),
           let v = try? JSONDecoder().decode([Deck].self, from: d)            { decks = v }
        if let d = cloud.data(forKey: foldersKey),
           let v = try? JSONDecoder().decode([DeckFolder].self, from: d)      { folders = v }
        if let d = cloud.data(forKey: statsKey),
           let v = try? JSONDecoder().decode([UUID: DeckStats].self, from: d) { deckStats = v }

        // Mirror to local storage + sync timestamp (no re-push to cloud)
        save()
        let cloudDate = cloud.double(forKey: syncDateKey)
        UserDefaults.standard.set(cloudDate, forKey: syncDateKey)
    }
}

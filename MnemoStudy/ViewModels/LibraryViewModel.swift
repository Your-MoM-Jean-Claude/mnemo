import Foundation
import Combine

class LibraryViewModel: ObservableObject {
    @Published var decks: [Deck]             = []
    @Published var folders: [DeckFolder]     = []
    @Published var deckStats: [UUID: DeckStats] = [:]
    @Published var dayStats: [String: DayStat]  = [:]
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let decksKey    = "ms_decks"
    private let foldersKey  = "ms_folders"
    private let statsKey    = "ms_stats"
    private let daysKey     = "ms_days"
    private let syncDateKey = "ms_syncDate"
    private let touchedKey  = "ms_userTouched"

    static let maxDeckNameLength = 120
    static let maxStoredDays     = 730

    // iCloud sync
    private let cloud = NSUbiquitousKeyValueStore.default
    private var isApplyingCloud = false
    private var isBatching      = false

    /// True once the user has made any change of their own on this device. Until
    /// then the local library is just the built-in starter content and iCloud
    /// always wins — that is what stops a late-arriving cloud sync from being
    /// overwritten by the seed on a fresh install.
    private var hasUserData: Bool {
        get { UserDefaults.standard.bool(forKey: touchedKey) }
        set { UserDefaults.standard.set(newValue, forKey: touchedKey) }
    }

    /// Whether a library blob exists on disk at all — checked as raw bytes, not
    /// as a successful decode, so a blob we failed to read is never mistaken for
    /// "new install" and seeded over.
    var hasStoredLibrary: Bool {
        UserDefaults.standard.data(forKey: decksKey) != nil
    }

    init() {
        load()
        mergeFromCloudIfNewer()
        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudChanged(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud)
        cloud.synchronize()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Deck CRUD

    private func clamped(_ name: String) -> String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(t.prefix(LibraryViewModel.maxDeckNameLength))
    }

    func addDeck(name: String, folderID: UUID? = nil) {
        var d = Deck(name: clamped(name))
        d.folderID  = folderID
        d.sortOrder = decks.count
        decks.append(d)
        save()
    }

    func deleteDeck(id: UUID) {
        // Drop the deck, its linked temp deck, and BOTH of their stats — leaving
        // stats behind kept the iCloud payload growing after every deletion.
        let linked = decks.filter { $0.parentDeckID == id }.map { $0.id }
        for orphan in linked { deckStats.removeValue(forKey: orphan) }
        deckStats.removeValue(forKey: id)
        decks.removeAll { $0.id == id || $0.parentDeckID == id }
        save()
    }

    func renameDeck(id: UUID, name: String) {
        guard let i = decks.firstIndex(where: { $0.id == id }) else { return }
        decks[i].name = clamped(name)
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
        var d = deck
        d.name = clamped(d.name)
        decks[i] = d
        // Cards removed by the editor must not leave their stats behind.
        pruneCardStats(forDeck: d)
        save()
    }

    func moveDecks(from source: IndexSet, to dest: Int) {
        decks.move(fromOffsets: source, toOffset: dest)
        for (i, _) in decks.enumerated() { decks[i].sortOrder = i }
        save()
    }

    private func pruneCardStats(forDeck deck: Deck) {
        guard var stat = deckStats[deck.id] else { return }
        let live = Set(deck.cards.map { $0.id })
        stat.cardStats = stat.cardStats.filter { live.contains($0.key) }
        deckStats[deck.id] = stat
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
        folders.append(DeckFolder(name: clamped(name), sortOrder: folders.count))
        save()
    }

    func deleteFolder(id: UUID) {
        // Delete the folder AND everything inside it (decks + their temp decks + stats)
        let insideIDs = decks.filter { $0.folderID == id }.map { $0.id }
        for deckID in insideIDs {
            deckStats.removeValue(forKey: deckID)
            for orphan in decks.filter({ $0.parentDeckID == deckID }) {
                deckStats.removeValue(forKey: orphan.id)
            }
            decks.removeAll { $0.parentDeckID == deckID }   // linked temp decks
        }
        decks.removeAll { $0.folderID == id }
        folders.removeAll { $0.id == id }
        save()
    }

    func renameFolder(id: UUID, name: String) {
        guard let i = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[i].name = clamped(name)
        save()
    }

    func moveFolder(id: UUID, before targetID: UUID) {
        guard id != targetID,
              let from = folders.firstIndex(where: { $0.id == id }) else { return }
        let f = folders.remove(at: from)
        let insertAt = folders.firstIndex(where: { $0.id == targetID }) ?? folders.count
        folders.insert(f, at: insertAt)
        for i in folders.indices { folders[i].sortOrder = i }
        save()
    }

    // Reorder a deck to sit before targetID; also adopts the target's folder
    // (so dragging onto a standalone deck moves it out of its folder).
    func reorderDeck(id: UUID, before targetID: UUID) {
        guard id != targetID,
              let from = decks.firstIndex(where: { $0.id == id }),
              let target = decks.first(where: { $0.id == targetID }) else { return }
        var d = decks.remove(at: from)
        let targetFolder = target.folderID
        d.folderID = targetFolder
        if let ti = decks.firstIndex(where: { $0.parentDeckID == id && $0.isTemporary }) {
            decks[ti].folderID = targetFolder
        }
        let insertAt = decks.firstIndex(where: { $0.id == targetID }) ?? decks.count
        decks.insert(d, at: insertAt)
        save()
    }

    // MARK: - Import

    /// Max accepted import size. A .txt of word pairs is a few tens of KB; this
    /// only exists to stop a multi-MB file being read wholly into memory.
    static let maxImportBytes = 4 * 1024 * 1024

    @discardableResult
    func importFromURL(_ url: URL, folderID: UUID? = nil, name: String? = nil) -> Bool {
        clearError()
        do {
            let cards = try FileParser.parse(url: url)
            let n = clamped(name ?? url.deletingPathExtension().lastPathComponent)
            var deck = Deck(name: n.isEmpty ? "Import" : n, cards: cards)
            deck.folderID = folderID
            decks.append(deck)
            save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
            return false
        }
    }

    @discardableResult
    func importFromText(_ text: String, name: String, folderID: UUID? = nil) -> Bool {
        clearError()
        do {
            let cards = try FileParser.parse(text: text)
            var deck = Deck(name: clamped(name), cards: cards)
            deck.folderID = folderID
            decks.append(deck)
            save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
            return false
        }
    }

    /// Import used to leave `errorMessage` set forever after the first failure,
    /// so every later import looked like it had failed too.
    func clearError() {
        errorMessage = nil
        showError    = false
    }

    // MARK: - Daily review (all due across decks)

    static let reviewSessionCap = 40

    // Cards already learned (have a due date) whose review is due now, across
    // all real (non-temporary) decks. Returns each card with its origin deck id.
    // New/never-studied cards are NOT included — those are learned via normal study.
    func dueReviewCards() -> [(card: Card, deckID: UUID)] {
        let now = Date()
        var result: [(Card, UUID, Date)] = []
        for d in decks where !d.isTemporary {
            let cs = deckStats[d.id]?.cardStats ?? [:]
            for card in d.cards {
                if let due = cs[card.id]?.srsDueDate, due <= now {
                    result.append((card, d.id, due))
                }
            }
        }
        return result.sorted { $0.2 < $1.2 }                       // most overdue first
            .prefix(LibraryViewModel.reviewSessionCap)
            .map { (card: $0.0, deckID: $0.1) }
    }

    /// Cheap count that must agree with `dueReviewCards()` — walking the decks
    /// without building and sorting the whole card list.
    var dueReviewCount: Int {
        let now = Date()
        var n = 0
        for d in decks where !d.isTemporary {
            guard let cs = deckStats[d.id]?.cardStats else { continue }
            for card in d.cards {
                if let due = cs[card.id]?.srsDueDate, due <= now { n += 1 }
            }
        }
        return min(n, LibraryViewModel.reviewSessionCap)
    }

    // Split a combined review result back into per-origin-deck results so each
    // deck's stats & SRS update correctly. Calibration runs once at the end.
    func recordReviewSession(result: SessionResult, origins: [UUID: UUID], settings: SettingsViewModel) {
        let byDeck = Dictionary(grouping: result.cardAdjustedTimes.keys) { origins[$0] ?? UUID() }
        isBatching = true
        for (deckID, cardIDs) in byDeck {
            guard decks.contains(where: { $0.id == deckID }) else { continue }
            var times: [UUID: Double] = [:]
            var wrong: Set<UUID> = []
            for id in cardIDs {
                times[id] = result.cardAdjustedTimes[id]
                if result.wrongCardIDs.contains(id) { wrong.insert(id) }
            }
            let sub = SessionResult(
                deckID: deckID, date: result.date, duration: result.duration / Double(byDeck.count),
                mode: result.mode, totalAnswered: cardIDs.count,
                totalCorrect: cardIDs.count - wrong.count,
                wrongCardIDs: wrong, cardAdjustedTimes: times)
            recordSession(result: sub, settings: settings, calibrate: false, countDay: false)
        }
        isBatching = false
        recordDay(result.date, minutes: result.duration / 60)
        settings.recordCalibration(result.correctAdjustedTimes)
        save()
    }

    func recordSession(result: SessionResult, settings: SettingsViewModel,
                       calibrate: Bool = true, countDay: Bool = true) {
        let srsEnabled = settings.srsActive
        let profile    = settings.settings.tempoProfile

        var stat = deckStats[result.deckID] ?? DeckStats(deckID: result.deckID)
        stat.apply(result)

        // Update per-card stats — ONLY for cards actually answered this session.
        // (A card is answered iff it has a recorded response time. Cards merely
        // present in the deck but not studied must not be counted.)
        for card in deck(id: result.deckID)?.cards ?? [] {
            guard let adjusted = result.cardAdjustedTimes[card.id] else { continue }
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
            if srsEnabled {
                let rating = SRSRating.from(correct: wasCorrect, adjusted: adjusted,
                                            median: profile.median, calibrated: profile.isCalibrated)
                cs = SRSEngine.update(cs, rating: rating)
            }
            stat.cardStats[card.id] = cs
        }

        // Feed the user's tempo profile (calibration runs over first sessions)
        if calibrate { settings.recordCalibration(result.correctAdjustedTimes) }

        deckStats[result.deckID] = stat
        // One review session that spans five decks is still one session. Letting
        // each per-deck sub-result record its own day entry multiplied the day's
        // session count by the number of decks involved.
        if countDay { recordDay(result.date, minutes: result.duration / 60) }

        // Update lastStudied
        if let i = decks.firstIndex(where: { $0.id == result.deckID }) {
            decks[i].lastStudied = result.date
        }

        // Handle wrong cards → temporary deck
        if !result.wrongCardIDs.isEmpty {
            updateTemporaryDeck(for: result.deckID, wrongCardIDs: result.wrongCardIDs)
        }

        // If this WAS a temp deck, remove cards answered correctly 3× in a row
        if deck(id: result.deckID)?.parentDeckID != nil {
            cleanTemporaryDeck(id: result.deckID)
        }

        save()
    }

    private func recordDay(_ date: Date, minutes: Double) {
        let key = DayKey.string(from: date)
        var d = dayStats[key] ?? DayStat()
        d.sessions += 1
        d.minutes  += minutes
        dayStats[key] = d
        trimDayStats()
    }

    private func trimDayStats() {
        guard dayStats.count > LibraryViewModel.maxStoredDays else { return }
        let keep = dayStats.keys.sorted().suffix(LibraryViewModel.maxStoredDays)
        dayStats = dayStats.filter { keep.contains($0.key) }
    }

    private func updateTemporaryDeck(for parentID: UUID, wrongCardIDs: Set<UUID>) {
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

    private func cleanTemporaryDeck(id: UUID) {
        guard let tempIdx = decks.firstIndex(where: { $0.id == id }) else { return }
        // Use the temp deck's OWN stats — that's where studying it records progress.
        let tempStat = deckStats[id] ?? DeckStats(deckID: id)

        decks[tempIdx].cards.removeAll { card in
            (tempStat.cardStats[card.id]?.consecutiveCorrect ?? 0) >= 3
        }

        if decks[tempIdx].cards.isEmpty {
            decks.remove(at: tempIdx)
            deckStats.removeValue(forKey: id)
        }
    }

    // MARK: - Stats helpers

    func deck(id: UUID) -> Deck? { decks.first { $0.id == id } }

    // User-created decks (excludes built-in bundled decks and temp decks)
    var customDeckCount: Int { decks.filter { !$0.isTemporary && !$0.isBundled }.count }

    func stats(for deckID: UUID) -> DeckStats { deckStats[deckID] ?? DeckStats(deckID: deckID) }

    /// Cards this deck has scheduled for review today. Deliberately counts only
    /// cards SRS has actually scheduled, matching `dueReviewCards()` — the old
    /// version treated every never-studied card as due, so the badge advertised
    /// "50 due today" while the review button offered nothing.
    func dueCount(for deck: Deck) -> Int {
        guard let cs = deckStats[deck.id]?.cardStats else { return 0 }
        let now = Date()
        return deck.cards.filter { card in
            guard let due = cs[card.id]?.srsDueDate else { return false }
            return due <= now
        }.count
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
        let sorted = dayStats.keys.compactMap { DayKey.date(from: $0) }.sorted()
        var best = 0, current = 0
        for (i, date) in sorted.enumerated() {
            if i == 0 { current = 1 }
            else {
                let gap = DayKey.calendar.dateComponents([.day], from: sorted[i-1], to: date).day
                current = gap == 1 ? current + 1 : 1
            }
            best = max(best, current)
        }
        return best
    }

    var studyStreak: Int {
        let days = Set(dayStats.keys)
        var streak = 0
        var day = Date()
        if !days.contains(DayKey.string(from: day)) {
            guard let y = DayKey.calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = y
        }
        while days.contains(DayKey.string(from: day)) {
            streak += 1
            guard let p = DayKey.calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = p
        }
        return streak
    }

    /// Session counts for the last 7 days, oldest first.
    var weeklyCounts: [Int] {
        (0..<7).map { offset in
            guard let day = DayKey.calendar.date(byAdding: .day, value: -(6 - offset), to: Date())
            else { return 0 }
            return dayStats[DayKey.string(from: day)]?.sessions ?? 0
        }
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
        dayStats[DayKey.string(from: Date())]?.minutes ?? 0
    }

    // MARK: - Persistence

    func save(pushToCloud: Bool = true) {
        guard !isBatching || !pushToCloud else { return }

        let decksData   = try? JSONEncoder().encode(decks)
        let foldersData = try? JSONEncoder().encode(folders)
        let statsData   = try? JSONEncoder().encode(deckStats)
        let daysData    = try? JSONEncoder().encode(dayStats)

        if let d = decksData   { UserDefaults.standard.set(d, forKey: decksKey) }
        if let d = foldersData { UserDefaults.standard.set(d, forKey: foldersKey) }
        if let d = statsData   { UserDefaults.standard.set(d, forKey: statsKey) }
        if let d = daysData    { UserDefaults.standard.set(d, forKey: daysKey) }

        // Don't push to iCloud while applying a cloud change (avoids ping-pong),
        // and don't push the built-in starter seed at all — pushing it used to
        // stamp a fresh timestamp over a real library that simply hadn't
        // downloaded yet, which destroyed it on every other device.
        guard !isApplyingCloud, pushToCloud else { return }
        hasUserData = true

        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: syncDateKey)
        if let d = decksData   { cloud.set(d, forKey: decksKey) }
        if let d = foldersData { cloud.set(d, forKey: foldersKey) }
        if let d = statsData   { cloud.set(d, forKey: statsKey) }
        if let d = daysData    { cloud.set(d, forKey: daysKey) }
        cloud.set(now, forKey: syncDateKey)
        cloud.synchronize()
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: decksKey),
           let v = SafeJSON.array(Deck.self, from: d)                  { decks     = v }
        if let d = UserDefaults.standard.data(forKey: foldersKey),
           let v = SafeJSON.array(DeckFolder.self, from: d)            { folders   = v }
        if let d = UserDefaults.standard.data(forKey: statsKey),
           let v = SafeJSON.dictionary(UUID.self, DeckStats.self, from: d) { deckStats = v }
        if let d = UserDefaults.standard.data(forKey: daysKey),
           let v = SafeJSON.dictionary(String.self, DayStat.self, from: d) { dayStats  = v }

        if dayStats.isEmpty && !deckStats.isEmpty { rebuildDayStats() }
    }

    /// Backfill the per-day rollup for libraries saved before it existed.
    private func rebuildDayStats() {
        var built: [String: DayStat] = [:]
        for stat in deckStats.values {
            for r in stat.sessions {
                let key = DayKey.string(from: r.date)
                var d = built[key] ?? DayStat()
                d.sessions += 1
                d.minutes  += r.duration / 60
                built[key] = d
            }
        }
        dayStats = built
        trimDayStats()
    }

    // MARK: - iCloud sync

    private func currentSnapshot() -> LibrarySnapshot {
        LibrarySnapshot(decks: decks, folders: folders, stats: deckStats, days: dayStats)
    }

    private func cloudSnapshot() -> LibrarySnapshot? {
        guard let d = cloud.data(forKey: decksKey),
              let remoteDecks = SafeJSON.array(Deck.self, from: d) else { return nil }
        var snap = LibrarySnapshot(decks: remoteDecks)
        if let fd = cloud.data(forKey: foldersKey),
           let v = SafeJSON.array(DeckFolder.self, from: fd)                 { snap.folders = v }
        if let sd = cloud.data(forKey: statsKey),
           let v = SafeJSON.dictionary(UUID.self, DeckStats.self, from: sd)  { snap.stats = v }
        if let dd = cloud.data(forKey: daysKey),
           let v = SafeJSON.dictionary(String.self, DayStat.self, from: dd)  { snap.days = v }
        return snap
    }

    private func mergeFromCloudIfNewer() {
        guard cloud.data(forKey: decksKey) != nil else { return }
        // A device that has never been edited locally holds nothing worth
        // keeping — take whatever iCloud has.
        if !hasUserData { applyCloudData(); return }

        let cloudDate = cloud.double(forKey: syncDateKey)
        let localDate = UserDefaults.standard.double(forKey: syncDateKey)
        if cloudDate > localDate, cloudDate > 0 { applyCloudData() }
        else { unionInCloudExtras() }
    }

    @objc private func cloudChanged(_ note: Notification) {
        // External change from another device — or the first payload finally
        // arriving on a fresh install.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.cloud.data(forKey: self.decksKey) != nil else { return }

            if !self.hasUserData { self.applyCloudData(); return }

            let cloudDate = self.cloud.double(forKey: self.syncDateKey)
            let localDate = UserDefaults.standard.double(forKey: self.syncDateKey)
            if cloudDate > localDate { self.applyCloudData() }
            else { self.unionInCloudExtras() }
        }
    }

    /// Our copy is the newer one, so it wins — but decks the cloud holds that we
    /// have never seen are adopted rather than dropped. Temporary "wrong answers"
    /// decks are not adopted; they are regenerated from this device's own
    /// mistakes and importing another device's is just noise.
    private func unionInCloudExtras() {
        guard var remote = cloudSnapshot() else { return }
        remote.decks.removeAll { $0.isTemporary }

        let merged = LibraryMerge.adopting(currentSnapshot(), into: remote)
        guard merged.decks.count != decks.count || merged.folders.count != folders.count else { return }

        decks     = merged.decks
        folders   = merged.folders
        deckStats = merged.stats
        dayStats  = merged.days
        save()
    }

    /// The cloud copy is newer, so it decides everything it knows about — but it
    /// does not get to delete decks it has never seen. Replacing outright meant
    /// whichever device synced second lost its entire offline session.
    private func applyCloudData() {
        guard let remote = cloudSnapshot() else { return }
        let merged = LibraryMerge.adopting(remote, into: currentSnapshot())

        isApplyingCloud = true
        decks     = merged.decks
        folders   = merged.folders
        deckStats = merged.stats
        dayStats  = merged.days

        if dayStats.isEmpty && !deckStats.isEmpty { rebuildDayStats() }

        // Mirror to local storage + sync timestamp (the push is suppressed while
        // isApplyingCloud is set, so this writes locally only).
        save()
        UserDefaults.standard.set(cloud.double(forKey: syncDateKey), forKey: syncDateKey)
        // Adopted data counts as real data from here on.
        hasUserData = true
        isApplyingCloud = false

        // Whatever this device held that the cloud copy did not has to go back up,
        // or it stays stranded here until the user happens to edit something.
        let remoteIDs = Set(remote.decks.map { $0.id })
        if merged.decks.contains(where: { !remoteIDs.contains($0.id) }) { save() }
    }
}

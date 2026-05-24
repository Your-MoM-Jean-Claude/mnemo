import Foundation
import Combine

struct HardWord: Identifiable {
    let list: WordList
    let pair: WordPair
    let stats: WordStats
    var id: UUID { pair.id }
}

class LibraryViewModel: ObservableObject {
    @Published var wordLists: [WordList]              = []
    @Published var statistics: [UUID: ListStatistics] = [:]
    @Published var errorMessage: String?
    @Published var showError: Bool      = false
    @Published var dataLoadFailed: Bool = false

    private let listsKey    = "savedWordLists"
    private let statsKey    = "wordListStats"
    private let importedKey = "importedListIDs"

    private(set) var importedListIDs: Set<UUID> = []

    init() { load() }

    // MARK: - Import

    func importFromURL(_ url: URL, name: String? = nil, errorFor: ((ParseError) -> String)? = nil) {
        do {
            let pairs    = try FileParser.parse(url: url)
            let listName = name ?? url.deletingPathExtension().lastPathComponent
            let newList  = WordList(name: listName, pairs: pairs)
            wordLists.append(newList)
            importedListIDs.insert(newList.id)
            save()
        } catch let error as ParseError {
            errorMessage = errorFor?(error) ?? error.localizedDescription
            showError    = true
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
        }
    }

    func importFromText(_ text: String, name: String, errorFor: ((ParseError) -> String)? = nil) {
        do {
            let pairs = try FileParser.parse(text: text)
            wordLists.append(WordList(name: name, pairs: pairs))
            save()
        } catch let error as ParseError {
            errorMessage = errorFor?(error) ?? error.localizedDescription
            showError    = true
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
        }
    }

    func deleteList(at offsets: IndexSet) {
        let ids = offsets.map { wordLists[$0].id }
        wordLists.remove(atOffsets: offsets)
        ids.forEach {
            statistics.removeValue(forKey: $0)
            importedListIDs.remove($0)
        }
        save()
    }

    func renameList(id: UUID, newName: String) {
        guard let idx = wordLists.firstIndex(where: { $0.id == id }) else { return }
        wordLists[idx].name = newName
        save()
    }

    func addPair(_ pair: WordPair, to listID: UUID) {
        guard let idx = wordLists.firstIndex(where: { $0.id == listID }) else { return }
        wordLists[idx].pairs.append(pair)
        save()
    }

    func updatePair(_ pair: WordPair, in listID: UUID) {
        guard let listIdx = wordLists.firstIndex(where: { $0.id == listID }),
              let pairIdx = wordLists[listIdx].pairs.firstIndex(where: { $0.id == pair.id }) else { return }
        wordLists[listIdx].pairs[pairIdx] = pair
        save()
    }

    func deletePair(id: UUID, from listID: UUID) {
        guard let listIdx = wordLists.firstIndex(where: { $0.id == listID }) else { return }
        wordLists[listIdx].pairs.removeAll { $0.id == id }
        statistics[listID]?.wordStats.removeValue(forKey: id)
        save()
    }

    // MARK: - Statistics

    func recordSession(result: QuizResult) {
        var stat = statistics[result.listID] ?? ListStatistics()
        stat.apply(result)
        statistics[result.listID] = stat

        if let idx = wordLists.firstIndex(where: { $0.id == result.listID }) {
            wordLists[idx].lastStudied = result.date
        }
        save()
    }

    func stats(for listID: UUID) -> ListStatistics {
        statistics[listID] ?? ListStatistics()
    }

    func wordStats(for listID: UUID) -> [UUID: WordStats] {
        statistics[listID]?.wordStats ?? [:]
    }

    func isImported(_ list: WordList) -> Bool {
        importedListIDs.contains(list.id)
    }

    func isComplete(_ list: WordList) -> Bool {
        guard !list.pairs.isEmpty else { return false }
        let ws = statistics[list.id]?.wordStats ?? [:]
        return list.pairs.allSatisfy { pair in
            guard let s = ws[pair.id] else { return false }
            return s.attempts >= 2 && s.accuracy >= 0.8
        }
    }

    func dueWordCount(for list: WordList) -> Int {
        let ws = statistics[list.id]?.wordStats ?? [:]
        return list.pairs.filter { ws[$0.id]?.isDue ?? true }.count
    }

    func nextReviewDate(for list: WordList) -> Date? {
        let ws = statistics[list.id]?.wordStats ?? [:]
        let dates = list.pairs.compactMap { pair -> Date? in
            guard let stat = ws[pair.id], !stat.isDue else { return nil }
            return stat.dueDate
        }
        return dates.min()
    }

    func deleteStats(for listID: UUID) {
        statistics.removeValue(forKey: listID)
        if let idx = wordLists.firstIndex(where: { $0.id == listID }) {
            wordLists[idx].lastStudied = nil
        }
        save()
    }

    func moveList(from source: IndexSet, to destination: Int) {
        wordLists.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Global computed stats

    var todayStudyMinutes: Double {
        let calendar = Calendar.current
        var total: TimeInterval = 0
        for stat in statistics.values {
            for session in stat.sessions where calendar.isDateInToday(session.date) {
                total += session.duration
            }
        }
        return total / 60.0
    }

    var totalSessionsCount: Int {
        statistics.values.reduce(0) { $0 + $1.totalSessions }
    }

    var overallAccuracy: Double {
        let totalAnswers = statistics.values.reduce(0) { $0 + $1.totalAnswers }
        let totalCorrect = statistics.values.reduce(0) { $0 + $1.totalCorrect }
        guard totalAnswers > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswers)
    }

    var studyStreak: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var allDates = Set<String>()
        for stat in statistics.values {
            for session in stat.sessions {
                allDates.insert(formatter.string(from: session.date))
            }
        }

        var streak = 0
        var checkDay = Date()

        // If no session today, start the streak check from yesterday
        if !allDates.contains(formatter.string(from: checkDay)) {
            checkDay = calendar.date(byAdding: .day, value: -1, to: checkDay) ?? .distantPast
        }

        while allDates.contains(formatter.string(from: checkDay)) {
            streak += 1
            checkDay = calendar.date(byAdding: .day, value: -1, to: checkDay) ?? .distantPast
        }

        return streak
    }

    // Session counts for each of the last 7 days (index 0 = 6 days ago, index 6 = today)
    var weeklySessionCounts: [Int] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var counts: [String: Int] = [:]
        for stat in statistics.values {
            for session in stat.sessions {
                let key = formatter.string(from: session.date)
                counts[key, default: 0] += 1
            }
        }

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -(6 - offset), to: Date()) ?? Date()
            return counts[formatter.string(from: day)] ?? 0
        }
    }

    var lastStudiedEntry: (list: WordList, date: Date)? {
        wordLists
            .compactMap { list -> (WordList, Date)? in
                guard let d = list.lastStudied else { return nil }
                return (list, d)
            }
            .max(by: { $0.1 < $1.1 })
    }

    // Top 10 hardest words across all lists (min 2 attempts)
    var hardestWords: [HardWord] {
        var result: [HardWord] = []
        for list in wordLists {
            let ws = statistics[list.id]?.wordStats ?? [:]
            for pair in list.pairs {
                if let s = ws[pair.id], s.attempts >= 2 {
                    result.append(HardWord(list: list, pair: pair, stats: s))
                }
            }
        }
        return result
            .sorted { $0.stats.accuracy < $1.stats.accuracy }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(wordLists) {
            UserDefaults.standard.set(data, forKey: listsKey)
        }
        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
        if let data = try? JSONEncoder().encode(Array(importedListIDs)) {
            UserDefaults.standard.set(data, forKey: importedKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: listsKey) {
            if let lists = try? JSONDecoder().decode([WordList].self, from: data) {
                wordLists = lists
            } else {
                dataLoadFailed = true
            }
        }
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let stats = try? JSONDecoder().decode([UUID: ListStatistics].self, from: data) {
            statistics = stats
        }
        if let data = UserDefaults.standard.data(forKey: importedKey),
           let ids = try? JSONDecoder().decode([UUID].self, from: data) {
            importedListIDs = Set(ids)
        }
    }
}

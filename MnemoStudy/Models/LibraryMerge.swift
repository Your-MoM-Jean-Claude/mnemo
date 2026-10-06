import Foundation

/// Per-day rollup used by the streak counter and the weekly chart, so neither
/// has to walk the whole session history on every SwiftUI render.
///
/// Lives here rather than next to the view model so the merge below stays
/// Foundation-only and can be exercised by the regression harness.
struct DayStat: Codable {
    var sessions: Int = 0
    var minutes: Double = 0

    init() {}
    init(sessions: Int, minutes: Double) {
        self.sessions = sessions
        self.minutes  = minutes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sessions = try c.decodeIfPresent(Int.self, forKey: .sessions) ?? 0
        minutes  = try c.decodeIfPresent(Double.self, forKey: .minutes) ?? 0
    }
}

/// Everything one store holds — the local copy or the iCloud copy.
struct LibrarySnapshot {
    var decks: [Deck] = []
    var folders: [DeckFolder] = []
    var stats: [UUID: DeckStats] = [:]
    var days: [String: DayStat] = [:]

    init(decks: [Deck] = [], folders: [DeckFolder] = [],
         stats: [UUID: DeckStats] = [:], days: [String: DayStat] = [:]) {
        self.decks   = decks
        self.folders = folders
        self.stats   = stats
        self.days    = days
    }
}

enum LibraryMerge {
    /// `incoming` is the copy that won on timestamp, so it decides the content of
    /// everything both sides know about. What it must not decide is that content
    /// it has never seen should cease to exist.
    ///
    /// Two devices edited offline is not an exotic case, and the copy that
    /// synced second used to have its entire offline session replaced by the
    /// other one. The price of keeping unknown local content is that deleting a
    /// deck on one device can be undone by another device that still holds it
    /// and has not synced since. A deck coming back is recoverable; a library
    /// being deleted is not.
    static func adopting(_ incoming: LibrarySnapshot, into local: LibrarySnapshot) -> LibrarySnapshot {
        var merged = incoming

        let known     = Set(incoming.decks.map { $0.id })
        let localOnly = local.decks.filter { !known.contains($0.id) }
        merged.decks.append(contentsOf: localOnly)

        // The folders those decks live in have to come along, or they resurface
        // as loose decks at the top level.
        let knownFolders = Set(incoming.folders.map { $0.id })
        let needed       = Set(localOnly.compactMap { $0.folderID })
        merged.folders.append(contentsOf: local.folders.filter {
            !knownFolders.contains($0.id) && needed.contains($0.id)
        })

        for d in localOnly where merged.stats[d.id] == nil {
            if let s = local.stats[d.id] { merged.stats[d.id] = s }
        }

        // Day rollups are plain counters and neither side knows the other's
        // total for a day both devices worked on. Keeping the larger count is a
        // heuristic — it protects the streak without inventing sessions that
        // never happened.
        for (key, mine) in local.days {
            guard let theirs = merged.days[key] else { merged.days[key] = mine; continue }
            if mine.sessions > theirs.sessions { merged.days[key] = mine }
        }

        return merged
    }
}

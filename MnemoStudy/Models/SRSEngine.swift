import Foundation

enum SRSRating: Int {
    case wrong   = 0
    case hard    = 3
    case good    = 4
    case easy    = 5
}

struct SRSEngine {
    /// SM-2 algorithm update. Returns updated CardStats.
    static func update(_ stats: CardStats, rating: SRSRating) -> CardStats {
        var s = stats
        let q = Double(rating.rawValue)

        if rating == .wrong {
            s.srsInterval = 1
            s.consecutiveCorrect = 0
        } else {
            let newEF = max(1.3, s.srsEaseFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
            s.srsEaseFactor = newEF
            s.srsInterval = nextInterval(current: s.srsInterval, ef: newEF)
            s.consecutiveCorrect += 1
        }

        s.srsDueDate = Calendar.current.date(byAdding: .day, value: s.srsInterval, to: Date())
        return s
    }

    private static func nextInterval(current: Int, ef: Double) -> Int {
        switch current {
        case 1:  return 3
        case 3:  return 7
        default: return Int(Double(current) * ef)
        }
    }
}

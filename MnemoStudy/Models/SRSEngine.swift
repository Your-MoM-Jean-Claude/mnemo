import Foundation

// Behavioral SM-2: rating derived from response time, not user self-assessment
enum SRSRating: Int, Codable {
    case again = 0   // wrong OR very slow (> ~10s adjusted)
    case hard  = 2   // correct but slow (6–10s adjusted)
    case good  = 4   // correct, normal speed (3–6s adjusted)
    case easy  = 5   // correct, fast (< 3s adjusted)

    // Compute rating from response time + correctness
    // wordLen adjusts thresholds: +0.4s per char above 5
    static func from(correct: Bool, elapsed: TimeInterval, wordLen: Int) -> SRSRating {
        if !correct { return .again }
        let bonus = max(0.0, Double(wordLen - 5)) * 0.4
        let t = elapsed - bonus
        if t < 3  { return .easy }
        if t < 6  { return .good }
        if t < 10 { return .hard }
        return .again
    }
}

struct SRSEngine {
    static func update(_ stats: CardStats, rating: SRSRating) -> CardStats {
        var s = stats
        let q = Double(rating.rawValue)

        switch rating {
        case .again:
            s.srsInterval        = 1
            s.consecutiveCorrect = 0
            s.srsEaseFactor      = max(1.3, s.srsEaseFactor - 0.2)
        case .hard:
            s.srsInterval   = max(1, Int(Double(s.srsInterval) * 1.2))
            s.srsEaseFactor = max(1.3, s.srsEaseFactor - 0.15)
            s.consecutiveCorrect += 1
        case .good, .easy:
            let newEF = max(1.3, s.srsEaseFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
            s.srsEaseFactor = newEF
            s.srsInterval   = nextInterval(current: s.srsInterval, ef: newEF)
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

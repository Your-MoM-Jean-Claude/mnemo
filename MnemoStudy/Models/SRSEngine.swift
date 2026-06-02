import Foundation

// Behavioral SM-2: rating derived from response time, not user self-assessment
enum SRSRating: Int, Codable {
    case again = 0   // wrong OR very slow (> ~10s adjusted)
    case hard  = 2   // correct but slow (6–10s adjusted)
    case good  = 4   // correct, normal speed (3–6s adjusted)
    case easy  = 5   // correct, fast (< 3s adjusted)

    // Word-length adjusted elapsed time: +0.4s allowance per char above 5
    static func adjustedTime(elapsed: TimeInterval, wordLen: Int) -> Double {
        let bonus = max(0.0, Double(wordLen - 5)) * 0.4
        return max(0, elapsed - bonus)
    }

    // Rating from adjusted time. Before calibration uses universal thresholds;
    // after calibration uses thresholds relative to the user's personal median.
    static func from(correct: Bool, adjusted: Double, median: Double, calibrated: Bool) -> SRSRating {
        if !correct { return .again }
        if !calibrated {
            if adjusted < 3  { return .easy }
            if adjusted < 6  { return .good }
            if adjusted < 10 { return .hard }
            return .again
        }
        // personalized relative to median
        if adjusted < median * 0.7 { return .easy }
        if adjusted < median * 1.3 { return .good }
        if adjusted < median * 2.5 { return .hard }
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

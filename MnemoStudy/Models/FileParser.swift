import Foundation

enum ParseError: LocalizedError {
    case emptyFile
    case noValidPairs
    case invalidFormat(line: Int)

    var errorDescription: String? {
        switch self {
        case .emptyFile:            return "The file is empty."
        case .noValidPairs:         return "No valid pairs found. Use format: front - back"
        case .invalidFormat(let l): return "Invalid format on line \(l). Use: front - back"
        }
    }
}

struct FileParser {
    static func parse(text: String) throws -> [Card] {
        let lines = text.components(separatedBy: .newlines)
        guard !lines.isEmpty else { throw ParseError.emptyFile }

        var cards: [Card] = []
        for (i, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let range = line.range(of: " - ") else {
                throw ParseError.invalidFormat(line: i + 1)
            }
            let front = String(line[line.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let back  = String(line[range.upperBound...])
                .trimmingCharacters(in: .whitespaces)
            guard !front.isEmpty, !back.isEmpty else {
                throw ParseError.invalidFormat(line: i + 1)
            }
            cards.append(Card(front: front, back: back))
        }
        if cards.isEmpty { throw ParseError.noValidPairs }
        return cards
    }

    static func parse(url: URL) throws -> [Card] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try parse(text: text)
    }

    static func export(deck: Deck) -> String {
        "# \(deck.name)\n" + deck.cards.map { "\($0.front) - \($0.back)" }.joined(separator: "\n")
    }
}

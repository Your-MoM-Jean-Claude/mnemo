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
        for (_, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let range = line.range(of: " - ") else { continue }
            let front = String(line[line.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let back  = String(line[range.upperBound...])
                .trimmingCharacters(in: .whitespaces)
            guard !front.isEmpty, !back.isEmpty else { continue }
            cards.append(Card(front: front, back: back))
        }
        if cards.isEmpty { throw ParseError.noValidPairs }
        return cards
    }

    static func parse(url: URL) throws -> [Card] {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        var coordinatorError: NSError?
        var parseResult: Result<[Card], Error> = .failure(ParseError.emptyFile)

        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinatorError) { coordURL in
            do {
                let data = try Data(contentsOf: coordURL)
                let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1)
                    ?? String(data: data, encoding: .windowsCP1252)
                    ?? ""
                parseResult = .success(try parse(text: text))
            } catch {
                parseResult = .failure(error)
            }
        }

        if let e = coordinatorError { throw e }
        switch parseResult {
        case .success(let cards): return cards
        case .failure(let error): throw error
        }
    }

    static func export(deck: Deck) -> String {
        "# \(deck.name)\n" + deck.cards.map { "\($0.front) - \($0.back)" }.joined(separator: "\n")
    }
}

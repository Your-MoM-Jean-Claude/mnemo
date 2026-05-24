import Foundation

enum ParseError: LocalizedError {
    case emptyFile
    case noValidPairs
    case invalidEncoding
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .emptyFile:       return "Empty file."
        case .noValidPairs:    return "No valid pairs. Supported formats: word - translation, word,translation, word;translation, word[TAB]translation"
        case .invalidEncoding: return "Invalid encoding — save as UTF-8."
        case .fileTooLarge:    return "File too large (max 5 MB)."
        }
    }
}

struct FileParser {

    // Accepted separators in priority order (more specific first)
    private static let separators = [" - ", "\t", ";", ","]

    static func parse(text: String) throws -> [WordPair] {
        let lines = text.components(separatedBy: .newlines)
        var pairs: [WordPair] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            if let pair = parsePair(from: trimmed) {
                pairs.append(pair)
            }
        }

        if pairs.isEmpty { throw ParseError.noValidPairs }
        return pairs
    }

    static func parse(url: URL) throws -> [WordPair] {
        let maxBytes = 5 * 1024 * 1024
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           size > maxBytes {
            throw ParseError.fileTooLarge
        }
        guard let text = (try? String(contentsOf: url, encoding: .utf8)) ??
                         (try? String(contentsOf: url, encoding: .isoLatin2)) else {
            throw ParseError.invalidEncoding
        }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ParseError.emptyFile
        }
        return try parse(text: text)
    }

    private static func parsePair(from line: String) -> WordPair? {
        for sep in separators {
            guard let range = line.range(of: sep) else { continue }
            let front = String(line[line.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let back  = String(line[range.upperBound...])
                .trimmingCharacters(in: .whitespaces)
            if !front.isEmpty && !back.isEmpty {
                return WordPair(front: front, back: back)
            }
        }
        return nil
    }
}

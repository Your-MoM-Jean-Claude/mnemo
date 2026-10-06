import Foundation

// MARK: - Tolerant decoding
//
// Every type below is persisted to UserDefaults/iCloud as JSON. Swift's
// synthesized `init(from:)` calls `decode(_:forKey:)` for non-optional
// properties, which THROWS when the key is missing — a property default does
// not rescue it. So the moment a new field is added to a stored model, every
// previously saved blob stops decoding. Combined with `try?` at the call site
// that reads as "no data", and the store then gets overwritten.
//
// That is exactly how builds 15, 37 and 41 silently discarded user data.
//
// Rules from here on:
//   1. Persisted models decode every field with `decodeIfPresent` + a default.
//   2. Collections decode element-wise via `Failable`, so one bad entry cannot
//      take the whole library with it.
//   3. Callers must distinguish "key absent" from "value present but unreadable"
//      and must never seed over the latter.

/// Decodes `T`, yielding `nil` instead of throwing so one corrupt element does
/// not fail the entire array.
struct Failable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

enum SafeJSON {
    /// Decode an array, dropping only the elements that are beyond repair.
    static func array<T: Decodable>(_ type: T.Type, from data: Data) -> [T]? {
        if let exact = try? JSONDecoder().decode([T].self, from: data) { return exact }
        guard let loose = try? JSONDecoder().decode([Failable<T>].self, from: data) else { return nil }
        return loose.compactMap { $0.value }
    }

    /// Decode a keyed dictionary, dropping only unreadable values.
    static func dictionary<K: Decodable & Hashable, V: Decodable>(
        _ keyType: K.Type, _ valueType: V.Type, from data: Data
    ) -> [K: V]? {
        if let exact = try? JSONDecoder().decode([K: V].self, from: data) { return exact }
        guard let loose = try? JSONDecoder().decode([K: Failable<V>].self, from: data) else { return nil }
        return loose.compactMapValues { $0.value }
    }

    static func object<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Enum fallbacks
//
// A raw-value enum throws on an unrecognized case, which would take its whole
// containing record with it. Old builds reading data written by newer ones must
// degrade to a sensible default instead.

extension StudyMode {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = StudyMode(rawValue: raw) ?? .typing
    }
}

extension CardOrder {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CardOrder(rawValue: raw) ?? .random
    }
}

extension StudyDirection {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = StudyDirection(rawValue: raw) ?? .frontToBack
    }
}

extension AppLanguage {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AppLanguage(rawValue: raw) ?? .en
    }
}

// MARK: - App metadata

/// Version was hardcoded as "1.0" in three separate views, so every one of them
/// went stale the moment MARKETING_VERSION moved.
enum AppInfo {
    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    static var versionString: String { "\(marketingVersion) (\(build))" }
}

// MARK: - Day keys
//
// Streaks and the weekly chart bucket sessions by calendar day. A plain
// DateFormatter picks up the user's locale and calendar, so on a non-Gregorian
// calendar the keys stop matching. Pin both.

enum DayKey {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_US_POSIX")
        return c
    }()

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar   = calendar
        f.locale     = Locale(identifier: "en_US_POSIX")
        f.timeZone   = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }
    static func date(from key: String) -> Date? { formatter.date(from: key) }
}

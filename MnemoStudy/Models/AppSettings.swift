import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case en, cs, es
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: "English"
        case .cs: "Čeština"
        case .es: "Español"
        }
    }
}

struct NotificationTime: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int

    init(id: UUID = UUID(), hour: Int, minute: Int) {
        self.id = id
        self.hour = hour
        self.minute = minute
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hour   = try c.decodeIfPresent(Int.self, forKey: .hour) ?? 8
        minute = try c.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        id     = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    }

    var displayString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

struct AppSettings: Codable {
    var language: AppLanguage = .en
    var dailyGoalMinutes: Int = 15
    var notifications: [NotificationTime] = []
    var srsEnabled: Bool = false
    /// Retained only so blobs written by builds ≤44 keep round-tripping. The
    /// access model is session-based (see SettingsViewModel.inTrial) and no
    /// longer reads this.
    var trialStartDate: Date = Date()
    var hasSeenOnboarding: Bool = false
    var tempoProfile: UserTempoProfile = UserTempoProfile()

    init() {}

    // Tolerant decoding — see Persistence.swift. `hasSeenOnboarding` (build 15)
    // and `tempoProfile` (build 37) each made every previously saved settings
    // blob undecodable, which silently reset the user's language, reminders and
    // daily goal on upgrade.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language          = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .en
        dailyGoalMinutes  = try c.decodeIfPresent(Int.self, forKey: .dailyGoalMinutes) ?? 15
        notifications     = try c.decodeIfPresent([Failable<NotificationTime>].self, forKey: .notifications)?
                                .compactMap { $0.value } ?? []
        srsEnabled        = try c.decodeIfPresent(Bool.self, forKey: .srsEnabled) ?? false
        trialStartDate    = try c.decodeIfPresent(Date.self, forKey: .trialStartDate) ?? Date()
        hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
        tempoProfile      = try c.decodeIfPresent(UserTempoProfile.self, forKey: .tempoProfile) ?? UserTempoProfile()
    }
}

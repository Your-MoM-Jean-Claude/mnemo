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

    var displayString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

struct AppSettings: Codable {
    var language: AppLanguage = .en
    var dailyGoalMinutes: Int = 15
    var notifications: [NotificationTime] = []
    var srsEnabled: Bool = false
    var trialStartDate: Date = Date()
    var hasSeenOnboarding: Bool = false
    var tempoProfile: UserTempoProfile = UserTempoProfile()
    static let trialDays = 3
}

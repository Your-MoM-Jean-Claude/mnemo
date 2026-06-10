import Foundation
import UserNotifications
import Combine
import StoreKit

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }

    private let key = "appSettings"

    init() {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let s = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = s
        } else {
            settings = AppSettings()
        }
        restorePurchaseIfNeeded()
        // Refresh the rolling notification window on every launch
        if !settings.notifications.isEmpty { scheduleNotifications() }
    }

    private func restorePurchaseIfNeeded() {
        Task { @MainActor in
            for await result in Transaction.currentEntitlements {
                if case .verified(let t) = result,
                   t.productID == "com.jirifilipec.mnemoapp.pro",
                   t.revocationDate == nil {
                    settings.trialStartDate = .distantPast
                }
            }
        }
    }

    var language: AppLanguage {
        get { settings.language }
        set { settings.language = newValue }
    }

    var srsEnabled: Bool {
        get { settings.srsEnabled }
        set { settings.srsEnabled = newValue }
    }

    var dailyGoalMinutes: Int {
        get { settings.dailyGoalMinutes }
        set { settings.dailyGoalMinutes = newValue }
    }

    // MARK: - Trial

    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let iCloudProKey = "mnemo_pro_unlocked"

    var isProUnlocked: Bool {
        get { iCloudStore.bool(forKey: iCloudProKey) }
        set {
            iCloudStore.set(newValue, forKey: iCloudProKey)
            iCloudStore.synchronize()
            if newValue { settings.trialStartDate = .distantPast }
        }
    }

    // MARK: - Access model (value-based trial + soft free tier)
    // First N study sessions give full Pro access (taste SRS + unlimited decks).
    // After that, a soft free tier remains (bundled decks + studying + 1 custom
    // deck + audio + basic stats). Pro unlocks everything. No hard paywall.

    static let trialSessions = 5
    static let freeCustomDecks = 1

    var trialSessionsUsed: Int { settings.tempoProfile.sessions }
    var inTrial: Bool { trialSessionsUsed < SettingsViewModel.trialSessions }
    var trialSessionsRemaining: Int { max(0, SettingsViewModel.trialSessions - trialSessionsUsed) }

    // Full access = purchased OR still within the value-based trial
    var hasPro: Bool { isProUnlocked || inTrial }

    // SRS only actually runs when enabled AND the user has Pro access
    var srsActive: Bool { settings.srsEnabled && hasPro }

    // MARK: - Notifications

    func addNotification(hour: Int, minute: Int) {
        guard settings.notifications.count < 3 else { return }
        settings.notifications.append(NotificationTime(hour: hour, minute: minute))
        scheduleNotifications()
    }

    func removeNotification(id: UUID) {
        settings.notifications.removeAll { $0.id == id }
        scheduleNotifications()
    }

    private var snoozeUntil: Date?

    // Schedule a rolling 7-day window of individual notifications, each with a
    // RANDOM message — so reminders actually vary (a single repeating trigger
    // would freeze one message). Refreshed on launch and whenever times change.
    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !settings.notifications.isEmpty else { return }

        let messages = settings.language.notificationMessages
        let cal = Calendar.current
        let now = Date()
        let floor = max(now, snoozeUntil ?? .distantPast)

        for n in settings.notifications {
            for dayOffset in 0..<7 {
                guard let base = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                var comps = cal.dateComponents([.year, .month, .day], from: base)
                comps.hour = n.hour; comps.minute = n.minute
                guard let fireDate = cal.date(from: comps), fireDate > floor else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Mnemo Study"
                content.body  = messages.randomElement() ?? "📚"
                content.sound = .default
                let trigComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: trigComps, repeats: false)
                let req = UNNotificationRequest(identifier: "\(n.id.uuidString)-\(dayOffset)",
                                                content: content, trigger: trigger)
                center.add(req)
            }
        }
    }

    // Pause reminders for N minutes, then they resume automatically.
    func snoozeReminders(minutes: Int = 10) {
        snoozeUntil = Date().addingTimeInterval(Double(minutes) * 60)
        scheduleNotifications()
    }

    // MARK: - SRS tempo calibration

    func recordCalibration(_ adjustedTimes: [Double]) {
        guard !adjustedTimes.isEmpty else {
            // still count the session even if no correct answers
            settings.tempoProfile.sessions += 1
            return
        }
        var p = settings.tempoProfile
        p.samples.append(contentsOf: adjustedTimes)
        if p.samples.count > 300 { p.samples.removeFirst(p.samples.count - 300) }
        p.sessions += 1
        settings.tempoProfile = p
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

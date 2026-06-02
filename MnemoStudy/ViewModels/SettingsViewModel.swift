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

    var isTrialActive: Bool {
        if isProUnlocked { return true }
        let days = Calendar.current.dateComponents([.day],
            from: settings.trialStartDate, to: Date()).day ?? 0
        return days < AppSettings.trialDays
    }

    var trialDaysRemaining: Int {
        let days = Calendar.current.dateComponents([.day],
            from: settings.trialStartDate, to: Date()).day ?? 0
        return max(0, AppSettings.trialDays - days)
    }

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

    func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let messages = settings.language.notificationMessages
        for n in settings.notifications {
            let content = UNMutableNotificationContent()
            content.title = "Mnemo Study"
            content.body  = messages.randomElement() ?? "Time to study! 📚"
            content.sound = .default
            var comps = DateComponents()
            comps.hour   = n.hour
            comps.minute = n.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: n.id.uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
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

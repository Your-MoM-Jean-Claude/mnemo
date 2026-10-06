import Foundation
import UserNotifications
import Combine
import StoreKit

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }

    /// Pro entitlement. Mirrored to UserDefaults as well as iCloud so the unlock
    /// survives on a device that is not signed into iCloud at all.
    @Published var isProUnlocked: Bool = false {
        didSet {
            guard isProUnlocked != oldValue else { return }
            UserDefaults.standard.set(isProUnlocked, forKey: SettingsViewModel.proKey)
            iCloudStore.set(isProUnlocked, forKey: SettingsViewModel.proKey)
            iCloudStore.synchronize()
        }
    }

    private let key = "appSettings"
    static let productID = "com.jirifilipec.mnemoapp.pro"
    fileprivate static let proKey = "mnemo_pro_unlocked"
    fileprivate static let sessionsKey = "mnemo_sessions_observed"

    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private var updatesTask: Task<Void, Never>?

    init() {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let s = SafeJSON.object(AppSettings.self, from: data) {
            settings = s
        } else {
            settings = AppSettings()
        }
        isProUnlocked = UserDefaults.standard.bool(forKey: SettingsViewModel.proKey)
            || iCloudStore.bool(forKey: SettingsViewModel.proKey)
        let sharedSessions = Int(iCloudStore.longLong(forKey: SettingsViewModel.sessionsKey))
        if sharedSessions > settings.tempoProfile.sessions {
            settings.tempoProfile.sessions = sharedSessions
            save()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudProChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore)

        restorePurchaseIfNeeded()
        listenForTransactions()
        // Refresh the rolling notification window on every launch
        if !settings.notifications.isEmpty { scheduleNotifications() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        updatesTask?.cancel()
    }

    @objc private func cloudProChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.iCloudStore.bool(forKey: SettingsViewModel.proKey) { self.isProUnlocked = true }
            // The trial is a count of sessions, and it used to live only in this
            // device's AppSettings — so every new device handed out a fresh one.
            let shared = Int(self.iCloudStore.longLong(forKey: SettingsViewModel.sessionsKey))
            if shared > self.settings.tempoProfile.sessions {
                self.settings.tempoProfile.sessions = shared
            }
        }
    }

    /// Reinstating a purchase after a reinstall. This previously wrote
    /// `settings.trialStartDate = .distantPast` — a field the access model stopped
    /// consulting when the session-based trial landed in build 41 — so a paying
    /// customer who reinstalled silently lost Pro until they found the Restore
    /// button themselves.
    private func restorePurchaseIfNeeded() {
        Task { @MainActor in
            for await result in Transaction.currentEntitlements {
                if case .verified(let t) = result,
                   t.productID == SettingsViewModel.productID,
                   t.revocationDate == nil {
                    isProUnlocked = true
                }
            }
        }
    }

    /// StoreKit redelivers every transaction that was never finished — an Ask to
    /// Buy approval that lands while the app is open, a purchase made on another
    /// device, one interrupted mid-flow. Without a listener those only take
    /// effect on the next launch, and nothing ever finishes them, so the App
    /// Store keeps re-presenting a purchase the user has already paid for.
    private func listenForTransactions() {
        updatesTask = Task { @MainActor [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let t) = result else { continue }
                if t.productID == SettingsViewModel.productID {
                    // Only an explicit revocation takes Pro away. Absence of an
                    // entitlement must never do it: a device that is offline or
                    // signed out of the App Store reports none, and revoking on
                    // that would strip Pro from someone who just lost signal.
                    self?.isProUnlocked = (t.revocationDate == nil)
                }
                await t.finish()
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

    // MARK: - Access model (value-based trial + soft free tier)
    // First N study sessions give full Pro access (taste SRS + unlimited decks).
    // After that, a soft free tier remains (bundled decks + studying + 1 custom
    // deck + audio + basic stats). Pro unlocks everything. No hard paywall.

    static let trialSessions = 5
    static let freeCustomDecks = 1

    /// Leaves headroom under the iOS cap of 64 pending notification requests.
    /// The window still runs out eventually: an endless reminder needs a
    /// repeating trigger, and a repeating trigger is frozen to one message,
    /// which is what the rotating messages in build 44 moved away from.
    static let pendingBudget = 60

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
        // Scheduling before the authorization prompt is answered silently drops
        // every request, so ask first and schedule from the callback.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { [weak self] in self?.scheduleNotifications() }
        }
    }

    func removeNotification(id: UUID) {
        settings.notifications.removeAll { $0.id == id }
        scheduleNotifications()
    }

    private var snoozeUntil: Date?

    // Schedule a rolling window of individual notifications, each with a
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

        // iOS keeps at most 64 pending requests per app. The window used to be a
        // fixed week, so anyone who did not open the app for seven days simply
        // stopped being reminded — exactly when the reminder was worth having.
        // Fill the budget instead: two months with one daily reminder, three
        // weeks with the maximum of three.
        let daysAhead = max(7, min(63, SettingsViewModel.pendingBudget / settings.notifications.count))

        for n in settings.notifications {
            for dayOffset in 0..<daysAhead {
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
        // Appending an empty array is a no-op, so a session with no correct
        // answers still counts — it just contributes no samples.
        var p = settings.tempoProfile
        p.samples.append(contentsOf: adjustedTimes)
        if p.samples.count > 300 { p.samples.removeFirst(p.samples.count - 300) }
        p.sessions += 1
        settings.tempoProfile = p
        publishSessionCount()
    }

    /// The trial is counted in sessions, so the count has to follow the user
    /// rather than the device. Only the count travels — the response-time samples
    /// are this device's own calibration and stay local.
    private func publishSessionCount() {
        iCloudStore.set(Int64(settings.tempoProfile.sessions), forKey: SettingsViewModel.sessionsKey)
        iCloudStore.synchronize()
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

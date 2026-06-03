import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsViewModel

    @State private var showTimePicker  = false
    @State private var pickerHour      = 8
    @State private var pickerMinute    = 0
    @State private var showPaywall     = false

    var lang: AppLanguage { settings.language }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    VStack(spacing: 16) {

                        // Daily goal
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(lang.settingsDailyGoal, systemImage: "target")
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                HStack {
                                    Slider(value: Binding(
                                        get: { Double(settings.dailyGoalMinutes) },
                                        set: { settings.dailyGoalMinutes = Int($0) }),
                                           in: 5...120, step: 5)
                                        .tint(.mnemoGreen)
                                    Text("\(settings.dailyGoalMinutes) \(lang.settingsMinutes)")
                                        .font(.subheadline).foregroundStyle(Color.mnemoGold)
                                        .frame(width: 56, alignment: .trailing)
                                }
                            }
                        }

                        // Notifications
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(lang.settingsNotifications, systemImage: "bell.fill")
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)

                                ForEach(settings.settings.notifications) { n in
                                    HStack {
                                        Text(n.displayString)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Button {
                                            settings.removeNotification(id: n.id)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                    }
                                }

                                if settings.settings.notifications.count < 3 {
                                    Button {
                                        showTimePicker = true
                                        settings.requestNotificationPermission()
                                    } label: {
                                        Label(lang.settingsAddReminder, systemImage: "plus")
                                            .font(.subheadline).foregroundStyle(Color.mnemoGreen)
                                    }
                                }
                            }
                        }

                        // Language
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(lang.settingsLanguage, systemImage: "globe")
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                Picker(lang.settingsLanguage, selection: $settings.settings.language) {
                                    ForEach(AppLanguage.allCases) { l in
                                        Text(l.displayName).tag(l)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        // Pro status / upsell
                        Button {
                            if !settings.isProUnlocked { showPaywall = true }
                        } label: {
                            settingsCard {
                                HStack(spacing: 12) {
                                    Image(systemName: settings.isProUnlocked ? "checkmark.seal.fill" : "crown.fill")
                                        .foregroundStyle(Color.mnemoGold)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.proRow)
                                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                        if settings.isProUnlocked {
                                            Text(lang.paywallProActive)
                                                .font(.caption).foregroundStyle(Color.mnemoGreen)
                                        } else if settings.inTrial {
                                            Text("\(settings.trialSessionsRemaining) \(lang.proTrialLeft)")
                                                .font(.caption).foregroundStyle(.secondary)
                                        } else {
                                            Text(lang.paywallSubtitle)
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if !settings.isProUnlocked {
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        // SRS (Pro feature)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label(lang.settingsSRS, systemImage: "brain.head.profile")
                                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                    if !settings.hasPro {
                                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(Color.mnemoGold)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { settings.settings.srsEnabled },
                                        set: { newValue in
                                            if newValue && !settings.hasPro {
                                                showPaywall = true        // gate: don't enable
                                            } else {
                                                settings.settings.srsEnabled = newValue
                                            }
                                        }))
                                        .tint(.mnemoGreen)
                                }
                                Text(lang.settingsSRSDesc)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        // File formats info
                        settingsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(lang.settingsFileFormats, systemImage: "doc.text")
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                Text(lang.settingsFileFormatsDesc)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        // Version
                        Text("Mnemo Study · \(lang.settingsVersion) 1.0")
                            .font(.caption).foregroundStyle(.secondary.opacity(0.5))
                            .padding(.bottom, 32)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(lang.tabSettings)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTimePicker) {
                TimePickerSheet(hour: $pickerHour, minute: $pickerMinute, lang: lang) {
                    settings.addNotification(hour: pickerHour, minute: pickerMinute)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(settings)
            }
        }
    }

    @ViewBuilder
    private func settingsCard<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .padding(16).glassCard()
    }
}

// MARK: - Time picker sheet

struct TimePickerSheet: View {
    @Binding var hour: Int
    @Binding var minute: Int
    var lang: AppLanguage
    var onAdd: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()
                HStack(spacing: 0) {
                    Picker("", selection: $hour) {
                        ForEach(0..<24) { Text(String(format: "%02d", $0)).tag($0) }
                    }
                    .pickerStyle(.wheel).frame(maxWidth: .infinity)
                    Text(":").font(.title).foregroundStyle(.white)
                    Picker("", selection: $minute) {
                        ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) {
                            Text(String(format: "%02d", $0)).tag($0)
                        }
                    }
                    .pickerStyle(.wheel).frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(lang.settingsAddReminder)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.commonAdd) { onAdd(); dismiss() }
                        .foregroundStyle(Color.mnemoGreen)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

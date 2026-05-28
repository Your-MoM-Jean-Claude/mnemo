import SwiftUI
  import UserNotifications

  @main
  struct LexiDrillApp: App {
      @StateObject private var langManager   = LanguageManager()
      @StateObject private var library       = LibraryViewModel()
      @StateObject private var paywallManager = PaywallManager()
      @State private var showWelcome         = true

      var body: some Scene {
          WindowGroup {
              ZStack {
                  TabView {
                      LibraryView()
                          .tabItem {
                              Label(langManager.s.libraryTab, systemImage:
  "books.vertical.fill")
                          }
                      StatsView()
                          .tabItem {
                              Label(langManager.s.statsTab, systemImage:
  "chart.bar.fill")
                          }
                      SettingsView()
                          .tabItem {
                              Label(langManager.s.settingsTab, systemImage:
  "gearshape.fill")
                          }
                  }

                  if showWelcome {
                      WelcomeView {
                          withAnimation(.easeInOut(duration: 0.6)) { showWelcome =
  false }
                      }
                      .transition(.opacity)
                      .zIndex(1)
                  }
              }
              .environmentObject(langManager)
              .environmentObject(library)
              .environmentObject(paywallManager)
              .preferredColorScheme(.dark)
              .tint(Color.khaki)
              .fullScreenCover(isPresented: .constant(!paywallManager.isTrialActive)) {
                  PaywallView(paywall: paywallManager)
                      .environmentObject(langManager)
              }
          }
      }
  }

  // MARK: - SettingsView

  struct SettingsView: View {
      @EnvironmentObject private var lm: LanguageManager

      @AppStorage("studyGoalMinutes")      private var studyGoalMinutes: Int  = 0
      @AppStorage("notificationEnabled")   private var notificationEnabled: Bool =
  false
      @AppStorage("notificationHour")      private var notificationHour: Int  = 20
      @AppStorage("notificationMinute")    private var notificationMinute: Int = 0

      private var reminderDate: Binding<Date> {
          Binding(
              get: {
                  var c = DateComponents(); c.hour = notificationHour; c.minute =
  notificationMinute
                  return Calendar.current.date(from: c) ?? Date()
              },
              set: { date in
                  let c = Calendar.current.dateComponents([.hour, .minute], from:
  date)
                  notificationHour   = c.hour ?? 20
                  notificationMinute = c.minute ?? 0
                  if notificationEnabled { scheduleNotification() }
              }
          )
      }

      var body: some View {
          NavigationStack {
              Form {
                  studyGoalSection
                  copyrightSection
              }
              .scrollContentBackground(.hidden)
              .background(Color.appBackground)
              .navigationTitle(lm.s.settingsTab)
              .navigationBarTitleDisplayMode(.large)
              .toolbar {
                  ToolbarItem(placement: .navigationBarTrailing) {
                      LanguagePickerCompact(selection: $lm.language)
                  }
              }
          }
      }

      // MARK: - Sections

      private var copyrightSection: some View {
          Section {
              VStack(spacing: 4) {
                  Text("Mnemo")
                      .font(.caption).fontWeight(.semibold)
                      .foregroundStyle(.secondary)
                  Text("© 2026 Jiří Filipec. All rights reserved.")
                      .font(.caption2)
                      .foregroundStyle(.tertiary)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 4)
          }
      }

      private var studyGoalSection: some View {
          Section(lm.s.studyGoalSection) {
              Picker(lm.s.studyGoalLabel, selection: $studyGoalMinutes) {
                  Text(lm.s.noGoal).tag(0)
                  ForEach([5, 10, 15, 20, 30], id: \.self) { m in
                      Text("\(m) \(lm.s.minutes)").tag(m)
                  }
              }

              if studyGoalMinutes > 0 {
                  Toggle(lm.s.reminderEnabled, isOn: $notificationEnabled)
                      .onChange(of: notificationEnabled) { enabled in
                          if enabled { scheduleNotification() }
                          else       { cancelNotification() }
                      }

                  if notificationEnabled {
                      DatePicker(lm.s.reminderTime,
                                 selection: reminderDate,
                                 displayedComponents: .hourAndMinute)
                  }
              }
          }
      }

      // MARK: - Notifications

      private func scheduleNotification() {
          let body = lm.s.notificationBody
          let hour = notificationHour; let minute = notificationMinute
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert,
  .sound]) { granted, _ in
              guard granted else {
                  DispatchQueue.main.async { self.notificationEnabled = false }
                  return
              }
              let content = UNMutableNotificationContent()
              content.title = "Mnemo"; content.body = body; content.sound = .default
              var components = DateComponents()
              components.hour = hour; components.minute = minute
              let trigger = UNCalendarNotificationTrigger(dateMatching: components,
  repeats: true)
              let request = UNNotificationRequest(identifier: "daily-study", content:
  content, trigger: trigger)
              let center = UNUserNotificationCenter.current()
              center.removePendingNotificationRequests(withIdentifiers:
  ["daily-study"])
              center.add(request)
          }
      }

      private func cancelNotification() {
          UNUserNotificationCenter.current()
              .removePendingNotificationRequests(withIdentifiers: ["daily-study"])
      }
  }

  // MARK: - Compact language picker (for toolbar)

  struct LanguagePickerCompact: View {
      @Binding var selection: Language

      var body: some View {
          HStack(spacing: 3) {
              ForEach(Language.allCases) { lang in
                  Button(lang.displayName) { selection = lang }
                      .font(.caption)
                      .fontWeight(.bold)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 4)
                      .background(selection == lang ? Color.khaki : Color.khakiCard,
  in: Capsule())
                      .foregroundStyle(selection == lang ? Color.appBackground :
  .primary)
                      .animation(.spring(response: 0.2), value: selection)
              }
          }
      }
  }

  // MARK: - Welcome Screen

  struct WelcomeView: View {
      @EnvironmentObject private var vm: LibraryViewModel
      @EnvironmentObject private var lm: LanguageManager
      var onDismiss: () -> Void

      @State private var appeared: CGFloat = 0

      private var hour: Int { Calendar.current.component(.hour, from: Date()) }

      var body: some View {
          ZStack {
              Color.appBackground.ignoresSafeArea()

              RadialGradient(
                  colors: [Color.khaki.opacity(0.10), Color.clear],
                  center: .top,
                  startRadius: 0,
                  endRadius: 380
              )
              .ignoresSafeArea()

              VStack(spacing: 0) {
                  Spacer()

                  VStack(spacing: 14) {
                      Image(systemName: "text.book.closed.fill")
                          .font(.system(size: 64))
                          .foregroundStyle(Color.khaki)
                          .shadow(color: Color.khaki.opacity(0.4), radius: 20)

                      Text("Mnemo")
                          .font(.system(size: 40, weight: .bold, design: .rounded))
                          .foregroundStyle(.white)
                  }
                  .opacity(appeared)
                  .offset(y: (1 - appeared) * -24)

                  Spacer().frame(height: 28)

                  Text(lm.s.welcomeGreeting(hour: hour))
                      .font(.title3)
                      .foregroundStyle(.secondary)
                      .opacity(appeared)
                      .offset(y: (1 - appeared) * -12)

                  Spacer().frame(height: 40)

                  lastSessionCard
                      .opacity(appeared)
                      .offset(y: (1 - appeared) * 12)

                  Spacer()

                  Text(lm.s.tapToContinue)
                      .font(.caption)
                      .foregroundStyle(.quaternary)
                      .opacity(appeared * 0.7)
                      .padding(.bottom, 36)
              }
              .padding(.horizontal, 36)
          }
          .onTapGesture { onDismiss() }
          .onAppear {
              withAnimation(.easeOut(duration: 0.75)) { appeared = 1 }
              DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { onDismiss() }
          }
      }

      @ViewBuilder
      private var lastSessionCard: some View {
          if let entry = vm.lastStudiedEntry {
              VStack(spacing: 6) {
                  Text(lm.s.welcomeLastSession)
                      .font(.caption)
                      .foregroundStyle(.secondary)

                  Text(entry.list.name)
                      .font(.headline)
                      .foregroundStyle(.white)
                      .lineLimit(1)

                  Text(formatDate(entry.date))
                      .font(.caption)
                      .foregroundStyle(Color.khaki)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 20)
              .padding(.horizontal, 24)
              .glassCard()
          } else {
              Text(lm.s.welcomeNoSession)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
          }
      }

      private func formatDate(_ date: Date) -> String {
          if Calendar.current.isDateInToday(date)     { return lm.s.lastStudiedToday }
          if Calendar.current.isDateInYesterday(date) { return
  lm.s.lastStudiedYesterday }
          let f = DateFormatter()
          f.dateStyle = .medium
          f.timeStyle = .none
          return f.string(from: date)
      }
  }

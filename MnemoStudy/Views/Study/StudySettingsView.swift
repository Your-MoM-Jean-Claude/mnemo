import SwiftUI

struct StudySettingsView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var deck: Deck

    @State private var mode: StudyMode       = .typing
    @State private var direction: StudyDirection = .frontToBack
    @State private var order: CardOrder      = .random
    @State private var sectionSize: Int      = 10
    @State private var requiredCorrect: Int  = 2
    @State private var showStudy             = false
    @State private var studyConfig: StudyConfig?

    var lang: AppLanguage { settings.language }

    // Quiz requires minimum 4 cards
    var quizDisabled: Bool { deck.cards.count < 4 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    VStack(spacing: 16) {

                        // Deck summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(deck.name)
                                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                Text("\(deck.cards.count) \(lang.libraryCards)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            ProgressRing(progress: library.stats(for: deck.id).overallAccuracy, size: 48)
                        }
                        .padding(16).glassCard().padding(.horizontal)

                        settingsSection(title: lang.settingsMode) {
                            Picker(lang.settingsMode, selection: $mode) {
                                Text(lang.settingsModeTyping).tag(StudyMode.typing)
                                Text(lang.settingsModeShow).tag(StudyMode.show)
                                Text(lang.settingsModeQuiz)
                                    .tag(StudyMode.quiz)
                                    .disabled(quizDisabled)
                            }
                            .pickerStyle(.segmented)
                            if quizDisabled {
                                Text("Quiz requires at least 4 cards")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        settingsSection(title: lang.settingsDirection) {
                            Picker(lang.settingsDirection, selection: $direction) {
                                Text(lang.settingsFrontToBack).tag(StudyDirection.frontToBack)
                                Text(lang.settingsBackToFront).tag(StudyDirection.backToFront)
                                Text(lang.settingsRandom).tag(StudyDirection.random)
                            }
                            .pickerStyle(.segmented)
                        }

                        settingsSection(title: "\(lang.settingsSectionSize): \(sectionSize)") {
                            Slider(value: Binding(
                                get: { Double(sectionSize) },
                                set: { sectionSize = Int($0) }),
                                   in: 2...min(20, Double(deck.cards.count)), step: 1)
                                .tint(.mnemoGreen)
                        }

                        settingsSection(title: "\(lang.settingsRequired): \(requiredCorrect)×") {
                            Slider(value: Binding(
                                get: { Double(requiredCorrect) },
                                set: { requiredCorrect = Int($0) }),
                                   in: 1...5, step: 1)
                                .tint(.mnemoGold)
                        }

                        settingsSection(title: lang.settingsOrder) {
                            Picker(lang.settingsOrder, selection: $order) {
                                Text(lang.settingsOrderAsc).tag(CardOrder.ascending)
                                Text(lang.settingsOrderDesc).tag(CardOrder.descending)
                                Text(lang.settingsRandom).tag(CardOrder.random)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Start button
                        PrimaryButton(title: lang.settingsStart) {
                            studyConfig = StudyConfig(
                                mode: mode, direction: direction, order: order,
                                sectionSize: min(sectionSize, deck.cards.count),
                                requiredCorrect: requiredCorrect)
                            showStudy = true
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(lang.settingsStudyTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }.foregroundStyle(.secondary)
                }
            }
            .fullScreenCover(isPresented: $showStudy) {
                if let config = studyConfig {
                    StudyView(deck: deck, config: config)
                }
            }
        }
        .onAppear {
            sectionSize = min(10, deck.cards.count)
        }
    }

    @ViewBuilder
    private func settingsSection<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
            content()
        }
        .padding(16).glassCard().padding(.horizontal)
    }
}

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
    @State private var studyConfig: StudyConfig? = nil

    var lang: AppLanguage { settings.language }

    // Quiz requires minimum 4 cards
    var quizDisabled: Bool { deck.cards.count < 4 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    VStack(spacing: 16) {

                        // Quick start presets
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Quick start")
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                            HStack(spacing: 10) {
                                presetButton("🎓", "Student",   .mnemoGold)   { applyPreset(mode: .typing, dir: .random,      sec: 20, req: 3) }
                                presetButton("🌴", "Casual",    .mnemoGreen)  { applyPreset(mode: .show,   dir: .frontToBack,  sec: 10, req: 1) }
                                presetButton("✈️", "Traveler",  .blue)        { applyPreset(mode: .show,   dir: .frontToBack,  sec: 5,  req: 1) }
                                presetButton("🔥", "Intensive", .orange)      { applyPreset(mode: .typing, dir: .random,      sec: 20, req: 5) }
                            }
                        }
                        .padding(16).glassCard().padding(.horizontal)

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
                            let maxSection = max(2.0, min(20.0, Double(deck.cards.count)))
                            Slider(value: Binding(
                                get: { Double(sectionSize) },
                                set: { sectionSize = Int($0) }),
                                   in: 2...maxSection, step: 1)
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
                                sectionSize: max(1, min(sectionSize, deck.cards.count)),
                                requiredCorrect: requiredCorrect)
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
            .fullScreenCover(item: $studyConfig) { config in
                StudyView(deck: deck, config: config,
                          srsEnabled: settings.srsEnabled,
                          cardStats: library.stats(for: deck.id).cardStats)
            }
        }
        .onAppear {
            sectionSize = max(2, min(10, deck.cards.count))
        }
    }

    private func applyPreset(mode: StudyMode, dir: StudyDirection, sec: Int, req: Int) {
        withAnimation(.spring(duration: 0.3)) {
            self.mode          = mode
            self.direction     = dir
            self.order         = .random
            self.sectionSize   = max(2, min(sec, deck.cards.count))
            self.requiredCorrect = req
        }
    }

    @ViewBuilder
    private func presetButton(_ icon: String, _ name: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon).font(.title2)
                Text(name).font(.caption2).fontWeight(.semibold).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.3), lineWidth: 1))
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

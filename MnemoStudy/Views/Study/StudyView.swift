import SwiftUI

struct StudyView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var deck: Deck
    var config: StudyConfig
    var reviewOrigins: [UUID: UUID]? = nil   // set when this is a cross-deck daily review

    @StateObject private var vm: StudyViewModel
    @State private var typingInput    = ""
    @State private var lastUserAnswer = ""
    @State private var showResults    = false
    @State private var showingBack    = false
    @State private var sessionSaved   = false
    @State private var selectedQuiz: String? = nil
    @State private var finalResult: SessionResult? = nil

    private let audio = AudioPlayer.shared

    @FocusState private var inputFocused: Bool

    var lang: AppLanguage { settings.language }

    init(deck: Deck, config: StudyConfig, srsEnabled: Bool = false,
         cardStats: [UUID: CardStats] = [:], reviewOrigins: [UUID: UUID]? = nil) {
        self.deck          = deck
        self.config        = config
        self.reviewOrigins = reviewOrigins
        _vm = StateObject(wrappedValue: StudyViewModel(deck: deck, config: config,
                                                       srsEnabled: srsEnabled, cardStats: cardStats))
    }

    private func save(_ result: SessionResult) {
        if let origins = reviewOrigins {
            library.recordReviewSession(result: result, origins: origins, settings: settings)
        } else {
            library.recordSession(result: result, settings: settings)
        }
    }

    var body: some View {
        ZStack {
            AppBg()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary).padding(12)
                    }
                    Spacer()
                    Text(vm.completedOfTotal)
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 4)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 4)
                        Capsule().fill(
                            LinearGradient(colors: [Color.mnemoGreen, Color.mnemoGold],
                                           startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * vm.progress, height: 4)
                            .animation(.spring(duration: 0.4), value: vm.progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                Spacer()

                if let item = vm.currentItem {
                    ZStack {
                        cardContent(item: item)

                        // Quiz: highlight options inline (green correct / red wrong),
                        // tap anywhere to advance — no full-screen overlay.
                        if vm.showResult && config.mode == .quiz {
                            Color.clear
                                .contentShape(Rectangle())
                                .ignoresSafeArea()
                                .onTapGesture { advance() }
                                .gesture(DragGesture(minimumDistance: 30).onEnded { _ in advance() })
                        }

                        // Typing: full-screen feedback overlay
                        if vm.showResult && config.mode == .typing {
                            Color.black.opacity(0.4).ignoresSafeArea()

                            Color.clear
                                .contentShape(Rectangle())
                                .ignoresSafeArea()
                                .onTapGesture { advance() }
                                .gesture(DragGesture(minimumDistance: 30).onEnded { _ in advance() })

                            AnswerFeedbackOverlay(
                                isCorrect: vm.lastAnswerCorrect,
                                questionText: vm.currentFront,
                                correctText: vm.currentBack,
                                userAnswer: lastUserAnswer,
                                lang: lang)
                            .allowsHitTesting(false)
                        }
                    }
                }

                Spacer()
            }
        }
        .onChange(of: vm.isSessionFinished) { finished in
            if finished {
                finalResult = vm.buildResult()
                showResults = true
            }
        }
        .onChange(of: typingInput) { newValue in
            // While feedback is shown, a keystroke on the keyboard (which the
            // system keyboard captures, not our tap layer) also advances.
            // Keyboard never has to disappear in typing mode.
            if vm.showResult && config.mode == .typing && !newValue.isEmpty {
                typingInput = ""
                advance()
            }
        }
        .onAppear {
            if config.mode == .typing { inputFocused = true }
        }
        .onDisappear {
            // save wrong answers even if user exits early (taps X)
            if !sessionSaved && !vm.wrongCardIDs.isEmpty {
                save(vm.buildResult())
            }
        }
        .fullScreenCover(isPresented: $showResults) {
            if let result = finalResult {
                ResultsView(result: result, deckName: deck.name, deck: deck, config: config)
                    .onDisappear {
                        save(result)
                        sessionSaved = true
                        dismiss()
                    }
            }
        }
    }

    @ViewBuilder
    private func cardContent(item: SessionItem) -> some View {
        switch config.mode {
        case .typing:  typingCard(item: item)
        case .show:    showCard(item: item)
        case .quiz:    quizCard(item: item)
        }
    }

    // MARK: - Typing mode

    @ViewBuilder
    private func typingCard(item: SessionItem) -> some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 8) {
                Spacer()
                Text(vm.currentFront)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Spacer()
                Button { audio.speak(vm.currentFront) } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3).foregroundStyle(Color.mnemoGreen.opacity(0.7))
                }
                .padding(.trailing, 32)
            }

            TextField(lang.studyTypeAnswer, text: $typingInput)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit { checkTyping() }
                .focused($inputFocused)
                // Hide the predictive/QuickType bar (covers feedback + would
                // suggest the answer) and stop autocapitalization mangling input.
                // NOTE: no .keyboardType restriction — must allow accents/CJK.
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 32)

            PrimaryButton(title: lang.studyCheck) { checkTyping() }
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Show mode (answer revealed first, then judge)

    @ViewBuilder
    private func showCard(item: SessionItem) -> some View {
        VStack(spacing: 28) {
            HStack(alignment: .top, spacing: 8) {
                Spacer()
                Text(vm.currentFront)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Spacer()
                Button { audio.speak(vm.currentFront) } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3).foregroundStyle(Color.mnemoGreen.opacity(0.7))
                }
                .padding(.trailing, 32)
            }

            if showingBack {
                HStack(spacing: 8) {
                    Text(vm.currentBack)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.mnemoGold)
                        .multilineTextAlignment(.center)
                        .padding(.leading, 32)
                    Button { audio.speak(vm.currentBack) } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.callout).foregroundStyle(Color.mnemoGold.opacity(0.7))
                    }
                    .padding(.trailing, 32)
                }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                HStack(spacing: 16) {
                    Button {
                        vm.submitShow(knows: false)
                        haptic(correct: false)
                        advance()
                    } label: {
                        Text(lang.studyDontKnow)
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        vm.submitShow(knows: true)
                        haptic(correct: true)
                        advance()
                    } label: {
                        Text(lang.studyKnow)
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.mnemoGreen, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Button {
                    withAnimation(.spring(duration: 0.4)) { showingBack = true }
                } label: {
                    Text(lang.studyReveal)
                        .font(.headline).foregroundStyle(Color.mnemoGreen)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.mnemoGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.mnemoGreen.opacity(0.4), lineWidth: 1))
                }
                .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Quiz mode

    @ViewBuilder
    private func quizCard(item: SessionItem) -> some View {
        VStack(spacing: 24) {
            Text(vm.currentFront)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 10) {
                ForEach(vm.quizOptions, id: \.self) { option in
                    Button {
                        guard !vm.showResult else { advance(); return }
                        selectedQuiz  = option
                        lastUserAnswer = option
                        vm.submitQuiz(choice: option)
                        haptic(correct: vm.lastAnswerCorrect)
                    } label: {
                        Text(option)
                            .font(.body).foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(quizOptionColor(option), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(quizOptionBorder(option), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }

    // Inline quiz highlight after answering
    private func quizOptionColor(_ option: String) -> Color {
        guard vm.showResult else { return Color.mnemoSurface }
        if option == vm.currentExpectedAnswer { return Color.mnemoGreen.opacity(0.85) }
        if option == selectedQuiz             { return Color.red.opacity(0.7) }
        return Color.mnemoSurface
    }
    private func quizOptionBorder(_ option: String) -> Color {
        guard vm.showResult else { return Color.white.opacity(0.1) }
        if option == vm.currentExpectedAnswer || option == selectedQuiz { return Color.white.opacity(0.4) }
        return Color.white.opacity(0.1)
    }

    // MARK: - Helpers

    private func haptic(correct: Bool) {
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
    }

    private func checkTyping() {
        lastUserAnswer = typingInput
        vm.submitTyping(typingInput)
        typingInput = ""
        haptic(correct: vm.lastAnswerCorrect)
    }

    private func advance() {
        vm.advanceAfterResult()
        showingBack  = false
        selectedQuiz = nil
        if config.mode == .typing { inputFocused = true }
    }
}

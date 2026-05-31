import SwiftUI

struct StudyView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var deck: Deck
    var config: StudyConfig

    @StateObject private var vm: StudyViewModel
    @State private var typingInput = ""
    @State private var showResults = false
    @FocusState private var inputFocused: Bool

    var lang: AppLanguage { settings.language }

    init(deck: Deck, config: StudyConfig) {
        self.deck   = deck
        self.config = config
        _vm = StateObject(wrappedValue: StudyViewModel(deck: deck, config: config, allDecks: []))
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
                    // balance
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

                // Card
                if let item = vm.currentItem {
                    ZStack {
                        cardContent(item: item)

                        // Inline answer feedback
                        if vm.showResult {
                            Color.black.opacity(0.4).ignoresSafeArea()
                            AnswerFeedbackOverlay(
                                isCorrect: vm.lastAnswerCorrect,
                                correctText: vm.currentBack,
                                lang: lang)
                            .onTapGesture { advance() }
                        }
                    }
                }

                Spacer()
            }
        }
        .onChange(of: vm.isSessionFinished) { finished in
            if finished { showResults = true }
        }
        .onAppear {
            if config.mode == .typing { inputFocused = true }
        }
        .fullScreenCover(isPresented: $showResults) {
            ResultsView(result: vm.buildResult(), deckName: deck.name)
                .onDisappear {
                    library.recordSession(result: vm.buildResult(), srsEnabled: settings.srsEnabled)
                    dismiss()
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
            Text(vm.currentFront)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField(lang.studyTypeAnswer, text: $typingInput)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit { checkTyping() }
                .focused($inputFocused)
                .padding(.horizontal, 32)

            PrimaryButton(title: lang.studyCheck) { checkTyping() }
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Show mode

    @ViewBuilder
    private func showCard(item: SessionItem) -> some View {
        VStack(spacing: 32) {
            Text(vm.currentFront)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 16) {
                Button {
                    vm.submitShow(knows: false)
                    showResultThenAdvance()
                } label: {
                    Text(lang.studyDontKnow)
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    vm.submitShow(knows: true)
                    showResultThenAdvance()
                } label: {
                    Text(lang.studyKnow)
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.mnemoGreen, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
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
                        vm.submitQuiz(choice: option)
                        showResultThenAdvance()
                    } label: {
                        Text(option)
                            .font(.body).foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers

    private func checkTyping() {
        vm.submitTyping(typingInput)
        typingInput = ""
        showResultThenAdvance()
    }

    private func showResultThenAdvance() {
        // result overlay is shown; user taps it to continue (handled in AnswerFeedbackOverlay tap)
    }

    private func advance() {
        vm.advanceAfterResult()
        if config.mode == .typing { inputFocused = true }
    }
}

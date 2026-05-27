import SwiftUI
  import UIKit

  struct QuizView: View {
      @StateObject var vm: QuizViewModel
      @ObservedObject var library: LibraryViewModel
      @EnvironmentObject private var lm: LanguageManager
      let onDismiss: () -> Void

      @State private var userInput: String = ""
      @State private var hintShown: Bool   = false
      @State private var sessionRecorded: Bool  = false
      @State private var showGoalComplete: Bool = false
      @AppStorage("studyGoalMinutes")  private var studyGoalMinutes: Int    = 0
      @AppStorage("lastGoalMetDate")   private var lastGoalMetDate: String  = ""
      @FocusState private var inputFocused: Bool
      @Environment(\.horizontalSizeClass) private var sizeClass

      private var isWide: Bool { sizeClass == .regular }

      var body: some View {
          ZStack {
              Color.appBackground.ignoresSafeArea()
                  .onTapGesture { inputFocused = false }

              Group {
                  switch vm.phase {
                  case .question:
                      questionView
                  case .flashcardRevealed:
                      flashcardRevealedView
                  case .srsRevealed:
                      srsRevealedView
                  case .revealed(let correct):
                      revealedView(correct: correct)
                  case .batchComplete(let correct, let total):
                      BatchCompleteView(
                          correct: correct,
                          total: total,
                          batchIndex: vm.batchIndex,
                          totalBatches: vm.totalBatches
                      ) {
                          vm.advanceBatch()
                          userInput = ""
                          hintShown = false
                      }
                  case .wrongWordsOffer:
                      WrongWordsOfferView(
                          wrongCount: vm.wrongWordsCount,
                          onReview: {
                              userInput = ""
                              hintShown = false
                              vm.startWrongWordsReview()
                          },
                          onSkip: { vm.skipWrongWordsReview() }
                      )
                  case .allDone:
                      AllDoneView(
                          correct: vm.sessionCorrect,
                          total: vm.sessionTotal,
                          bestStreak: vm.bestStreak,
                          onFinish: onDismiss
                      )
                  }
              }
              .transition(.asymmetric(
                  insertion: .move(edge: .trailing).combined(with: .opacity),
                  removal:   .move(edge: .leading).combined(with: .opacity)
              ))
              .frame(maxWidth: isWide ? 560 : .infinity)
              .frame(maxWidth: .infinity)

              if showGoalComplete {
                  GoalCompleteView(minutesToday: Int(library.todayStudyMinutes)) {
                      showGoalComplete = false
                  }
                  .transition(.opacity.combined(with: .scale(scale: 0.96)))
                  .zIndex(10)
              }
          }
          .animation(.spring(response: 0.30, dampingFraction: 0.82), value: vm.phase)
          .animation(
              .spring(response: 0.40, dampingFraction: 0.80),
              value: showGoalComplete
          )
          .navigationBarBackButtonHidden(true)
          .toolbar {
              ToolbarItem(placement: .navigationBarLeading) {
                  Button(action: saveAndDismiss) {
                      HStack(spacing: 4) {
                          Image(systemName: "xmark")
                          Text(lm.s.quit)
                      }
                      .font(.system(.subheadline))
                      .fontWeight(.medium)
                  }
                  .foregroundStyle(.secondary)
              }
              ToolbarItem(placement: .principal) {
                  if vm.totalBatches > 1 {
                      Text(lm.s.batchProgress(vm.batchIndex, vm.totalBatches))
                          .font(.caption.bold())
                          .foregroundStyle(.secondary)
                  }
              }
          }
          .onChange(of: vm.phase) { newPhase in
              switch newPhase {
              case .flashcardRevealed, .srsRevealed:
                  UIImpactFeedbackGenerator(style: .light).impactOccurred()
              case .revealed(let correct):
                  let style: UIImpactFeedbackGenerator.FeedbackStyle =
                      correct ? .medium : .rigid
                  UIImpactFeedbackGenerator(style: style).impactOccurred()
              case .allDone:
                  if !sessionRecorded {
                      sessionRecorded = true
                      library.recordSession(result: vm.buildResult())
                      checkGoalCompletion()
                  }
              default:
                  break
              }
          }
          .onChange(of: vm.currentCard?.id) { _ in
              hintShown = false
              userInput = ""
          }
      }

      private func saveAndDismiss() {
          if case .allDone = vm.phase { onDismiss(); return }
          library.recordSession(result: vm.buildResult())
          onDismiss()
      }

      private func checkGoalCompletion() {
          guard studyGoalMinutes > 0 else { return }
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd"
          let today = formatter.string(from: Date())
          guard lastGoalMetDate != today else { return }
          if library.todayStudyMinutes >= Double(studyGoalMinutes) {
              lastGoalMetDate = today
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  showGoalComplete = true
              }
          }
      }

      // MARK: - Question view

      private var questionView: some View {
          VStack(spacing: 0) {
              progressBar
              Spacer()

              VStack(spacing: 24) {
                  Text(lm.s.translate)
                      .font(.caption.bold())
                      .foregroundStyle(Color.khaki.opacity(0.7))
                      .textCase(.uppercase)
                      .tracking(1.5)

                  Text(vm.currentCard?.questionText ?? "")
                      .font(.system(size: 36, weight: .bold, design: .rounded))
                      .multilineTextAlignment(.center)
                      .padding(.horizontal, 28)
                      .padding(.vertical, 36)
                      .frame(maxWidth: .infinity)
                      .glassCard(cornerRadius: 24)
                      .padding(.horizontal, 20)
              }

              Spacer()

              if vm.isSRS {
                  srsRevealButton
              } else {
                  switch vm.quizMode {
                  case .typing:          typingInputArea
                  case .flashcard:       flashcardRevealButton
                  case .multipleChoice:  multipleChoiceArea
                  }
              }
          }
          .onAppear {
              if vm.quizMode == .typing && !vm.isSRS { inputFocused = true }
          }
      }

      // MARK: - Typing

      private var typingInputArea: some View {
          VStack(spacing: 12) {
              hintRow

              TextField(lm.s.yourAnswer, text: $userInput)
                  .font(.title3)
                  .focused($inputFocused)
                  .autocorrectionDisabled()
                  .textInputAutocapitalization(.never)
                  .onSubmit { submitAnswer() }
                  .padding(.horizontal, 20)
                  .padding(.vertical, 16)
                  .glassCard(cornerRadius: 16)
                  .padding(.horizontal, 20)

              Button(action: submitAnswer) {
                  Text(lm.s.check)
                      .font(.system(.body))
                      .fontWeight(.semibold)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 16)
                      .background(
                          userInput.trimmingCharacters(in: .whitespaces).isEmpty
                              ? Color.khaki.opacity(0.3) : Color.khaki,
                          in: RoundedRectangle(cornerRadius: 20)
                      )
                      .foregroundStyle(Color.appBackground)
              }
              .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
              .padding(.horizontal, 20)
              .padding(.bottom, 24)
          }
      }

      @ViewBuilder
      private var hintRow: some View {
          if hintShown {
              Text(hintText)
                  .font(.system(.callout, design: .monospaced))
                  .foregroundStyle(Color.khaki)
                  .transition(.opacity.combined(with: .scale(scale: 0.95)))
          } else {
              Button {
                  withAnimation(.spring(response: 0.3)) { hintShown = true }
              } label: {
                  Label(lm.s.hintBtn, systemImage: "lightbulb")
                      .font(.caption.bold())
                      .foregroundStyle(Color.khaki.opacity(0.8))
              }
          }
      }

      private var hintText: String {
          guard let answer = vm.currentCard?.answerText,
                !answer.isEmpty else { return "" }
          let first = answer.components(separatedBy: "/").first?
              .trimmingCharacters(in: .whitespaces) ?? answer
          let dots = String(repeating: "•", count: max(0, first.count - 1))
          return String(first.prefix(1)) + dots
      }

      private func submitAnswer() {
          guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty
          else { return }
          vm.submitAnswer(userInput: userInput)
          inputFocused = false
      }

      // MARK: - Flashcard

      private var flashcardRevealButton: some View {
          Button(action: { vm.flashcardReveal() }) {
              Text(lm.s.flashcardRevealBtn)
                  .font(.system(.body))
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 16)
                  .background(Color.khaki, in: RoundedRectangle(cornerRadius: 20))
                  .foregroundStyle(Color.appBackground)
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 24)
      }

      private var flashcardRevealedView: some View {
          VStack(spacing: 0) {
              progressBar
              Spacer()

              VStack(spacing: 20) {
                  Text(vm.currentCard?.questionText ?? "")
                      .font(.callout)
                      .foregroundStyle(.secondary)

                  Text(vm.currentCard?.answerText ?? "")
                      .font(.system(size: 34, weight: .bold, design: .rounded))
                      .multilineTextAlignment(.center)
                      .foregroundStyle(Color.khaki)
                      .padding(.horizontal, 28)
                      .padding(.vertical, 32)
                      .frame(maxWidth: .infinity)
                      .glassCard(cornerRadius: 24)
                      .padding(.horizontal, 20)
              }

              Spacer()

              HStack(spacing: 12) {
                  Button(action: { vm.flashcardAnswer(knew: false) }) {
                      Text(lm.s.flashcardDontKnow)
                          .font(.system(.body)).fontWeight(.semibold)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 16)
                          .background(
                              Color.appError,
                              in: RoundedRectangle(cornerRadius: 20)
                          )
                          .foregroundStyle(Color.appBackground)
                  }
                  Button(action: { vm.flashcardAnswer(knew: true) }) {
                      Text(lm.s.flashcardKnow)
                          .font(.system(.body)).fontWeight(.semibold)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 16)
                          .background(
                              Color.appSuccess,
                              in: RoundedRectangle(cornerRadius: 20)
                          )
                          .foregroundStyle(Color.appBackground)
                  }
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 24)
          }
      }

      // MARK: - SRS

      private var srsRevealButton: some View {
          Button(action: { vm.srsReveal() }) {
              Text(lm.s.flashcardRevealBtn)
                  .font(.system(.body))
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 16)
                  .background(Color.khaki, in: RoundedRectangle(cornerRadius: 20))
                  .foregroundStyle(Color.appBackground)
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 24)
      }

      private var srsRevealedView: some View {
          VStack(spacing: 0) {
              progressBar
              Spacer()
              VStack(spacing: 20) {
                  Text(vm.currentCard?.questionText ?? "")
                      .font(.callout)
                      .foregroundStyle(.secondary)
                  Text(vm.currentCard?.answerText ?? "")
                      .font(.system(size: 34, weight: .bold, design: .rounded))
                      .multilineTextAlignment(.center)
                      .foregroundStyle(Color.khaki)
                      .padding(.horizontal, 28)
                      .padding(.vertical, 32)
                      .frame(maxWidth: .infinity)
                      .glassCard(cornerRadius: 24)
                      .padding(.horizontal, 20)
              }
              Spacer()
              srsRatingButtons
          }
      }

      private var srsRatingButtons: some View {
          HStack(spacing: 10) {
              SRSRatingButton(
                  label: lm.s.srsAgain,
                  color: Color.appError
              ) { vm.rateSRS(rating: .again) }
              SRSRatingButton(
                  label: lm.s.srsHard,
                  color: .orange
              ) { vm.rateSRS(rating: .hard) }
              SRSRatingButton(
                  label: lm.s.srsGood,
                  color: Color.appSuccess
              ) { vm.rateSRS(rating: .good) }
              SRSRatingButton(
                  label: lm.s.srsEasy,
                  color: .blue
              ) { vm.rateSRS(rating: .easy) }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 24)
      }

      // MARK: - Multiple choice

      private var multipleChoiceArea: some View {
          VStack(spacing: 10) {
              ForEach(vm.currentOptions, id: \.self) { option in
                  Button(action: { vm.selectOption(option) }) {
                      Text(option)
                          .font(.system(.body))
                          .fontWeight(.medium)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .padding(.horizontal, 18)
                          .padding(.vertical, 14)
                          .glassCard(cornerRadius: 14)
                          .foregroundStyle(.primary)
                  }
              }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 24)
      }

      // MARK: - Revealed

      @ViewBuilder
      private func revealedView(correct: Bool) -> some View {
          VStack(spacing: 0) {
              progressBar
              Spacer()

              VStack(spacing: 20) {
                  HStack(spacing: 8) {
                      Image(
                          systemName: correct
                              ? "checkmark.circle.fill"
                              : "xmark.circle.fill"
                      )
                      .font(.system(size: 22, weight: .semibold))
                      Text(correct ? lm.s.correctAnswer : lm.s.wrongAnswer)
                          .font(.system(.title3))
                          .fontWeight(.bold)
                  }
                  .foregroundStyle(correct ? Color.appSuccess : Color.appError)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)
                  .background(
                      (correct ? Color.appSuccess : Color.appError).opacity(0.15),
                      in: Capsule()
                  )

                  VStack(spacing: 12) {
                      HStack(spacing: 8) {
                          Text(vm.currentCard?.questionText ?? "")
                              .font(.callout)
                              .foregroundStyle(.secondary)
                          Image(systemName: "arrow.right")
                              .font(.caption)
                              .foregroundStyle(Color.khaki.opacity(0.6))
                          Text(vm.currentCard?.answerText ?? "")
                              .font(.system(.title2))
                              .fontWeight(.bold)
                              .foregroundStyle(Color.khaki)
                      }
                      .multilineTextAlignment(.center)

                      if !correct {
                          let sel = vm.quizMode == .typing
                              ? userInput
                              : vm.lastSelectedOption
                          if !sel.isEmpty {
                              HStack(spacing: 4) {
                                  Text(lm.s.yourAnswerWas)
                                      .foregroundStyle(.secondary)
                                  Text(sel)
                                      .strikethrough()
                                      .foregroundStyle(Color.appError)
                              }
                              .font(.callout)
                          }
                      }
                  }
                  .padding(.horizontal, 24)
                  .padding(.vertical, 28)
                  .frame(maxWidth: .infinity)
                  .glassCard(cornerRadius: 24)
                  .padding(.horizontal, 20)

                  if vm.currentStreak >= 10 {
                      HStack(spacing: 6) {
                          Image(systemName: "flame.fill")
                          Text("\(vm.currentStreak)\(lm.s.inRow)")
                              .fontWeight(.bold)
                      }
                      .font(.callout)
                      .foregroundStyle(Color.khaki)
                      .padding(.horizontal, 16)
                      .padding(.vertical, 8)
                      .background(Color.khaki.opacity(0.15), in: Capsule())
                  }
              }

              Spacer()

              Button(action: {
                  userInput = ""
                  hintShown = false
                  vm.advanceAfterReveal()
                  if vm.quizMode == .typing { inputFocused = true }
              }) {
                  Text(lm.s.continueBtn)
                      .font(.system(.body))
                      .fontWeight(.semibold)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 16)
                      .background(
                          correct ? Color.appSuccess : Color.appError,
                          in: RoundedRectangle(cornerRadius: 20)
                      )
                      .foregroundStyle(Color.appBackground)
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 24)
          }
      }

      // MARK: - Progress bar

      private var progressBar: some View {
          GeometryReader { geo in
              ZStack(alignment: .leading) {
                  RoundedRectangle(cornerRadius: 3)
                      .fill(Color.khakiCard)
                      .frame(height: 3)
                  RoundedRectangle(cornerRadius: 3)
                      .fill(Color.khaki)
                      .frame(width: geo.size.width * vm.progress, height: 3)
                      .animation(.spring(response: 0.4), value: vm.progress)
              }
          }
          .frame(height: 3)
          .padding(.horizontal, 20)
          .padding(.top, 12)
      }
  }

  // MARK: - Batch Complete

  struct BatchCompleteView: View {
      @EnvironmentObject private var lm: LanguageManager
      let correct: Int
      let total: Int
      let batchIndex: Int
      let totalBatches: Int
      let onContinue: () -> Void

      var accuracy: Double {
          total > 0 ? Double(correct) / Double(total) : 0
      }
      var isLast: Bool { batchIndex >= totalBatches }

      var body: some View {
          VStack(spacing: 0) {
              Spacer()
              VStack(spacing: 32) {
                  Text(lm.s.batchDone(batchIndex))
                      .font(.system(.title, design: .rounded))
                      .fontWeight(.bold)
                  ZStack {
                      Circle()
                          .stroke(Color.khakiCard, lineWidth: 14)
                          .frame(width: 140, height: 140)
                      Circle()
                          .trim(from: 0, to: accuracy)
                          .stroke(
                              accuracyColor,
                              style: StrokeStyle(lineWidth: 14, lineCap: .round)
                          )
                          .rotationEffect(.degrees(-90))
                          .frame(width: 140, height: 140)
                          .animation(.spring(response: 0.8), value: accuracy)
                      VStack(spacing: 2) {
                          Text("\(Int(accuracy * 100))%")
                              .font(.system(.title2, design: .rounded))
                              .fontWeight(.bold)
                              .monospacedDigit()
                          Text("\(correct)/\(total)")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                              .monospacedDigit()
                      }
                  }
                  if !isLast {
                      Text(lm.s.prepareForBatch(batchIndex + 1, totalBatches))
                          .foregroundStyle(.secondary)
                          .font(.callout)
                  }
              }
              Spacer()
              Button(action: onContinue) {
                  Text(isLast ? lm.s.showResults : lm.s.nextBatch)
                      .font(.system(.body))
                      .fontWeight(.semibold)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 16)
                      .background(
                          Color.khaki,
                          in: RoundedRectangle(cornerRadius: 20)
                      )
                      .foregroundStyle(Color.appBackground)
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 24)
          }
          .padding()
      }

      var accuracyColor: Color {
          accuracy >= 0.8 ? Color.appSuccess
              : accuracy >= 0.5 ? .orange
              : Color.appError
      }
  }

  // MARK: - All Done

  struct AllDoneView: View {
      @EnvironmentObject private var lm: LanguageManager
      let correct: Int
      let total: Int
      let bestStreak: Int
      let onFinish: () -> Void

      var accuracy: Double {
          total > 0 ? Double(correct) / Double(total) : 0
      }

      var body: some View {
          VStack(spacing: 0) {
              Spacer()
              VStack(spacing: 32) {
                  VStack(spacing: 10) {
                      let headline = accuracy >= 0.9 ? lm.s.excellent
                          : accuracy >= 0.7 ? lm.s.goodJob
                          : lm.s.tryAgain
                      Text(headline)
                          .font(.system(.largeTitle, design: .rounded))
                          .fontWeight(.bold)
                      Text(lm.s.sessionDone)
                          .foregroundStyle(.secondary)
                          .font(.callout)
                  }
                  VStack(spacing: 10) {
                      ResultCard(
                          icon: "checkmark.circle.fill",
                          color: Color.appSuccess,
                          title: lm.s.correctLabel,
                          value: "\(correct) / \(total)"
                      )
                      ResultCard(
                          icon: "percent",
                          color: Color.khaki,
                          title: lm.s.successRate,
                          value: "\(Int(accuracy * 100))%"
                      )
                      ResultCard(
                          icon: "flame.fill",
                          color: .orange,
                          title: lm.s.bestStreakLabel,
                          value: "\(bestStreak)×"
                      )
                  }
                  .padding(.horizontal, 20)
              }
              Spacer()
              Button(action: onFinish) {
                  Text(lm.s.backToLibrary)
                      .font(.system(.body))
                      .fontWeight(.semibold)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 16)
                      .background(
                          Color.khaki,
                          in: RoundedRectangle(cornerRadius: 20)
                      )
                      .foregroundStyle(Color.appBackground)
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 24)
          }
      }
  }

  struct ResultCard: View {
      let icon: String
      let color: Color
      let title: String
      let value: String

      var body: some View {
          HStack {
              Image(systemName: icon)
                  .font(.title2)
                  .foregroundStyle(color)
                  .frame(width: 36)
              Text(title).foregroundStyle(.secondary)
              Spacer()
              Text(value)
                  .font(.system(.title3))
                  .fontWeight(.bold)
                  .monospacedDigit()
          }
          .padding(16)
          .glassCard(cornerRadius: 16)
      }
  }

  // MARK: - Wrong Words Offer

  struct WrongWordsOfferView: View {
      @EnvironmentObject private var lm: LanguageManager
      let wrongCount: Int
      let onReview: () -> Void
      let onSkip: () -> Void

      var body: some View {
          VStack(spacing: 0) {
              Spacer()

              VStack(spacing: 32) {
                  ZStack {
                      Circle()
                          .fill(Color.appError.opacity(0.15))
                          .frame(width: 90, height: 90)
                      Image(systemName: "exclamationmark.triangle.fill")
                          .font(.system(size: 38))
                          .foregroundStyle(Color.appError)
                  }

                  VStack(spacing: 10) {
                      Text(lm.s.wrongWordsOfferTitle)
                          .font(.system(.title2, design: .rounded))
                          .fontWeight(.bold)
                      Text(lm.s.wrongWordsOfferBody(wrongCount))
                          .font(.callout)
                          .foregroundStyle(.secondary)
                          .multilineTextAlignment(.center)
                          .padding(.horizontal, 32)
                  }
              }

              Spacer()

              VStack(spacing: 12) {
                  Button(action: onReview) {
                      Text(lm.s.reviewWrongBtn)
                          .font(.system(.body))
                          .fontWeight(.semibold)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 16)
                          .background(
                              Color.appError,
                              in: RoundedRectangle(cornerRadius: 20)
                          )
                          .foregroundStyle(Color.appBackground)
                  }

                  Button(action: onSkip) {
                      Text(lm.s.skipToResultsBtn)
                          .font(.system(.body))
                          .fontWeight(.medium)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 16)
                          .background(
                              Color.khakiCard,
                              in: RoundedRectangle(cornerRadius: 20)
                          )
                          .foregroundStyle(.primary)
                  }
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 24)
          }
      }
  }

  // MARK: - SRS Rating Button

  private struct SRSRatingButton: View {
      let label: String
      let color: Color
      let action: () -> Void

      var body: some View {
          Button(action: action) {
              Text(label)
                  .font(.system(.subheadline))
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 14)
                  .background(color, in: RoundedRectangle(cornerRadius: 16))
                  .foregroundStyle(.white)
          }
      }
  }

  // MARK: - Goal Complete Overlay

  private struct GoalCompleteView: View {
      @EnvironmentObject private var lm: LanguageManager
      let minutesToday: Int
      let onDismiss: () -> Void

      @State private var appeared = false

      var body: some View {
          ZStack {
              Color.black.opacity(0.88).ignoresSafeArea()

              VStack(spacing: 0) {
                  Spacer()

                  VStack(spacing: 28) {
                      ZStack {
                          Circle()
                              .fill(Color.khaki.opacity(0.08))
                              .frame(width: 170, height: 170)
                              .scaleEffect(appeared ? 1.12 : 0.9)
                              .animation(
                                  .easeInOut(duration: 1.8)
                                      .repeatForever(autoreverses: true),
                                  value: appeared
                              )
                          Circle()
                              .fill(Color.khaki.opacity(0.14))
                              .frame(width: 130, height: 130)
                          Image(systemName: "trophy.fill")
                              .font(.system(size: 58))
                              .foregroundStyle(Color.khaki)
                              .scaleEffect(appeared ? 1 : 0.4)
                              .animation(
                                  .spring(response: 0.5, dampingFraction: 0.55),
                                  value: appeared
                              )
                      }

                      VStack(spacing: 10) {
                          Text(lm.s.goalMetTitle)
                              .font(.system(.largeTitle, design: .rounded))
                              .fontWeight(.bold)
                              .opacity(appeared ? 1 : 0)
                              .offset(y: appeared ? 0 : 12)
                              .animation(
                                  .spring(response: 0.4).delay(0.15),
                                  value: appeared
                              )
                          Text(lm.s.goalMetBody(minutesToday))
                              .font(.callout)
                              .foregroundStyle(.secondary)
                              .multilineTextAlignment(.center)
                              .padding(.horizontal, 36)
                              .opacity(appeared ? 1 : 0)
                              .offset(y: appeared ? 0 : 10)
                              .animation(
                                  .spring(response: 0.4).delay(0.28),
                                  value: appeared
                              )
                      }
                  }

                  Spacer()

                  Button(action: onDismiss) {
                      Text(lm.s.continueBtn)
                          .font(.system(.body))
                          .fontWeight(.semibold)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 16)
                          .background(
                              Color.khaki,
                              in: RoundedRectangle(cornerRadius: 20)
                          )
                          .foregroundStyle(Color.appBackground)
                  }
                  .padding(.horizontal, 20)
                  .padding(.bottom, 24)
                  .opacity(appeared ? 1 : 0)
                  .animation(
                      .easeIn(duration: 0.3).delay(0.45),
                      value: appeared
                  )
              }
          }
          .onAppear { appeared = true }
      }
  }

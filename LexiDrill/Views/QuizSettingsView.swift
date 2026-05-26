import SwiftUI
  import UserNotifications

  struct QuizSettingsView: View {
      let wordList: WordList
      @ObservedObject var library: LibraryViewModel
      @EnvironmentObject private var lm: LanguageManager
      @Environment(\.dismiss) private var dismiss

      @State private var quizMode: QuizMode       = .typing
      @State private var direction: QuizDirection  = .frontToBack
      @State private var batchSize: Double         = 10
      @State private var requiredCorrect: Double   = 2
      @State private var shuffle: Bool             = true
      @State private var startQuiz                 = false
      @State private var settings: QuizSettings?

      private var maxBatch: Double { Double(min(wordList.pairs.count, 50)) }
      private var listStats: ListStatistics { library.stats(for: wordList.id) }

      var body: some View {
          NavigationStack {
              Form {
                  summarySection
                  modeSection
                  directionSection
                  roundSection
                  otherSection
                  editSection
                  statsSection
              }
              .navigationTitle(lm.s.settingsTitle)
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button(lm.s.cancel) { dismiss() }
                  }
                  ToolbarItem(placement: .confirmationAction) {
                      Button {
                          settings = QuizSettings(
                              batchSize: Int(batchSize),
                              requiredCorrect: Int(requiredCorrect),
                              direction: direction,
                              shuffleOrder: shuffle,
                              mode: quizMode
                          )
                          startQuiz = true
                      } label: {
                          Text(lm.s.start).fontWeight(.semibold)
                      }
                  }
              }
              .navigationDestination(isPresented: $startQuiz) {
                  if let s = settings {
                      QuizView(
                          vm: QuizViewModel(wordList: wordList, settings: s,
                                            wordStats: library.wordStats(for:
  wordList.id)),
                          library: library,
                          onDismiss: { dismiss() }
                      )
                  }
              }
          }
      }

      private var summarySection: some View {
          Section {
              HStack(spacing: 14) {
                  ZStack {
                      RoundedRectangle(cornerRadius: 10)
                          .fill(Color.khaki.gradient)
                          .frame(width: 44, height: 44)
                      Image(systemName: "text.book.closed.fill")
                          .foregroundStyle(Color.appBackground)
                          .font(.system(size: 18, weight: .semibold))
                  }
                  VStack(alignment: .leading, spacing: 3) {
                      Text(wordList.name)
                          .font(.system(.body))
                          .fontWeight(.semibold)
                      Text("\(wordList.pairs.count) \(lm.s.wordPairs)")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
                  Spacer()
                  if listStats.totalSessions > 0 {
                      VStack(alignment: .trailing, spacing: 2) {
                          Text("\(Int(listStats.accuracy * 100))%")
                              .font(.system(.title3))
                              .fontWeight(.bold)
                              .foregroundStyle(listStats.accuracy >= 0.8 ?
  Color.appSuccess : listStats.accuracy >= 0.5 ? .orange : Color.appError)
                          Text(lm.s.accuracyLabel)
                              .font(.caption2)
                              .foregroundStyle(.secondary)
                      }
                  }
              }
              .padding(.vertical, 4)
          }
      }

      private var modeSection: some View {
          Section(lm.s.quizModeSection) {
              Picker("", selection: $quizMode) {
                  Text(lm.s.modeTyping).tag(QuizMode.typing)
                  Text(lm.s.modeFlashcard).tag(QuizMode.flashcard)
                  Text(lm.s.modeMultipleChoice).tag(QuizMode.multipleChoice)
              }
              .pickerStyle(.segmented)
              .padding(.vertical, 4)
          }
      }

      private var directionSection: some View {
          Section(lm.s.quizDirection) {
              if let pair = wordList.pairs.first {
                  Picker("", selection: $direction) {
                      Label("\(pair.front)  →  ?", systemImage: "arrow.right")
                          .tag(QuizDirection.frontToBack)
                      Label("\(pair.back)  →  ?", systemImage: "arrow.left")
                          .tag(QuizDirection.backToFront)
                      Label(lm.s.randomDir, systemImage: "arrow.left.arrow.right")
                          .tag(QuizDirection.random)
                  }
                  .pickerStyle(.inline)
                  .labelsHidden()
              }
          }
      }

      private var roundSection: some View {
          Section(lm.s.roundSettings) {
              VStack(alignment: .leading, spacing: 8) {
                  HStack {
                      Text(lm.s.wordsPerBatch).foregroundStyle(.primary)
                      Spacer()
                      Text("\(Int(batchSize))")
                          .font(.system(.body))
                          .fontWeight(.bold)
                          .foregroundStyle(Color.khaki)
                          .monospacedDigit()
                  }
                  Slider(value: $batchSize, in: 3...maxBatch, step: 1)
                      .tint(Color.khaki)
              }
              .padding(.vertical, 4)

              VStack(alignment: .leading, spacing: 8) {
                  HStack {
                      Text(lm.s.correctInRow).foregroundStyle(.primary)
                      Spacer()
                      Text("\(Int(requiredCorrect))×")
                          .font(.system(.body))
                          .fontWeight(.bold)
                          .foregroundStyle(Color.khaki)
                          .monospacedDigit()
                  }
                  Slider(value: $requiredCorrect, in: 1...5, step: 1)
                      .tint(Color.khaki)
                  Text(lm.s.correctInRowHint)
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              .padding(.vertical, 4)
          }
      }

      private var otherSection: some View {
          Section(lm.s.other) {
              Toggle(lm.s.shuffleOrder, isOn: $shuffle)
          }
      }

      private var editSection: some View {
          Section {
              NavigationLink(destination: WordListEditorView(listID: wordList.id)) {
                  Label(lm.s.editWords, systemImage: "square.and.pencil")
              }
              NavigationLink(destination: ListStatsView(listID: wordList.id)) {
                  Label(lm.s.wordStatsTitle, systemImage: "chart.bar.fill")
              }
          }
      }

      @ViewBuilder
      private var statsSection: some View {
          if listStats.totalSessions > 0 {
              Section(lm.s.statistics) {
                  StatRow(label: lm.s.totalSessions,  value:
  "\(listStats.totalSessions)")
                  StatRow(label: lm.s.totalAnswers,   value:
  "\(listStats.totalAnswers)")
                  StatRow(label: lm.s.correctLabel,   value:
  "\(listStats.totalCorrect) (\(Int(listStats.accuracy * 100))%)")
                  StatRow(label: lm.s.bestStreakLabel, value:
  "\(listStats.bestStreak)×")
              }
          }
      }
  }

  struct StatRow: View {
      let label: String
      let value: String

      var body: some View {
          HStack {
              Text(label).foregroundStyle(.secondary)
              Spacer()
              Text(value).fontWeight(.medium).monospacedDigit()
          }
      }
  }

  // MARK: - List Stats View

  struct ListStatsView: View {
      @EnvironmentObject private var vm: LibraryViewModel
      @EnvironmentObject private var lm: LanguageManager

      let listID: UUID

      @State private var showDeleteConfirm = false

      private var list: WordList? { vm.wordLists.first { $0.id == listID } }
      private var ws: [UUID: WordStats] { vm.wordStats(for: listID) }
      private var listStats: ListStatistics { vm.stats(for: listID) }

      var body: some View {
          ZStack {
              Color.appBackground.ignoresSafeArea()

              if listStats.totalSessions == 0 {
                  emptyState
              } else if let list = list {
                  listContent(list: list)
              }
          }
          .navigationTitle(lm.s.wordStatsTitle)
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
              if listStats.totalSessions > 0 {
                  ToolbarItem(placement: .navigationBarTrailing) {
                      Button { showDeleteConfirm = true } label: {
                          Image(systemName: "trash")
                              .foregroundStyle(Color.appError)
                      }
                  }
              }
          }
          .confirmationDialog(lm.s.deleteStatsConfirm,
                              isPresented: $showDeleteConfirm,
                              titleVisibility: .visible) {
              Button(lm.s.deleteStatsBtn, role: .destructive) {
                  vm.deleteStats(for: listID)
              }
              Button(lm.s.cancel, role: .cancel) {}
          } message: {
              Text(lm.s.deleteStatsDesc)
          }
      }

      private func listContent(list: WordList) -> some View {
          List {
              Section {
                  summaryRow
              }
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)

              Section(lm.s.perWordSection) {
                  ForEach(sortedPairs(list.pairs)) { pair in
                      WordStatRow(pair: pair, stats: ws[pair.id])
                          .listRowBackground(Color.clear)
                          .listRowSeparator(.hidden)
                          .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4,
  trailing: 16))
                  }
              }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
      }

      private func sortedPairs(_ pairs: [WordPair]) -> [WordPair] {
          pairs.sorted { a, b in
              let sa = ws[a.id]
              let sb = ws[b.id]
              switch (sa, sb) {
              case (nil, nil): return false
              case (nil, _):   return false
              case (_, nil):   return true
              default:
                  let accA = sa!.attempts > 0 ? sa!.accuracy : 1.0
                  let accB = sb!.attempts > 0 ? sb!.accuracy : 1.0
                  return accA < accB
              }
          }
      }

      private var summaryRow: some View {
          HStack(spacing: 10) {
              StatPill(icon: "percent",    color: accuracyColor(listStats.accuracy),
                       label: lm.s.accuracyLabel,   value: "\(Int(listStats.accuracy *
   100))%")
              StatPill(icon: "calendar",   color: Color.khaki,
                       label: lm.s.totalSessions,   value:
  "\(listStats.totalSessions)")
              StatPill(icon: "flame.fill", color: .orange,
                       label: lm.s.bestStreakLabel,  value:
  "\(listStats.bestStreak)×")
          }
          .padding(.vertical, 4)
      }

      private var emptyState: some View {
          VStack(spacing: 14) {
              Image(systemName: "chart.bar.xaxis")
                  .font(.system(size: 44))
                  .foregroundStyle(Color.khaki.opacity(0.4))
              Text(lm.s.noStatsYet)
                  .font(.callout)
                  .foregroundStyle(.secondary)
          }
      }

      private func accuracyColor(_ a: Double) -> Color {
          a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
      }
  }

  private struct StatPill: View {
      let icon: String; let color: Color; let label: String; let value: String

      var body: some View {
          VStack(spacing: 6) {
              Image(systemName: icon).font(.system(size: 15)).foregroundStyle(color)
              Text(value).font(.system(.body)).fontWeight(.bold).monospacedDigit()
              Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAli
  gnment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .glassCard(cornerRadius: 14)
      }
  }

  private struct WordStatRow: View {
      @EnvironmentObject private var lm: LanguageManager
      let pair: WordPair
      let stats: WordStats?

      var body: some View {
          HStack(spacing: 12) {
              accuracyRing.frame(width: 44, height: 44)

              VStack(alignment: .leading, spacing: 4) {
                  HStack(spacing: 5) {
                      Text(pair.front)

  .font(.system(.subheadline)).fontWeight(.medium).lineLimit(1)
                      Image(systemName: "arrow.right")
                          .font(.system(size:
  9)).foregroundStyle(Color.khaki.opacity(0.5))
                      Text(pair.back)

  .font(.system(.subheadline)).foregroundStyle(Color.khaki).lineLimit(1)
                  }
                  subtitleText
              }

              Spacer(minLength: 0)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .glassCard(cornerRadius: 14)
      }

      @ViewBuilder
      private var accuracyRing: some View {
          ZStack {
              Circle().stroke(Color.khakiBorder.opacity(0.35), lineWidth: 2.5)
              if let s = stats, s.attempts > 0 {
                  Circle()
                      .trim(from: 0, to: CGFloat(s.accuracy))
                      .stroke(ringColor(s.accuracy),
                              style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                      .rotationEffect(.degrees(-90))
                  Text("\(Int(s.accuracy * 100))%")
                      .font(.system(size: 9, weight: .bold))
                      .foregroundStyle(ringColor(s.accuracy))
                      .monospacedDigit()
              } else {
                  Text("—").font(.caption2).foregroundStyle(.secondary)
              }
          }
      }

      @ViewBuilder
      private var subtitleText: some View {
          if let s = stats, s.attempts > 0 {
              HStack(spacing: 6) {
                  Text("\(s.attempts) \(lm.s.attemptsLabel)")
                      .font(.caption).foregroundStyle(.secondary)
                  if s.isDue {
                      Circle().fill(Color.orange).frame(width: 3, height: 3)
                      Text(lm.s.dueLabel).font(.caption).foregroundStyle(.orange)
                  } else if let due = s.dueDate {
                      let days = max(1, Calendar.current.dateComponents([.day], from:
  Date(), to: due).day ?? 1)
                      Circle().fill(Color.secondary.opacity(0.4)).frame(width: 3,
  height: 3)

  Text(lm.s.nextReviewIn(days)).font(.caption).foregroundStyle(.secondary)
                  }
              }
          } else {
              Text(lm.s.notStudiedYet).font(.caption).foregroundStyle(.secondary)
          }
      }

      private func ringColor(_ a: Double) -> Color {
          a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
      }
  }

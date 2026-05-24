import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @EnvironmentObject private var lm: LanguageManager

    @State private var showImportPicker  = false
    @State private var showPasteSheet    = false
    @State private var searchText        = ""
    @State private var editMode: EditMode = .inactive
    @State private var showRenameAlert   = false
    @State private var renameTarget: WordList?
    @State private var renameText        = ""

    // Direct quiz navigation
    @State private var showQuiz      = false
    @State private var selectedList: WordList?

    // Secondary sheets
    @State private var editorTarget: LibraryListTarget?
    @State private var statsTarget:  LibraryListTarget?

    // Read global quiz settings
    @AppStorage("globalQuizMode")        private var quizModeRaw: String  = QuizMode.typing.rawValue
    @AppStorage("globalDirection")       private var directionRaw: String = QuizDirection.frontToBack.rawValue
    @AppStorage("globalBatchSize")       private var batchSize: Int       = 10
    @AppStorage("globalRequiredCorrect") private var requiredCorrect: Int = 2
    @AppStorage("globalShuffle")         private var shuffle: Bool        = true

    private var displayedLists: [WordList] {
        guard editMode == .inactive, !searchText.isEmpty else { return vm.wordLists }
        return vm.wordLists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if vm.wordLists.isEmpty {
                    emptyState
                } else if displayedLists.isEmpty {
                    noResults
                } else {
                    listContent
                }
            }
            .navigationTitle("Mnemo")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: lm.s.searchLists)
            .environment(\.editMode, $editMode)
            .navigationDestination(isPresented: $showQuiz) {
                if let list = selectedList {
                    QuizView(
                        vm: QuizViewModel(
                            wordList: list,
                            settings: buildSettings(for: list),
                            wordStats: vm.wordStats(for: list.id)
                        ),
                        library: vm,
                        onDismiss: { showQuiz = false }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LanguagePicker(selection: $lm.language)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        if !vm.wordLists.isEmpty {
                            Button(editMode == .active ? lm.s.done : lm.s.editBtn) {
                                withAnimation { editMode = editMode == .active ? .inactive : .active }
                            }
                            .font(.system(.subheadline))
                            .fontWeight(.medium)
                        }
                        Menu {
                            Button(action: { showImportPicker = true }) {
                                Label(lm.s.importFile, systemImage: "doc.badge.plus")
                            }
                            Button(action: { showPasteSheet = true }) {
                                Label(lm.s.pasteText, systemImage: "doc.text")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.khaki)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    vm.importFromURL(url, errorFor: { lm.s.errorFor($0) })
                }
            }
            .sheet(isPresented: $showPasteSheet) {
                PasteImportView { text, name in
                    vm.importFromText(text, name: name, errorFor: { lm.s.errorFor($0) })
                }
            }
            .sheet(item: $editorTarget) { target in
                NavigationStack { WordListEditorView(listID: target.id) }
            }
            .sheet(item: $statsTarget) { target in
                NavigationStack { ListStatsView(listID: target.id) }
            }
            .alert(lm.s.rename, isPresented: $showRenameAlert) {
                TextField(lm.s.listNamePlaceholder, text: $renameText)
                Button(lm.s.save) {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    if let target = renameTarget, !trimmed.isEmpty {
                        vm.renameList(id: target.id, newName: trimmed)
                    }
                    renameTarget = nil
                }
                Button(lm.s.cancel, role: .cancel) { renameTarget = nil }
            }
            .alert(lm.s.importError, isPresented: $vm.showError) {
                Button(lm.s.ok, role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .alert(lm.s.dataLoadErrorTitle, isPresented: $vm.dataLoadFailed) {
                Button(lm.s.ok, role: .cancel) {}
            } message: {
                Text(lm.s.dataLoadError)
            }
        }
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(displayedLists) { list in
                WordListCard(
                    list: list,
                    stats: vm.stats(for: list.id),
                    isImported: vm.isImported(list),
                    isComplete: vm.isComplete(list),
                    dueCount: vm.dueWordCount(for: list),
                    nextReviewDate: vm.nextReviewDate(for: list)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    guard editMode == .inactive else { return }
                    selectedList = list
                    showQuiz = true
                }
                .contextMenu {
                    Button {
                        statsTarget = LibraryListTarget(id: list.id)
                    } label: {
                        Label(lm.s.wordStatsTitle, systemImage: "chart.bar.fill")
                    }
                    Button {
                        editorTarget = LibraryListTarget(id: list.id)
                    } label: {
                        Label(lm.s.editWords, systemImage: "square.and.pencil")
                    }
                    Divider()
                    Button {
                        renameTarget = list
                        renameText = list.name
                        showRenameAlert = true
                    } label: {
                        Label(lm.s.rename, systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        if let idx = vm.wordLists.firstIndex(where: { $0.id == list.id }) {
                            vm.deleteList(at: IndexSet(integer: idx))
                        }
                    } label: {
                        Label(lm.s.delete, systemImage: "trash")
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .onDelete { offsets in
                let ids = offsets.map { displayedLists[$0].id }
                let real = IndexSet(ids.compactMap { id in
                    vm.wordLists.firstIndex(where: { $0.id == id })
                })
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    vm.deleteList(at: real)
                }
            }
            .onMove(perform: vm.moveList)
        }
        .listStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: vm.wordLists.count)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty / No Results

    private var noResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(lm.s.noResults)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.khaki.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.khaki)
                }

                VStack(spacing: 8) {
                    Text(lm.s.noLists)
                        .font(.title2.bold())
                    Text(lm.s.emptyStateDesc)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }

            VStack(spacing: 12) {
                Button(action: { showImportPicker = true }) {
                    Label(lm.s.importFileButton, systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: { showPasteSheet = true }) {
                    Label(lm.s.pasteText, systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Helpers

private struct LibraryListTarget: Identifiable { let id: UUID }

extension LibraryView {
    func buildSettings(for list: WordList) -> QuizSettings {
        QuizSettings(
            batchSize: max(1, min(batchSize, list.pairs.count)),
            requiredCorrect: requiredCorrect,
            direction: QuizDirection(rawValue: directionRaw) ?? .frontToBack,
            shuffleOrder: shuffle,
            mode: QuizMode(rawValue: quizModeRaw) ?? .typing
        )
    }
}

// MARK: - Language Picker

private struct LanguagePicker: View {
    @Binding var selection: Language

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Language.allCases) { lang in
                Button(lang.displayName) { selection = lang }
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        selection == lang ? Color.khaki : Color.khakiCard,
                        in: Capsule()
                    )
                    .foregroundStyle(selection == lang ? Color.appBackground : .primary)
                    .animation(.spring(response: 0.2), value: selection)
            }
        }
    }
}

// MARK: - Word List Card

private struct WordListCard: View {
    @EnvironmentObject private var lm: LanguageManager
    let list: WordList
    let stats: ListStatistics
    let isImported: Bool
    let isComplete: Bool
    let dueCount: Int
    let nextReviewDate: Date?

    private let iconColors: [Color] = [
        Color(red: 0.34, green: 0.52, blue: 0.24),
        Color(red: 0.28, green: 0.48, blue: 0.30),
        Color(red: 0.40, green: 0.58, blue: 0.22),
        Color(red: 0.22, green: 0.44, blue: 0.28),
        Color(red: 0.36, green: 0.55, blue: 0.26),
        Color(red: 0.30, green: 0.50, blue: 0.35),
        Color(red: 0.44, green: 0.60, blue: 0.28),
        Color(red: 0.26, green: 0.46, blue: 0.22)
    ]

    private var iconColor: Color {
        let hash = list.name.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        return iconColors[abs(hash) % iconColors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(iconColor)
                        .frame(width: 52, height: 52)
                    Image(systemName: isComplete ? "checkmark.seal.fill" : "text.book.closed.fill")
                        .foregroundStyle(Color.appBackground.opacity(0.9))
                        .font(.system(size: 20, weight: .semibold))
                }

                if isImported && !isComplete {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.appBackground)
                        .background(iconColor, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.system(.body))
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text("\(list.pairs.count) \(lm.s.pairs)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let studiedText = lastStudiedText {
                        Circle()
                            .fill(.secondary.opacity(0.4))
                            .frame(width: 3, height: 3)
                        Text(studiedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isComplete {
                        Circle()
                            .fill(Color.appSuccess.opacity(0.6))
                            .frame(width: 3, height: 3)
                        Text(lm.s.completed)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appSuccess)
                    } else if stats.totalSessions > 0 {
                        Circle()
                            .fill(.secondary.opacity(0.4))
                            .frame(width: 3, height: 3)
                        Text("\(Int(stats.accuracy * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(accuracyColor(stats.accuracy))
                    }
                }

                if stats.totalSessions > 0 {
                    reviewBadge
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.khaki.opacity(0.5))
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private func accuracyColor(_ a: Double) -> Color {
        a >= 0.8 ? Color.appSuccess : a >= 0.5 ? Color.orange : Color.appError
    }

    private var lastStudiedText: String? {
        guard let date = list.lastStudied else { return nil }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return lm.s.lastStudiedToday }
        if days == 1 { return lm.s.lastStudiedYesterday }
        return lm.s.lastStudiedDaysAgo(days)
    }

    private var daysUntilReview: Int? {
        guard let next = nextReviewDate else { return nil }
        return max(1, Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 1)
    }

    @ViewBuilder
    private var reviewBadge: some View {
        if dueCount > 0 {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 5, height: 5)
                Text(lm.s.dueNow(dueCount))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.orange)
            }
        } else if let days = daysUntilReview {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 5, height: 5)
                Text(lm.s.nextReviewIn(days))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Shared Design System

extension Color {
    static let khaki         = Color(red: 0.34, green: 0.50, blue: 0.18)
    static let khakiCard     = Color(red: 0.04, green: 0.07, blue: 0.02)
    static let khakiBorder   = Color(red: 0.14, green: 0.25, blue: 0.07)
    static let appBackground = Color(red: 0.01, green: 0.02, blue: 0.01)
    static let appSuccess    = Color(red: 0.20, green: 0.60, blue: 0.21)
    static let appError      = Color(red: 0.62, green: 0.21, blue: 0.17)
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.05, green: 0.08, blue: 0.03).opacity(0.48))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.07),
                                Color(red: 0.18, green: 0.38, blue: 0.08).opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 18, x: 0, y: 7)
    }
}

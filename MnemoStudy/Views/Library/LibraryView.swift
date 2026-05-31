import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @State private var searchText        = ""
    @State private var showAddMenu       = false
    @State private var showNewDeck       = false
    @State private var showNewFolder     = false
    @State private var showImport        = false
    @State private var selectedDeck: Deck?
    @State private var editingDeck: Deck?
    @State private var newFolderName     = ""
    @State private var editMode: EditMode = .inactive

    var lang: AppLanguage { settings.language }

    var filteredDecks: [Deck] {
        let base = library.decks.filter { !$0.isTemporary }
        if searchText.isEmpty { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Standalone decks (no folder)
                        let standalone = filteredDecks.filter { $0.folderID == nil }
                        ForEach(standalone) { deck in
                            deckSection(deck: deck)
                        }

                        // Folders
                        ForEach(library.folders) { folder in
                            FolderSection(folder: folder, lang: lang,
                                          onTapDeck: tapDeck,
                                          onEdit: { editingDeck = $0 },
                                          onDelete: { library.deleteDeck(id: $0) },
                                          onDeleteFolder: { library.deleteFolder(id: $0) })
                        }

                        // Empty state
                        if filteredDecks.isEmpty && library.folders.isEmpty && searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 52))
                                    .foregroundStyle(Color.mnemoGreen.opacity(0.5))
                                Text(lang.libraryEmpty)
                                    .font(.title3).fontWeight(.semibold).foregroundStyle(.white)
                                Text("Tap + to add a deck or import a file")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        }
                    }
                    .padding(16)
                }
                .searchable(text: $searchText, prompt: lang.librarySearch)
            }
            .navigationTitle("Mnemo Study")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showNewDeck = true } label: {
                            Label(lang.libraryAdd, systemImage: "plus.square")
                        }
                        Button { showNewFolder = true } label: {
                            Label(lang.libraryNewFolder, systemImage: "folder.badge.plus")
                        }
                        Button { showImport = true } label: {
                            Label(lang.libraryImport, systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.mnemoGreen)
                    }
                }
            }
            // Study settings sheet
            .sheet(item: $selectedDeck) { deck in
                StudySettingsView(deck: deck)
            }
            // New deck editor
            .sheet(isPresented: $showNewDeck) {
                DeckEditorView(deck: nil)
            }
            // Edit deck
            .sheet(item: $editingDeck) { deck in
                DeckEditorView(deck: deck)
            }
            // Import
            .sheet(isPresented: $showImport) {
                ImportView()
            }
            // New folder alert
            .alert(lang.folderCreate, isPresented: $showNewFolder) {
                TextField(lang.folderName, text: $newFolderName)
                Button(lang.commonAdd) {
                    if !newFolderName.isEmpty {
                        library.addFolder(name: newFolderName)
                        newFolderName = ""
                    }
                }
                Button(lang.editorCancel, role: .cancel) { newFolderName = "" }
            }
            .alert(lang.importError, isPresented: $library.showError) {
                Button(lang.commonOK, role: .cancel) {}
            } message: {
                Text(library.errorMessage ?? "")
            }
        }
    }

    // MARK: - Deck row with its temporary sub-deck

    @ViewBuilder
    private func deckSection(deck: Deck) -> some View {
        VStack(spacing: 6) {
            DeckCardView(deck: deck, lang: lang,
                         onTap: { tapDeck(deck) },
                         onEdit: { editingDeck = deck },
                         onDelete: { library.deleteDeck(id: deck.id) })

            // Temp deck attached below
            if let temp = library.decks.first(where: { $0.parentDeckID == deck.id && $0.isTemporary }) {
                TempDeckCard(deck: temp, lang: lang, onTap: { tapDeck(temp) })
                    .padding(.leading, 24)
            }
        }
    }

    private func tapDeck(_ deck: Deck) {
        selectedDeck = deck
    }
}

// MARK: - Deck card

struct DeckCardView: View {
    var deck: Deck
    var lang: AppLanguage
    var onTap: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel

    private var stats: DeckStats { library.stats(for: deck.id) }
    private var accuracy: Double { stats.overallAccuracy }
    private var dueCount: Int    { library.srueDueCount(for: deck) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ProgressRing(progress: accuracy, size: 46, lineWidth: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.headline).foregroundStyle(.white)
                    Text("\(deck.cards.count) \(lang.libraryCards)")
                        .font(.caption).foregroundStyle(.secondary)
                    if settings.srsEnabled && dueCount > 0 {
                        TagBadge(text: "\(dueCount) \(lang.librarySRSDue)", color: .mnemoGold)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .glassCard()
        }
        .contextMenu {
            Button(lang.libraryRename, action: onEdit)
            ShareLink(item: FileParser.export(deck: deck), subject: Text(deck.name)) {
                Label(lang.libraryShare, systemImage: "square.and.arrow.up")
            }
            Button(lang.libraryDelete, role: .destructive, action: onDelete)
        }
    }
}

// MARK: - Temporary deck sub-card

struct TempDeckCard: View {
    var deck: Deck
    var lang: AppLanguage
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 10))
                Text(lang.libraryTemporary)
                    .font(.caption2).fontWeight(.semibold).foregroundStyle(.orange)
                Text("· \(deck.cards.count) \(lang.libraryCards)")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.orange.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Folder section

struct FolderSection: View {
    var folder: DeckFolder
    var lang: AppLanguage
    var onTapDeck: (Deck) -> Void
    var onEdit: (Deck) -> Void
    var onDelete: (UUID) -> Void
    var onDeleteFolder: (UUID) -> Void

    @EnvironmentObject var library: LibraryViewModel
    @State private var isExpanded   = false
    @State private var showRename   = false
    @State private var renameText   = ""

    var decks: [Deck] { library.decks.filter { $0.folderID == folder.id && !$0.isTemporary } }
    var totalCards: Int { decks.reduce(0) { $0 + $1.cards.count } }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "folder.fill").foregroundStyle(Color.mnemoGold)
                    Text(folder.name).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                    Spacer()
                    Text("\(decks.count) · \(totalCards) \(lang.libraryCards)")
                        .font(.caption).foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .glassCard()
            }
            .contextMenu {
                Button(lang.libraryRename) {
                    renameText = folder.name
                    showRename = true
                }
                Button(lang.libraryDelete, role: .destructive) { onDeleteFolder(folder.id) }
            }
            .alert(lang.libraryRename, isPresented: $showRename) {
                TextField(lang.folderName, text: $renameText)
                Button(lang.editorSave) {
                    if !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                        library.renameFolder(id: folder.id, name: renameText.trimmingCharacters(in: .whitespaces))
                    }
                }
                Button(lang.editorCancel, role: .cancel) {}
            }

            if isExpanded {
                ForEach(decks) { deck in
                    VStack(spacing: 6) {
                        DeckCardView(deck: deck, lang: lang,
                                     onTap: { onTapDeck(deck) },
                                     onEdit: { onEdit(deck) },
                                     onDelete: { onDelete(deck.id) })

                        if let temp = library.decks.first(where: { $0.parentDeckID == deck.id && $0.isTemporary }) {
                            TempDeckCard(deck: temp, lang: lang, onTap: { onTapDeck(temp) })
                                .padding(.leading, 24)
                        }
                    }
                    .padding(.leading, 12)
                }
            }
        }
    }
}

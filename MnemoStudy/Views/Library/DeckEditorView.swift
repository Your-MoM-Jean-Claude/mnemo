import SwiftUI

struct DeckEditorView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var deck: Deck?   // nil = new deck

    @State private var name: String = ""
    @State private var cards: [Card] = []
    @State private var showPaste = false
    @State private var editingCard: Card?
    @State private var showCardEditor = false

    var lang: AppLanguage { settings.language }
    var isNew: Bool { deck == nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mnemoBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lang.editorDeckName)
                                .font(.caption).foregroundStyle(.secondary)
                            TextField(lang.editorDeckName, text: $name)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)

                        // Format hint
                        HStack {
                            Image(systemName: "info.circle").foregroundStyle(Color.mnemoGreen)
                            Text(lang.editorFormatHint)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)

                        // Paste button
                        Button {
                            showPaste = true
                        } label: {
                            Label(lang.editorPaste, systemImage: "doc.on.clipboard")
                                .font(.subheadline)
                                .foregroundStyle(Color.mnemoGold)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.mnemoGold.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)

                        Divider().overlay(Color.white.opacity(0.1))

                        // Cards list
                        ForEach(cards) { card in
                            CardRow(card: card, lang: lang,
                                    onEdit: { editingCard = card; showCardEditor = true },
                                    onDelete: { cards.removeAll { $0.id == card.id } })
                                .padding(.horizontal, 16)
                        }

                        // Add card button
                        Button {
                            editingCard  = Card(front: "", back: "")
                            showCardEditor = true
                        } label: {
                            Label(lang.editorAddCard, systemImage: "plus")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Color.mnemoGreen)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.mnemoGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isNew ? lang.editorNewDeck : lang.editorEditDeck)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.editorSave) { save() }
                        .foregroundStyle(Color.mnemoGreen)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPaste) {
                PasteImportSheet(lang: lang) { newCards in
                    cards.append(contentsOf: newCards)
                }
            }
            .sheet(isPresented: $showCardEditor) {
                if let c = editingCard {
                    CardEditorSheet(card: c, lang: lang) { updated in
                        if let i = cards.firstIndex(where: { $0.id == updated.id }) {
                            cards[i] = updated
                        } else {
                            cards.append(updated)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let d = deck {
                name  = d.name
                cards = d.cards
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        if var existing = deck {
            existing.name  = n
            existing.cards = cards
            library.updateDeck(existing)
        } else {
            var d = Deck(name: n, cards: cards)
            library.decks.append(d)
            library.save()
        }
        dismiss()
    }
}

// MARK: - Card row

struct CardRow: View {
    var card: Card
    var lang: AppLanguage
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.front).font(.subheadline).foregroundStyle(.white)
                Text(card.back).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil").foregroundStyle(Color.mnemoGreen)
            }
            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Single card editor

struct CardEditorSheet: View {
    var card: Card
    var lang: AppLanguage
    var onSave: (Card) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var front: String = ""
    @State private var back: String  = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mnemoBg.ignoresSafeArea()
                VStack(spacing: 16) {
                    field(label: lang.editorFront, text: $front)
                    field(label: lang.editorBack,  text: $back)
                    HStack {
                        Image(systemName: "info.circle").foregroundStyle(Color.mnemoGreen)
                        Text(lang.editorFormatHint).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(lang.editorAddCard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.editorSave) {
                        var c = card; c.front = front.trimmingCharacters(in: .whitespaces)
                        c.back = back.trimmingCharacters(in: .whitespaces)
                        onSave(c); dismiss()
                    }
                    .foregroundStyle(Color.mnemoGreen)
                    .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty ||
                              back.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { front = card.front; back = card.back }
    }

    @ViewBuilder
    private func field(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.plain).padding(14)
                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Paste import sheet

struct PasteImportSheet: View {
    var lang: AppLanguage
    var onImport: ([Card]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mnemoBg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    Text(lang.editorPasteHint)
                        .font(.caption).foregroundStyle(.secondary).padding(.horizontal)

                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .frame(minHeight: 200)
                        .padding(.horizontal)

                    if let err = errorMsg {
                        Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                    }
                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle(lang.editorPaste)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.editorSave) {
                        do {
                            let cards = try FileParser.parse(text: text)
                            onImport(cards)
                            dismiss()
                        } catch {
                            errorMsg = error.localizedDescription
                        }
                    }
                    .foregroundStyle(Color.mnemoGreen)
                }
            }
        }
    }
}

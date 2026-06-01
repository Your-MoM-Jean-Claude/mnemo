import SwiftUI

// Per-card editor — edit individual cards in a list (vs DeckEditorView bulk text)
struct CardListEditorView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    let deck: Deck

    @State private var deckName: String = ""
    @State private var cards: [Card] = []

    var lang: AppLanguage { settings.language }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                List {
                    // Deck name
                    Section {
                        TextField(lang.editorDeckName, text: $deckName)
                            .foregroundStyle(.white)
                            .listRowBackground(Color.mnemoSurface)
                    }

                    // Cards
                    Section {
                        ForEach($cards) { $card in
                            VStack(alignment: .leading, spacing: 8) {
                                TextField(lang.editorFront, text: $card.front)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                Divider().overlay(Color.white.opacity(0.1))
                                TextField(lang.editorBack, text: $card.back)
                                    .font(.body)
                                    .foregroundStyle(Color.mnemoGold)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.mnemoSurface)
                        }
                        .onDelete { cards.remove(atOffsets: $0) }
                        .onMove   { cards.move(fromOffsets: $0, toOffset: $1) }

                        // Add card row
                        Button {
                            withAnimation { cards.append(Card(front: "", back: "")) }
                        } label: {
                            Label(lang.editorAddCard, systemImage: "plus.circle.fill")
                                .foregroundStyle(Color.mnemoGreen)
                        }
                        .listRowBackground(Color.mnemoSurface)
                    } header: {
                        Text("\(validCards.count) \(lang.libraryCards)")
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle(lang.libraryEditCards)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.editorSave) { save() }
                        .foregroundStyle(Color.mnemoGreen)
                        .disabled(deckName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            deckName = deck.name
            cards    = deck.cards
        }
    }

    private var validCards: [Card] {
        cards.filter {
            !$0.front.trimmingCharacters(in: .whitespaces).isEmpty &&
            !$0.back.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func save() {
        var updated = deck
        updated.name  = deckName.trimmingCharacters(in: .whitespaces)
        updated.cards = validCards.map { card in
            var c = card
            c.front = c.front.trimmingCharacters(in: .whitespaces)
            c.back  = c.back.trimmingCharacters(in: .whitespaces)
            return c
        }
        library.updateDeck(updated)
        dismiss()
    }
}

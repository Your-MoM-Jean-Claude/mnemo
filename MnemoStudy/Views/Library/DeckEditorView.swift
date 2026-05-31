import SwiftUI

struct DeckEditorView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var deck: Deck?

    @State private var name: String = ""
    @State private var text: String = ""
    @State private var parseError: String?

    var lang: AppLanguage { settings.language }
    var isNew: Bool { deck == nil }

    var parsedCount: Int {
        (try? FileParser.parse(text: text))?.count ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

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

                        // Format hint card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.mnemoGreen)
                                Text(lang.editorFormatHintTitle)
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                            }
                            Text(lang.editorFormatHintBody)
                                .font(.caption).foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(14)
                        .background(Color.mnemoGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.mnemoGreen.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 16)

                        // Text editor
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(lang.editorCardsText)
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                if parsedCount > 0 {
                                    Text("\(parsedCount) \(lang.editorCardCount)")
                                        .font(.caption).foregroundStyle(Color.mnemoGold)
                                }
                            }
                            TextEditor(text: $text)
                                .scrollContentBackground(.hidden)
                                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 260)
                                .padding(4)
                                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)

                        if let err = parseError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                                Text(err).font(.caption).foregroundStyle(.red)
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 32)
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || parsedCount == 0)
                }
            }
        }
        .onAppear {
            if let d = deck {
                name = d.name
                text = FileParser.export(deck: d)
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        do {
            let cards = try FileParser.parse(text: text)
            if var existing = deck {
                existing.name  = n
                existing.cards = cards
                library.updateDeck(existing)
            } else {
                let d = Deck(name: n, cards: cards)
                library.decks.append(d)
                library.save()
            }
            dismiss()
        } catch {
            parseError = error.localizedDescription
        }
    }
}

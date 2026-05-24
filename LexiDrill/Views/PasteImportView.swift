import SwiftUI

private let maxInputLength = 50_000

struct PasteImportView: View {
    let onImport: (String, String) -> Void
    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var text: String      = ""
    @State private var listName: String  = ""
    @State private var preview: [WordPair] = []
    @State private var parseError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(lm.s.listName) {
                    TextField(lm.s.listNamePlaceholder, text: $listName)
                }

                Section {
                    Group {
                        if let attr = try? AttributedString(markdown: lm.s.formatHint) {
                            Text(attr)
                        } else {
                            Text(lm.s.formatHint)
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                } header: {
                    Text(lm.s.help)
                }

                Section(lm.s.wordText) {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: text) { newValue in
                            if newValue.count > maxInputLength {
                                text = String(newValue.prefix(maxInputLength))
                            }
                            updatePreview()
                        }

                    if text.count > maxInputLength / 2 {
                        Text("\(text.count) / \(maxInputLength)")
                            .font(.caption2)
                            .foregroundStyle(text.count > maxInputLength * 9 / 10 ? .orange : .secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                if let err = parseError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                } else if !preview.isEmpty {
                    Section(lm.s.previewCount(preview.count)) {
                        ForEach(preview.prefix(5)) { pair in
                            HStack(spacing: 8) {
                                Text(pair.front).bold()
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(pair.back)
                            }
                            .font(.callout)
                        }
                        if preview.count > 5 {
                            Text(lm.s.andMore(preview.count - 5))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(lm.s.pasteText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.s.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.s.importBtn) {
                        let name = listName.trimmingCharacters(in: .whitespaces)
                        onImport(text, name.isEmpty ? lm.s.newList : name)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(preview.isEmpty)
                }
            }
        }
    }

    private func updatePreview() {
        do {
            preview     = try FileParser.parse(text: text)
            parseError  = nil
        } catch let error as ParseError {
            preview    = []
            parseError = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : lm.s.errorFor(error)
        } catch {
            preview    = []
            parseError = error.localizedDescription
        }
    }
}

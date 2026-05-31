import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showFilePicker = false
    @State private var deckName       = ""

    var lang: AppLanguage { settings.language }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                VStack(spacing: 20) {
                    // Format info card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text").foregroundStyle(Color.mnemoGreen)
                            Text(lang.importSupported)
                                .font(.subheadline).foregroundStyle(.white)
                        }
                        Text("word - translation / alternative")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.mnemoGold)
                    }
                    .padding(16)
                    .glassCard()
                    .padding(.horizontal)

                    // Optional custom name
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang.editorDeckName + " (\(lang.commonOK.lowercased()) — optional)")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField(lang.editorDeckName, text: $deckName)
                            .textFieldStyle(.plain).padding(14)
                            .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)

                    PrimaryButton(title: lang.importChooseFile) {
                        showFilePicker = true
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle(lang.importTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.editorCancel) { dismiss() }.foregroundStyle(.secondary)
                }
            }
            .fileImporter(isPresented: $showFilePicker,
                          allowedContentTypes: [UTType.plainText],
                          allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let n = deckName.isEmpty ? nil : deckName
                    library.importFromURL(url, name: n)
                    if library.errorMessage == nil { dismiss() }
                case .failure(let err):
                    library.errorMessage = err.localizedDescription
                    library.showError = true
                }
            }
        }
    }
}

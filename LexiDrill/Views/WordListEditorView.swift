import SwiftUI

struct WordListEditorView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let listID: UUID

    @State private var editingPair: WordPair?
    @State private var showAddSheet = false

    private var list: WordList? {
        vm.wordLists.first { $0.id == listID }
    }

    var body: some View {
        Group {
            if let list = list {
                List {
                    ForEach(list.pairs) { pair in
                        PairRow(pair: pair, wordStats: vm.wordStats(for: listID)[pair.id])
                            .contentShape(Rectangle())
                            .onTapGesture { editingPair = pair }
                    }
                    .onDelete { offsets in
                        offsets.map { list.pairs[$0].id }
                               .forEach { vm.deletePair(id: $0, from: listID) }
                    }
                }
            }
        }
        .navigationTitle(list?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingPair) { pair in
            PairEditSheet(pair: pair, listID: listID, isNew: false)
                .environmentObject(vm)
                .environmentObject(lm)
        }
        .sheet(isPresented: $showAddSheet) {
            PairEditSheet(pair: WordPair(front: "", back: ""), listID: listID, isNew: true)
                .environmentObject(vm)
                .environmentObject(lm)
        }
    }
}

// MARK: - Pair Row

private struct PairRow: View {
    let pair: WordPair
    let wordStats: WordStats?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(pair.front)
                    .font(.system(.body, weight: .medium))
                Text(pair.back)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let ws = wordStats, ws.attempts > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(ws.accuracy * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(accuracyColor(ws.accuracy))
                        .monospacedDigit()
                    Text("\(ws.attempts)×")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func accuracyColor(_ a: Double) -> Color {
        a >= 0.8 ? .green : a >= 0.5 ? .orange : .red
    }
}

// MARK: - Pair Edit Sheet

struct PairEditSheet: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let pair: WordPair
    let listID: UUID
    let isNew: Bool

    @State private var front: String
    @State private var back: String

    init(pair: WordPair, listID: UUID, isNew: Bool) {
        self.pair   = pair
        self.listID = listID
        self.isNew  = isNew
        _front = State(initialValue: pair.front)
        _back  = State(initialValue: pair.back)
    }

    private var isValid: Bool {
        !front.trimmingCharacters(in: .whitespaces).isEmpty &&
        !back.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(lm.s.frontSide, text: $front)
                        .autocorrectionDisabled()
                    TextField(lm.s.backSide, text: $back)
                        .autocorrectionDisabled()
                } footer: {
                    Text(lm.s.slashHint)
                        .font(.caption)
                }
            }
            .navigationTitle(isNew ? lm.s.addWord : lm.s.editWord)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.s.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.s.save) {
                        let updated = WordPair(
                            id: pair.id,
                            front: front.trimmingCharacters(in: .whitespaces),
                            back:  back.trimmingCharacters(in: .whitespaces)
                        )
                        if isNew {
                            vm.addPair(updated, to: listID)
                        } else {
                            vm.updatePair(updated, in: listID)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

import SwiftUI

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

    // MARK: - Content

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
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // hardest words (lowest accuracy) first, unstudied words last
    private func sortedPairs(_ pairs: [WordPair]) -> [WordPair] {
        pairs.sorted { a, b in
            let sa = ws[a.id]
            let sb = ws[b.id]
            switch (sa, sb) {
            case (nil, nil):   return false
            case (nil, _):     return false
            case (_, nil):     return true
            default:
                let accA = sa!.attempts > 0 ? sa!.accuracy : 1.0
                let accB = sb!.attempts > 0 ? sb!.accuracy : 1.0
                return accA < accB
            }
        }
    }

    // MARK: - Summary pills

    private var summaryRow: some View {
        HStack(spacing: 10) {
            StatPill(
                icon: "percent",
                color: accuracyColor(listStats.accuracy),
                label: lm.s.accuracyLabel,
                value: "\(Int(listStats.accuracy * 100))%"
            )
            StatPill(
                icon: "calendar",
                color: Color.khaki,
                label: lm.s.totalSessions,
                value: "\(listStats.totalSessions)"
            )
            StatPill(
                icon: "flame.fill",
                color: .orange,
                label: lm.s.bestStreakLabel,
                value: "\(listStats.bestStreak)×"
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.khaki.opacity(0.4))
            Text(lm.s.noStatsYet)  // "Žádné statistiky"
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func accuracyColor(_ a: Double) -> Color {
        a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.body))
                .fontWeight(.bold)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Word Stat Row

private struct WordStatRow: View {
    @EnvironmentObject private var lm: LanguageManager
    let pair: WordPair
    let stats: WordStats?

    var body: some View {
        HStack(spacing: 12) {
            accuracyRing
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(pair.front)
                        .font(.system(.subheadline))
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.khaki.opacity(0.5))
                    Text(pair.back)
                        .font(.system(.subheadline))
                        .foregroundStyle(Color.khaki)
                        .lineLimit(1)
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
            Circle()
                .stroke(Color.khakiBorder.opacity(0.35), lineWidth: 2.5)
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
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var subtitleText: some View {
        if let s = stats, s.attempts > 0 {
            HStack(spacing: 6) {
                Text("\(s.attempts) \(lm.s.attemptsLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if s.isDue {
                    Circle().fill(Color.orange).frame(width: 3, height: 3)
                    Text(lm.s.dueLabel)
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let due = s.dueDate {
                    let days = max(1, Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 1)
                    Circle().fill(Color.secondary.opacity(0.4)).frame(width: 3, height: 3)
                    Text(lm.s.nextReviewIn(days))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text(lm.s.notStudiedYet)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func ringColor(_ a: Double) -> Color {
        a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
    }
}

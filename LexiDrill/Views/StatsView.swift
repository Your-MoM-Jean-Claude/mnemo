import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @EnvironmentObject private var lm: LanguageManager

    @State private var sessionsExpanded  = false
    @State private var accuracyExpanded  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if vm.totalSessionsCount == 0 { emptyState }
                    else { statsContent }
                }
            }
            .navigationTitle(lm.s.statsTab)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Content

    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Top row – streak static, accuracy + sessions expandable
                HStack(spacing: 10) {
                    MiniStatCard(
                        icon: "flame.fill", color: .orange,
                        title: lm.s.studyStreakLabel,
                        value: lm.s.streakDays(vm.studyStreak)
                    )
                    ExpandableMiniCard(
                        icon: "checkmark.circle.fill", color: Color.appSuccess,
                        title: lm.s.overallAccuracy,
                        value: "\(Int(vm.overallAccuracy * 100))%",
                        isExpanded: $accuracyExpanded
                    )
                    ExpandableMiniCard(
                        icon: "book.fill", color: Color.khaki,
                        title: lm.s.totalSessions,
                        value: "\(vm.totalSessionsCount)",
                        isExpanded: $sessionsExpanded
                    )
                }
                .padding(.horizontal, 16)

                // Accuracy breakdown (expandable)
                if accuracyExpanded {
                    KhakiCard { accuracyBreakdownView }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal:   .move(edge: .top).combined(with: .opacity)
                        ))
                }

                // Session history (expandable)
                if sessionsExpanded {
                    KhakiCard { sessionHistoryView }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal:   .move(edge: .top).combined(with: .opacity)
                        ))
                }

                // Weekly chart
                KhakiCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(lm.s.weeklyActivity)
                            .font(.system(.subheadline)).fontWeight(.semibold)
                        WeeklyBarChart(counts: vm.weeklySessionCounts, language: lm.language)
                    }
                }

                // Hardest words
                if !vm.hardestWords.isEmpty {
                    KhakiCard {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lm.s.hardestWords)
                                .font(.system(.subheadline)).fontWeight(.semibold)
                                .padding(.bottom, 10)
                            ForEach(Array(vm.hardestWords.enumerated()), id: \.offset) { i, item in
                                HardWordRow(item: item)
                                if i < vm.hardestWords.count - 1 {
                                    Divider().overlay(Color.khakiBorder.opacity(0.4))
                                }
                            }
                        }
                    }
                }

                // Lists overview
                let listsWithStats = vm.wordLists.filter { vm.stats(for: $0.id).totalSessions > 0 }
                if !listsWithStats.isEmpty {
                    KhakiCard {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lm.s.listsOverview)
                                .font(.system(.subheadline)).fontWeight(.semibold)
                                .padding(.bottom, 10)
                            ForEach(Array(listsWithStats.enumerated()), id: \.offset) { i, list in
                                ListStatRow(list: list, stats: vm.stats(for: list.id))
                                if i < listsWithStats.count - 1 {
                                    Divider().overlay(Color.khakiBorder.opacity(0.4))
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 8)
            .animation(.spring(response: 0.30, dampingFraction: 0.82), value: sessionsExpanded)
            .animation(.spring(response: 0.30, dampingFraction: 0.82), value: accuracyExpanded)
        }
    }

    // MARK: - Accuracy breakdown

    private var accuracyBreakdownView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lm.s.accuracyBreakdown)
                .font(.system(.subheadline)).fontWeight(.semibold)
                .padding(.bottom, 10)
            let lists = vm.wordLists.filter { vm.stats(for: $0.id).totalSessions > 0 }
                .sorted { vm.stats(for: $0.id).accuracy > vm.stats(for: $1.id).accuracy }
            ForEach(Array(lists.enumerated()), id: \.offset) { i, list in
                let acc = vm.stats(for: list.id).accuracy
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(list.name)
                            .font(.system(.callout)).fontWeight(.medium).lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.khakiCard)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(accuracyColor(acc))
                                    .frame(width: geo.size.width * acc, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    Text("\(Int(acc * 100))%")
                        .font(.system(.callout)).fontWeight(.bold)
                        .foregroundStyle(accuracyColor(acc))
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                }
                .padding(.vertical, 8)
                if i < lists.count - 1 {
                    Divider().overlay(Color.khakiBorder.opacity(0.4))
                }
            }
        }
    }

    // MARK: - Session history

    private var sessionHistoryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lm.s.sessionHistoryTitle)
                .font(.system(.subheadline)).fontWeight(.semibold)
                .padding(.bottom, 10)
            let days = sessionsByDay
            ForEach(Array(days.enumerated()), id: \.offset) { i, item in
                HStack {
                    Text(formatSessionDate(item.date))
                        .font(.system(.callout))
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<min(item.count, 5), id: \.self) { _ in
                            Circle()
                                .fill(Color.khaki)
                                .frame(width: 6, height: 6)
                        }
                        if item.count > 5 {
                            Text("+\(item.count - 5)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Text("\(item.count)×")
                        .font(.system(.callout)).fontWeight(.bold)
                        .foregroundStyle(Color.khaki).monospacedDigit()
                        .frame(width: 28, alignment: .trailing)
                }
                .padding(.vertical, 7)
                if i < days.count - 1 {
                    Divider().overlay(Color.khakiBorder.opacity(0.4))
                }
            }
        }
    }

    // MARK: - Helpers

    private var sessionsByDay: [(date: Date, count: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var map: [String: (date: Date, count: Int)] = [:]
        for stat in vm.statistics.values {
            for session in stat.sessions {
                let key = formatter.string(from: session.date)
                map[key] = (session.date, (map[key]?.count ?? 0) + 1)
            }
        }
        return map.values.sorted { $0.date > $1.date }
    }

    private func formatSessionDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return lm.s.lastStudiedToday }
        if cal.isDateInYesterday(date) { return lm.s.lastStudiedYesterday }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: lm.language.rawValue)
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    private func accuracyColor(_ a: Double) -> Color {
        a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(Color.khaki.opacity(0.5))
            Text(lm.s.noStatsYet)
                .font(.title2)
                .fontWeight(.bold)
            Text(lm.s.noStatsDesc)
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Expandable Mini Card

private struct ExpandableMiniCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isExpanded ? Color.white : color)
                Text(value)
                    .font(.system(.callout)).fontWeight(.bold).monospacedDigit()
                    .minimumScaleFactor(0.7).lineLimit(1)
                Text(title)
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).minimumScaleFactor(0.7).lineLimit(2)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isExpanded ? color.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Khaki Card Container

private struct KhakiCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
            .padding(.horizontal, 16)
    }
}

// MARK: - Mini Stat Card

private struct MiniStatCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
            Text(value)
                .font(.system(.callout)).fontWeight(.bold).monospacedDigit()
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(title)
                .font(.system(size: 10)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).minimumScaleFactor(0.7).lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Weekly Bar Chart

private struct WeeklyBarChart: View {
    let counts: [Int]
    let language: Language

    private var maxCount: Int { max(1, counts.max() ?? 1) }

    private var dayLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateFormat = "EEE"
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -(6 - offset), to: Date()) ?? Date()
            return String(formatter.string(from: day).prefix(2))
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 4) {
                    let barH = counts[i] > 0
                        ? max(8, CGFloat(counts[i]) / CGFloat(maxCount) * 52)
                        : 3
                    RoundedRectangle(cornerRadius: 5)
                        .fill(counts[i] > 0 ? Color.khaki : Color.khakiCard)
                        .frame(height: barH)
                    Text(dayLabels[i])
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
        .animation(.spring(response: 0.5), value: counts)
    }
}

// MARK: - Hard Word Row

private struct HardWordRow: View {
    @EnvironmentObject private var lm: LanguageManager
    let item: HardWord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.pair.front)  →  \(item.pair.back)")
                    .font(.system(.callout)).fontWeight(.medium).lineLimit(1)
                Text(item.list.name)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.stats.accuracy * 100))%")
                    .font(.system(.callout)).fontWeight(.bold)
                    .foregroundStyle(accuracyColor(item.stats.accuracy)).monospacedDigit()
                Text("\(item.stats.attempts) \(lm.s.attempts)")
                    .font(.caption2).foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .padding(.vertical, 8)
    }

    private func accuracyColor(_ a: Double) -> Color {
        a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
    }
}

// MARK: - List Stat Row

private struct ListStatRow: View {
    @EnvironmentObject private var lm: LanguageManager
    let list: WordList
    let stats: ListStatistics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(.system(.callout)).fontWeight(.semibold).lineLimit(1)
                Text("\(stats.totalSessions) \(lm.s.totalSessions.lowercased())")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(stats.accuracy * 100))%")
                    .font(.system(.callout)).fontWeight(.bold)
                    .foregroundStyle(accuracyColor(stats.accuracy)).monospacedDigit()
                if let trend = stats.trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(Int(abs(trend) * 100))%")
                            .font(.caption2).monospacedDigit()
                    }
                    .foregroundStyle(trend >= 0 ? Color.appSuccess : Color.appError)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func accuracyColor(_ a: Double) -> Color {
        a >= 0.8 ? Color.appSuccess : a >= 0.5 ? .orange : Color.appError
    }
}

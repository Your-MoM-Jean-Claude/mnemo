import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @State private var showAccuracyDetail  = false
    @State private var showSessionsDetail  = false

    var lang: AppLanguage { settings.language }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                if library.totalSessions == 0 {
                    Text(lang.statsNoData)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {

                            // Daily goal progress
                            let goalMin = settings.dailyGoalMinutes
                            let todayMin = library.todayMinutes
                            let ratio = goalMin > 0 ? min(1.0, todayMin / Double(goalMin)) : 0.0
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(lang.settingsDailyGoal, systemImage: "target")
                                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(todayMin))m / \(goalMin)m")
                                        .font(.caption).foregroundStyle(Color.mnemoGold)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 8)
                                        Capsule().fill(
                                            LinearGradient(colors: [Color.mnemoGreen, Color.mnemoGold],
                                                           startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * ratio, height: 8)
                                            .animation(.spring(duration: 0.5), value: ratio)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(14).glassCard().padding(.horizontal)

                            // Top 3 headline stats
                            HStack(spacing: 12) {
                                headlineStat(
                                    value: "\(library.studyStreak)",
                                    sublabel: "best \(library.bestStreak)",
                                    label: lang.statsStreak,
                                    icon: "flame.fill",
                                    color: .orange)

                                Button {
                                    showAccuracyDetail.toggle()
                                    showSessionsDetail = false
                                } label: {
                                    headlineStat(
                                        value: "\(Int(library.overallAccuracy * 100))%",
                                        sublabel: nil,
                                        label: lang.statsAccuracy,
                                        icon: "target",
                                        color: .mnemoGreen)
                                }

                                Button {
                                    showSessionsDetail.toggle()
                                    showAccuracyDetail = false
                                } label: {
                                    headlineStat(
                                        value: "\(library.totalSessions)",
                                        sublabel: nil,
                                        label: lang.statsSessions,
                                        icon: "book.fill",
                                        color: .mnemoGold)
                                }
                            }
                            .padding(.horizontal)

                            // Per-deck accuracy (expandable) — only studied decks
                            if showAccuracyDetail {
                                let studiedDecks = library.decks.filter {
                                    !$0.isTemporary && (library.deckStats[$0.id]?.totalSessions ?? 0) > 0
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(lang.statsAllDecks)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)

                                    ForEach(studiedDecks) { deck in
                                        let acc = library.stats(for: deck.id).overallAccuracy
                                        HStack {
                                            ProgressRing(progress: acc, size: 32, lineWidth: 3)
                                            Text(deck.name).foregroundStyle(.white)
                                            Spacer()
                                            Text("\(Int(acc * 100))%")
                                                .font(.subheadline).foregroundStyle(.secondary)
                                        }
                                        .padding(14).glassCard().padding(.horizontal)
                                    }
                                }
                            }

                            // Session history (expandable)
                            if showSessionsDetail {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(lang.statsSessionHistory)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)

                                    ForEach(groupedSessions(), id: \.0) { (dateStr, sessions) in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(dateStr)
                                                .font(.caption).foregroundStyle(.secondary)
                                                .padding(.horizontal)
                                            ForEach(sessions) { session in
                                                sessionRow(session)
                                            }
                                        }
                                    }
                                }
                            }

                            // Weekly activity mini chart
                            WeeklyChart()
                                .padding(.horizontal)

                        }
                        .padding(.top, 16).padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(lang.tabStats)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func headlineStat(value: String, sublabel: String?, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            if let sub = sublabel {
                Text(sub).font(.caption2).foregroundStyle(color.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14).glassCard()
    }

    @ViewBuilder
    private func sessionRow(_ s: SessionRecord) -> some View {
        let deckName = library.decks.first(where: { $0.id == s.deckID })?.name ?? "—"
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(deckName).font(.subheadline).foregroundStyle(.white)
                Text(s.mode.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(s.accuracy * 100))%")
                .font(.subheadline).foregroundStyle(Color.mnemoGreen)
        }
        .padding(12).glassCard().padding(.horizontal)
    }

    private func groupedSessions() -> [(String, [SessionRecord])] {
        let fmt = DateFormatter(); fmt.dateStyle = .medium
        let all = library.allSessions
        var groups: [(String, [SessionRecord])] = []
        var seen: [String: Int] = [:]
        for s in all {
            let key = fmt.string(from: s.date)
            if let idx = seen[key] { groups[idx].1.append(s) }
            else { seen[key] = groups.count; groups.append((key, [s])) }
        }
        return groups
    }
}

// MARK: - Weekly bar chart

struct WeeklyChart: View {
    @EnvironmentObject var library: LibraryViewModel

    private var counts: [Int] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        var dict: [String: Int] = [:]
        for s in library.deckStats.values {
            for r in s.sessions { dict[fmt.string(from: r.date), default: 0] += 1 }
        }
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: Date()) ?? Date()
            return dict[fmt.string(from: day)] ?? 0
        }
    }

    private var maxCount: Int { counts.max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days").font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let h = maxCount > 0 ? Double(counts[i]) / Double(maxCount) : 0
                    RoundedRectangle(cornerRadius: 4)
                        .fill(i == 6 ? Color.mnemoGreen : Color.mnemoGreen.opacity(0.4))
                        .frame(maxWidth: .infinity, minHeight: 4, maxHeight: max(4, h * 60))
                }
            }
            .frame(height: 60)
        }
        .padding(14).glassCard()
    }
}

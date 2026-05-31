import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var result: SessionResult
    var deckName: String
    var deck: Deck
    var config: StudyConfig

    @State private var studyAgainConfig: StudyConfig? = nil

    var lang: AppLanguage { settings.language }

    private var durationString: String {
        let m = Int(result.duration) / 60
        let s = Int(result.duration) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var body: some View {
        ZStack {
            AppBg()

            VStack(spacing: 28) {
                Spacer()

                // Accuracy ring + deck name
                VStack(spacing: 16) {
                    ProgressRing(progress: result.accuracy, size: 120, lineWidth: 10)
                        .overlay(
                            Text("\(Int(result.accuracy * 100))%")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white))

                    Text(deckName)
                        .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                    Text(lang.resultsTitle)
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Stats row
                HStack(spacing: 0) {
                    statCell(value: "\(result.totalAnswered)", label: lang.resultsAnswered)
                    Divider().frame(height: 40).overlay(Color.white.opacity(0.1))
                    statCell(value: "\(result.totalCorrect)", label: lang.resultsAccuracy)
                    Divider().frame(height: 40).overlay(Color.white.opacity(0.1))
                    statCell(value: durationString, label: lang.resultsTime)
                }
                .padding(16).glassCard().padding(.horizontal)

                // Wrong deck notice
                if !result.wrongCardIDs.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(lang.resultsWrongCreated)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(16).glassCard().padding(.horizontal)
                }

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: lang.resultsStudyAgain) {
                        studyAgainConfig = StudyConfig(
                            mode: config.mode,
                            direction: config.direction,
                            order: config.order,
                            sectionSize: config.sectionSize,
                            requiredCorrect: config.requiredCorrect)
                    }
                    .padding(.horizontal)

                    Button(lang.resultsDone) { dismiss() }
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)
            }
        }
        .fullScreenCover(item: $studyAgainConfig) { cfg in
            StudyView(deck: deck, config: cfg)
        }
    }

    @ViewBuilder
    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

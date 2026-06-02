import SwiftUI

struct InfoView: View {
    @EnvironmentObject var settings: SettingsViewModel
    var lang: AppLanguage { settings.language }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    VStack(spacing: 14) {
                        infoCard(icon: "sparkles", color: .mnemoGreen,
                                 title: lang.infoAppTitle, body: lang.infoAppBody)
                        infoCard(icon: "square.stack.3d.up.fill", color: .mnemoGold,
                                 title: lang.infoModesTitle, body: lang.infoModesBody)
                        infoCard(icon: "clock.arrow.circlepath", color: .blue,
                                 title: lang.infoSRSTitle, body: lang.infoSRSBody)
                        infoCard(icon: "brain.head.profile", color: Color(red: 0.9, green: 0.5, blue: 0.3),
                                 title: lang.infoOurSRSTitle, body: lang.infoOurSRSBody)
                        infoCard(icon: "square.and.arrow.down", color: .mnemoGreen,
                                 title: lang.infoImportTitle, body: lang.infoImportBody)
                        infoCard(icon: "slider.horizontal.3", color: .mnemoGold,
                                 title: lang.infoEditTitle, body: lang.infoEditBody)
                        infoCard(icon: "checkmark.seal.fill", color: .green,
                                 title: lang.infoAnswersTitle, body: lang.infoAnswersBody)

                        Text("Mnemo Study · 1.0")
                            .font(.caption2).foregroundStyle(.secondary.opacity(0.5))
                            .padding(.top, 8).padding(.bottom, 32)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(lang.infoTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func infoCard(icon: String, color: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3).foregroundStyle(color)
                    .frame(width: 28)
                Text(title)
                    .font(.headline).foregroundStyle(.white)
            }
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}

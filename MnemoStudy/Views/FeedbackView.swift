import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject var settings: SettingsViewModel
    var lang: AppLanguage { settings.language }

    // Survey state
    @State private var wantsSync       = false
    @State private var wantsAudio      = false
    @State private var wantsMoreDecks  = false
    @State private var wantsWatch      = false
    @State private var wantsAI         = false
    @State private var wantsSharing    = false
    @State private var freeComment     = ""
    @State private var showThankYou    = false

    private let feedbackEmail = "jir.filipec@gmail.com"

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()

                ScrollView {
                    VStack(spacing: 20) {

                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.mnemoGreen)
                            Text(lang.feedbackHeader)
                                .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(lang.feedbackIntro)
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)

                        // Survey card
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lang.feedbackQuestion)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 12)

                            surveyToggle(icon: "icloud.fill", color: .blue,
                                title: lang.feedbackSync, desc: lang.feedbackSyncDesc, binding: $wantsSync)
                            Divider().background(Color.white.opacity(0.08))
                            surveyToggle(icon: "speaker.wave.2.fill", color: .mnemoGold,
                                title: lang.feedbackAudio, desc: lang.feedbackAudioDesc, binding: $wantsAudio)
                            Divider().background(Color.white.opacity(0.08))
                            surveyToggle(icon: "books.vertical.fill", color: .mnemoGreen,
                                title: lang.feedbackMoreDecks, desc: lang.feedbackDecksDesc, binding: $wantsMoreDecks)
                            Divider().background(Color.white.opacity(0.08))
                            surveyToggle(icon: "applewatch", color: Color(red: 0.6, green: 0.6, blue: 0.9),
                                title: lang.feedbackWatch, desc: lang.feedbackWatchDesc, binding: $wantsWatch)
                            Divider().background(Color.white.opacity(0.08))
                            surveyToggle(icon: "brain.head.profile", color: Color(red: 0.9, green: 0.5, blue: 0.3),
                                title: lang.feedbackAI, desc: lang.feedbackAIDesc, binding: $wantsAI)
                            Divider().background(Color.white.opacity(0.08))
                            surveyToggle(icon: "person.2.fill", color: .orange,
                                title: lang.feedbackSharing, desc: lang.feedbackSharingDesc, binding: $wantsSharing)
                        }
                        .padding(16).glassCard().padding(.horizontal)

                        // Free text
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.feedbackElse)
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                            TextEditor(text: $freeComment)
                                .scrollContentBackground(.hidden)
                                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                                .frame(minHeight: 80)
                                .padding(4)
                                .background(Color.mnemoSurface, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(16).glassCard().padding(.horizontal)

                        // Send button
                        PrimaryButton(title: lang.feedbackSend) {
                            sendFeedback()
                        }
                        .padding(.horizontal)

                        // Direct email
                        Button {
                            if let url = URL(string: "mailto:\(feedbackEmail)?subject=Mnemo%20Study%20Feedback") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope")
                                Text("\(lang.feedbackWriteDirect) \(feedbackEmail)")
                            }
                            .font(.subheadline).foregroundStyle(Color.mnemoGreen)
                        }

                        // Rate on App Store
                        Button {
                            if let url = URL(string: "itms-apps://itunes.apple.com/app/id0") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                Text(lang.feedbackRate).foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(lang.feedbackTitle)
            .navigationBarTitleDisplayMode(.large)
            .alert(lang.feedbackThanks, isPresented: $showThankYou) {
                Button(lang.commonOK, role: .cancel) {}
            } message: {
                Text(lang.feedbackThanksBody)
            }
        }
    }

    @ViewBuilder
    private func surveyToggle(icon: String, color: Color, title: String, desc: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: binding).tint(.mnemoGreen)
        }
        .padding(.vertical, 10)
    }

    private func sendFeedback() {
        var body = "Mnemo Study — Feature Survey\n\n"
        body += "iCloud Sync: \(wantsSync ? "YES" : "no")\n"
        body += "Audio Pronunciation: \(wantsAudio ? "YES" : "no")\n"
        body += "More Built-in Decks: \(wantsMoreDecks ? "YES" : "no")\n"
        body += "Apple Watch App: \(wantsWatch ? "YES" : "no")\n"
        body += "AI Card Generator: \(wantsAI ? "YES" : "no")\n"
        body += "Deck Sharing: \(wantsSharing ? "YES" : "no")\n"
        if !freeComment.trimmingCharacters(in: .whitespaces).isEmpty {
            body += "\nComment:\n\(freeComment)\n"
        }
        body += "\n---\nApp version: 1.0"

        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subject = "Mnemo%20Study%20Feature%20Survey"
        if let url = URL(string: "mailto:\(feedbackEmail)?subject=\(subject)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
        showThankYou = true
    }
}

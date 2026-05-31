import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject var settings: SettingsViewModel

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
                            Text("Help shape Mnemo Study")
                                .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                            Text("Which features would you like to see next? Your vote directly influences what we build.")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)

                        // Survey card
                        VStack(alignment: .leading, spacing: 0) {
                            Text("What would you like to see?")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 12)

                            surveyToggle(
                                icon: "icloud.fill", color: .blue,
                                title: "iCloud Sync",
                                desc: "Keep decks & progress across all your devices",
                                binding: $wantsSync)

                            Divider().background(Color.white.opacity(0.08))

                            surveyToggle(
                                icon: "speaker.wave.2.fill", color: .mnemoGold,
                                title: "Audio Pronunciation",
                                desc: "Hear native pronunciation for every card",
                                binding: $wantsAudio)

                            Divider().background(Color.white.opacity(0.08))

                            surveyToggle(
                                icon: "books.vertical.fill", color: .mnemoGreen,
                                title: "More Built-in Decks",
                                desc: "More languages, topics, and vocabulary sets",
                                binding: $wantsMoreDecks)

                            Divider().background(Color.white.opacity(0.08))

                            surveyToggle(
                                icon: "applewatch", color: Color(red: 0.6, green: 0.6, blue: 0.9),
                                title: "Apple Watch App",
                                desc: "5 quick cards on your wrist every morning",
                                binding: $wantsWatch)

                            Divider().background(Color.white.opacity(0.08))

                            surveyToggle(
                                icon: "brain.head.profile", color: Color(red: 0.9, green: 0.5, blue: 0.3),
                                title: "AI Card Generator",
                                desc: "Paste any text and generate cards automatically",
                                binding: $wantsAI)

                            Divider().background(Color.white.opacity(0.08))

                            surveyToggle(
                                icon: "person.2.fill", color: .orange,
                                title: "Deck Sharing",
                                desc: "Share your decks with friends via link",
                                binding: $wantsSharing)
                        }
                        .padding(16).glassCard().padding(.horizontal)

                        // Free text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anything else on your mind?")
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
                        PrimaryButton(title: "Send Feedback") {
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
                                Text("Write directly: \(feedbackEmail)")
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
                                Text("Rate Mnemo Study on the App Store")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.large)
            .alert("Thank you! 🙏", isPresented: $showThankYou) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your feedback has been sent. We'll use it to prioritize upcoming features.")
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
        body += "\n---\nApp version: 1.0 (build 29)"

        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subject = "Mnemo%20Study%20Feature%20Survey"
        if let url = URL(string: "mailto:\(feedbackEmail)?subject=\(subject)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
        showThankYou = true
    }
}

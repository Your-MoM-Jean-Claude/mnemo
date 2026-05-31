import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var page = 0

    var body: some View {
        ZStack {
            AppBg(opacity: 0.18)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                PrimaryButton(title: page < 2 ? "Continue" : "Get Started") {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        onComplete()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Pages

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("MnemoLogo")
                .resizable().scaledToFit().frame(width: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: Color.mnemoGreen.opacity(0.4), radius: 24, y: 8)
            Text("Mnemo Study")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Master any language,\none card at a time")
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var page2: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("How it works")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            VStack(spacing: 14) {
                onboardingRow(icon: "keyboard", title: "Typing", desc: "Type the answer from memory")
                onboardingRow(icon: "eye", title: "Show", desc: "Reveal the answer, judge yourself")
                onboardingRow(icon: "list.bullet", title: "Quiz", desc: "Pick from 4 options")
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var page3: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(Color.mnemoGreen)
            Text("Spaced Repetition")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Wrong answers get flagged automatically.\n\nEnable SRS in Settings to schedule each card for review at the perfect moment — right before you forget it.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    @ViewBuilder
    private func onboardingRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.mnemoGreen)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .glassCard()
    }
}

import SwiftUI

struct SplashView: View {
    var lastDeck: (deck: Deck, accuracy: Double)?
    var lang: AppLanguage
    var onDismiss: () -> Void

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            AppBg(opacity: 0.18)

            VStack(spacing: 0) {
                Spacer()

                // Foreground logo
                Image("MnemoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: Color.mnemoGreen.opacity(0.4), radius: 24, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Spacer().frame(height: 28)

                Text(lang.currentGreeting)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.mnemoGold)
                    .opacity(contentOpacity)

                Spacer().frame(height: 40)

                // Last studied info
                if let entry = lastDeck {
                    VStack(spacing: 6) {
                        Text(lang.splashLastStudied)
                            .font(.caption).foregroundStyle(.secondary)
                        Text(entry.deck.name)
                            .font(.headline).foregroundStyle(.white)
                        Text("\(Int(entry.accuracy * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.mnemoGreen, Color.mnemoGold],
                                               startPoint: .leading, endPoint: .trailing))
                    }
                    .padding(20)
                    .glassCard()
                    .padding(.horizontal, 40)
                    .opacity(contentOpacity)
                }

                Spacer()

                Text(lang.splashTapToContinue)
                    .font(.caption).foregroundStyle(.secondary.opacity(0.6))
                    .padding(.bottom, 12)
                    .opacity(contentOpacity)

                Text("© 2025 Jiří Filipec")
                    .font(.caption2).foregroundStyle(.secondary.opacity(0.4))
                    .padding(.bottom, 32)
                    .opacity(contentOpacity)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

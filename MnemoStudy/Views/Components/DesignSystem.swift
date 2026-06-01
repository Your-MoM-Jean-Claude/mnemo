import SwiftUI

// MARK: - Brand colors (from logo: sage green + warm beige/gold)
extension Color {
    static let mnemoGreen  = Color(red: 0.48, green: 0.62, blue: 0.49)   // #7A9E7E sage
    static let mnemoGold   = Color(red: 0.83, green: 0.72, blue: 0.59)   // #D4B896 warm beige
    static let mnemoBg     = Color(red: 0.11, green: 0.13, blue: 0.12)   // dark background
    static let mnemoSurface = Color(red: 0.16, green: 0.18, blue: 0.17)  // card surface
}

// MARK: - Shared background: dark base + MnemoLogo watermark
struct AppBg: View {
    var opacity: Double = 0.13
    var body: some View {
        Color.mnemoBg
            .ignoresSafeArea()
            .overlay(
                Image("MnemoLogo")
                    .resizable()
                    .scaledToFit()
                    .opacity(opacity)
                    .allowsHitTesting(false)
            )
    }
}

// MARK: - Glass card modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Progress ring
struct ProgressRing: View {
    var progress: Double         // 0–1
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4
    var color: Color = .mnemoGreen

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Tag badge
struct TagBadge: View {
    var text: String
    var color: Color = .mnemoGreen
    var body: some View {
        Text(text)
            .font(.caption2).fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Primary button
struct PrimaryButton: View {
    var title: String
    var color: Color = .mnemoGreen
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [color, color.opacity(0.75)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Correct / wrong flash overlay
struct AnswerFeedbackOverlay: View {
    var isCorrect: Bool
    var questionText: String
    var correctText: String
    var userAnswer: String = ""
    var lang: AppLanguage

    private var feedbackColor: Color {
        isCorrect
            ? Color(red: 0.18, green: 0.48, blue: 0.32)
            : Color(red: 0.58, green: 0.16, blue: 0.16)
    }

    private var showUserAnswer: Bool {
        !isCorrect && !userAnswer.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(feedbackColor)
                .padding(16)

            VStack(spacing: 0) {
                // Heading — upper area
                VStack(spacing: 10) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.92))
                    Text(isCorrect ? lang.studyCorrect : lang.studyWrong)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 52)

                Spacer()

                // Word pair — center
                VStack(spacing: 14) {
                    Text(questionText)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)

                    Image(systemName: "arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))

                    Text(correctText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    // User's wrong answer — struck through
                    if showUserAnswer {
                        VStack(spacing: 4) {
                            Text(lang.studyYourAnswer)
                                .font(.caption).foregroundStyle(.white.opacity(0.6))
                            Text(userAnswer)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .strikethrough(true, color: .white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 36)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }
}

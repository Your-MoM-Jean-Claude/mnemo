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
        ZStack {
            Color.mnemoBg
            Image("MnemoLogo")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .opacity(opacity)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
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
    var correctText: String
    var lang: AppLanguage

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(isCorrect ? Color.mnemoGreen : .red)
            Text(isCorrect ? lang.studyCorrect : lang.studyWrong)
                .font(.headline).bold()
                .foregroundStyle(isCorrect ? Color.mnemoGreen : .red)
            if !isCorrect {
                VStack(spacing: 2) {
                    Text(lang.studyCorrectAnswer)
                        .font(.caption).foregroundStyle(.secondary)
                    Text(correctText)
                        .font(.body).bold()
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(24)
        .glassCard()
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

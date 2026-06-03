import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var product: Product?
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    static let productID = "com.jirifilipec.mnemoapp.pro"
    var lang: AppLanguage { settings.language }

    var body: some View {
        ZStack {
            AppBg()

            // Close button (soft paywall — always dismissable)
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary).padding(16)
                    }
                }
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()

                // Logo + title
                Image("MnemoLogo")
                    .resizable().scaledToFit().frame(width: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 16)

                Text(lang.paywallTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.mnemoGreen, Color.mnemoGold],
                                       startPoint: .leading, endPoint: .trailing))
                    .padding(.bottom, 8)

                Text(lang.paywallSubtitle)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    featureRow(lang.paywallFeature1, icon: "books.vertical.fill")
                    featureRow(lang.paywallFeature2, icon: "pencil.and.list.clipboard")
                    featureRow(lang.paywallFeature3, icon: "brain.head.profile")
                    featureRow(lang.paywallFeature4, icon: "chart.bar.fill")
                }
                .padding(20).glassCard().padding(.horizontal)
                .padding(.bottom, 28)

                // Price + buy
                if let p = product {
                    Text(p.displayPrice)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.mnemoGold)
                    Text(lang.paywallFounder)
                        .font(.caption).fontWeight(.semibold).foregroundStyle(Color.mnemoGreen)
                    Text(lang.paywallCancelAnytime)
                        .font(.caption2).foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                }

                PrimaryButton(title: lang.paywallPurchase, color: .mnemoGreen) {
                    Task { await purchase() }
                }
                .padding(.horizontal)
                .disabled(isPurchasing)

                Button(lang.paywallRestore) {
                    Task { await restore() }
                }
                .font(.subheadline).foregroundStyle(.secondary)
                .padding(.top, 12)

                if let err = purchaseError {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.top, 8)
                }

                Spacer()
            }
        }
        .task {
            if let products = try? await Product.products(for: [Self.productID]) {
                product = products.first
            }
        }
    }

    // MARK: - StoreKit

    private func purchase() async {
        guard let p = product else { return }
        isPurchasing = true
        do {
            let result = try await p.purchase()
            switch result {
            case .success(let v):
                switch v {
                case .verified:
                    settings.isProUnlocked = true   // persisted to iCloud, survives reinstall
                    dismiss()
                default: break
                }
            default: break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isPurchasing = false
    }

    private func restore() async {
        try? await AppStore.sync()
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID {
                settings.isProUnlocked = true
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.mnemoGreen)
                .frame(width: 24)
            Text(text).font(.subheadline).foregroundStyle(.white)
        }
    }
}

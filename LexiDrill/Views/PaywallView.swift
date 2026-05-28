import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var lm: LanguageManager
    @ObservedObject var paywall: PaywallManager

    @State private var monthlyProduct: Product?
    @State private var yearlyProduct: Product?
    @State private var selectedID: String = PaywallManager.productIDYearly

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            RadialGradient(
                colors: [Color.orange.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 440
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(Color.orange)
                    }

                    Text("Mnemo Pro")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(lm.s.paywallSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer().frame(height: 32)

                // Feature list
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(lm.s.paywallFeatures, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.orange)
                                .font(.system(size: 17))
                            Text(feature)
                                .font(.callout)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal, 36)

                Spacer().frame(height: 28)

                // Plan cards
                HStack(spacing: 12) {
                    PlanCard(
                        title: lm.s.paywallMonthly,
                        price: monthlyProduct?.displayPrice,
                        period: lm.s.paywallPerMonth,
                        badge: nil,
                        isSelected: selectedID == PaywallManager.productIDMonthly
                    ) {
                        selectedID = PaywallManager.productIDMonthly
                    }

                    PlanCard(
                        title: lm.s.paywallYearly,
                        price: yearlyProduct?.displayPrice,
                        period: lm.s.paywallPerYear,
                        badge: lm.s.paywallBestValue,
                        isSelected: selectedID == PaywallManager.productIDYearly
                    ) {
                        selectedID = PaywallManager.productIDYearly
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // CTA
                VStack(spacing: 10) {
                    Button {
                        Task { await paywall.purchase(productID: selectedID) }
                    } label: {
                        Group {
                            if paywall.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(lm.s.paywallSubscribeBtn)
                                    .fontWeight(.bold)
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.orange)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(paywall.isLoading)
                    .padding(.horizontal, 24)

                    Text(lm.s.paywallCancelAnytime)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Button {
                        Task { await paywall.restorePurchases() }
                    } label: {
                        Text(lm.s.paywallRestoreBtn)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(paywall.isLoading)
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            let products = (try? await Product.products(for: PaywallManager.allProductIDs)) ?? []
            monthlyProduct = products.first { $0.id == PaywallManager.productIDMonthly }
            yearlyProduct  = products.first { $0.id == PaywallManager.productIDYearly }
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let title: String
    let price: String?
    let period: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange, in: Capsule())
                } else {
                    Spacer().frame(height: 18)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .secondary)

                if let price {
                    Text(price)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.orange : .primary)
                        .monospacedDigit()
                } else {
                    ProgressView()
                        .frame(height: 28)
                }

                Text(period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? Color.orange.opacity(0.12)
                          : Color(red: 0.05, green: 0.08, blue: 0.03).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : Color.khakiBorder.opacity(0.4),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

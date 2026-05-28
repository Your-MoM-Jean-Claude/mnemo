import Foundation
import StoreKit

class PaywallManager: ObservableObject {
    static let productIDMonthly = "com.jirifilipec.mnemoapp.pro.monthly"
    static let productIDYearly  = "com.jirifilipec.mnemoapp.pro.yearly"
    static let allProductIDs    = [productIDMonthly, productIDYearly]
    static let trialDays        = 3

    @Published var isPurchased: Bool
    @Published var isLoading = false

    init() {
        self.isPurchased = UserDefaults.standard.bool(forKey: "isPurchased")
        registerInstallIfNeeded()
        Task { await refreshPurchaseStatus() }
    }

    private func registerInstallIfNeeded() {
        if UserDefaults.standard.double(forKey: "installDate") == 0 {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "installDate")
        }
    }

    private var installDate: Date {
        let ts = UserDefaults.standard.double(forKey: "installDate")
        return ts == 0 ? Date() : Date(timeIntervalSince1970: ts)
    }

    var isTrialActive: Bool {
        if isPurchased { return true }
        let days = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return days < Self.trialDays
    }

    var trialDaysRemaining: Int {
        if isPurchased { return Self.trialDays }
        let days = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(0, Self.trialDays - days)
    }

    func purchase(productID: String) async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else { return }
            let result = try await product.purchase()
            if case .success(let verification) = result, case .verified = verification {
                await MainActor.run {
                    isPurchased = true
                    UserDefaults.standard.set(true, forKey: "isPurchased")
                }
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }

    func restorePurchases() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if case .verified(let tx) = result,
                   Self.allProductIDs.contains(tx.productID) {
                    await MainActor.run {
                        isPurchased = true
                        UserDefaults.standard.set(true, forKey: "isPurchased")
                    }
                }
            }
        } catch {
            print("Restore error: \(error)")
        }
    }

    private func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               Self.allProductIDs.contains(tx.productID) {
                await MainActor.run {
                    isPurchased = true
                    UserDefaults.standard.set(true, forKey: "isPurchased")
                }
            }
        }
    }
}

import SwiftUI

@main
struct MnemoStudyApp: App {
    @StateObject private var library  = LibraryViewModel()
    @StateObject private var settings = SettingsViewModel()

    @State private var showSplash = true
    @State private var didSeed    = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !settings.settings.hasSeenOnboarding {
                    OnboardingView {
                        settings.settings.hasSeenOnboarding = true
                    }
                    .environmentObject(settings)
                } else if showSplash {
                    SplashView(lastDeck: library.lastStudiedEntry,
                               lang: settings.language,
                               onDismiss: dismissSplash)
                        .task {
                            // Auto-dismiss backstop. Cancelled automatically if the
                            // view goes away first, unlike the old asyncAfter block.
                            try? await Task.sleep(nanoseconds: 7 * 1_000_000_000)
                            dismissSplash()
                        }
                } else {
                    // No hard paywall — soft free tier + contextual Pro upsell
                    MainTabView()
                        .environmentObject(library)
                        .environmentObject(settings)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                // Parsing the 25 bundled .txt files used to run inside App.init(),
                // on the main thread, before the first frame could be drawn. Parse
                // off the main actor and only hop back to publish the result.
                guard !didSeed else { return }
                didSeed = true
                guard library.decks.isEmpty, !library.hasStoredLibrary else { return }

                let content = await Task.detached(priority: .userInitiated) {
                    BundledLibraryLoader.buildContent()
                }.value

                BundledLibraryLoader.apply(content, to: library)
            }
        }
    }

    private func dismissSplash() {
        guard showSplash else { return }
        withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
    }
}

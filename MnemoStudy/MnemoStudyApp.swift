import SwiftUI

@main
struct MnemoStudyApp: App {
    @StateObject private var library: LibraryViewModel
    @StateObject private var settings = SettingsViewModel()

    @State private var showSplash = true

    init() {
        let lib = LibraryViewModel()
        BundledLibraryLoader.loadInto(lib)
        _library = StateObject(wrappedValue: lib)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !settings.settings.hasSeenOnboarding {
                    OnboardingView {
                        settings.settings.hasSeenOnboarding = true
                    }
                } else if showSplash {
                    SplashView(lastDeck: library.lastStudiedEntry,
                               lang: settings.language,
                               onDismiss: { withAnimation(.easeOut(duration: 0.4)) { showSplash = false } })
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
                            }
                        }
                } else {
                    MainTabView()
                        .environmentObject(library)
                        .environmentObject(settings)
                        .fullScreenCover(isPresented: .constant(!settings.isTrialActive)) {
                            PaywallView()
                                .environmentObject(settings)
                        }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

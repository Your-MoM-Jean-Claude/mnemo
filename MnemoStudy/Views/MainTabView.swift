import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var library: LibraryViewModel
    @EnvironmentObject var settings: SettingsViewModel

    var lang: AppLanguage { settings.language }

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label(lang.tabLibrary, systemImage: "books.vertical.fill")
                }

            StatisticsView()
                .tabItem {
                    Label(lang.tabStats, systemImage: "chart.bar.fill")
                }

            FeedbackView()
                .tabItem {
                    Label("Feedback", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SettingsView()
                .tabItem {
                    Label(lang.tabSettings, systemImage: "gearshape.fill")
                }
        }
        .tint(.mnemoGreen)
    }
}

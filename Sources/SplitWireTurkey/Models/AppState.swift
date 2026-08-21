import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var statusMessage = ""
    @Published var selectedTab = 1  // Default to ByeDPI tab
    @Published var isDarkMode = false
    @Published var selectedLanguage: Language = .turkish

    // Favorite Apps for Quick Actions
    @Published var favoriteApps: [FavoriteApp] = []

    enum Language: String, CaseIterable {
        case turkish = "Türkçe"
        case english = "English"
        case russian = "Русский"
    }

    struct FavoriteApp: Codable, Identifiable, Equatable {
        let id: UUID
        var name: String
        let path: String
        let bundleIdentifier: String?
        var customArgs: String  // Custom proxy arguments for this app

        init(name: String, path: String, bundleIdentifier: String? = nil, customArgs: String = "--proxy-server=socks5://127.0.0.1:1080") {
            self.id = UUID()
            self.name = name
            self.path = path
            self.bundleIdentifier = bundleIdentifier
            self.customArgs = customArgs
        }
    }

    init() {
        loadSettings()
    }

    func loadSettings() {
        if let isDark = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            isDarkMode = isDark
        }

        if let langRaw = UserDefaults.standard.string(forKey: "language"),
           let lang = Language(rawValue: langRaw) {
            selectedLanguage = lang
        }

        // Load favorite apps
        if let data = UserDefaults.standard.data(forKey: "favoriteApps"),
           let apps = try? JSONDecoder().decode([FavoriteApp].self, from: data) {
            favoriteApps = apps
        } else {
            // Default favorites
            favoriteApps = [
                FavoriteApp(name: "Discord", path: "/Applications/Discord.app", bundleIdentifier: "com.hnc.Discord")
            ]
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "language")
        // Save favorite apps
        if let data = try? JSONEncoder().encode(favoriteApps) {
            UserDefaults.standard.set(data, forKey: "favoriteApps")
        }
    }

    // Favorite Apps Management
    func addFavoriteApp(_ app: FavoriteApp) {
        if !favoriteApps.contains(where: { $0.path == app.path }) {
            favoriteApps.append(app)
            saveSettings()
        }
    }

    func removeFavoriteApp(_ app: FavoriteApp) {
        favoriteApps.removeAll { $0.id == app.id }
        saveSettings()
    }

    func updateFavoriteApp(_ app: FavoriteApp) {
        if let index = favoriteApps.firstIndex(where: { $0.id == app.id }) {
            favoriteApps[index] = app
            saveSettings()
        }
    }

    func isFavorite(_ appPath: String) -> Bool {
        favoriteApps.contains { $0.path == appPath }
    }

}

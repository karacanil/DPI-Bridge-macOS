import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var selectedTab = 1
    @Published var isDarkMode: Bool {
        didSet { UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode") }
    }
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        language = .current
    }

    func text(_ key: String) -> String {
        L10n.text(key, language: language)
    }
}

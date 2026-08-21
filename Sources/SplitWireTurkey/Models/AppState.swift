import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var selectedTab = 1
    @Published var isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")

    func saveAppearance() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

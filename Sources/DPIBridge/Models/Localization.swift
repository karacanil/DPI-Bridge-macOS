import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    static var current: AppLanguage {
        guard let rawValue = UserDefaults.standard.string(forKey: "appLanguage"),
              let language = AppLanguage(rawValue: rawValue) else {
            return .turkish
        }
        return language
    }
}

enum L10n {
    private static let translations: [String: [AppLanguage: String]] = [
        "tab.about": [.turkish: "Hakkında", .english: "About"],
        "header.edition": [.turkish: "macOS Sürümü", .english: "macOS Edition"],
        "appearance.dark": [.turkish: "Koyu görünüm", .english: "Dark appearance"],

        "connect.title": [.turkish: "Discord'a Bağlan", .english: "Connect to Discord"],
        "connect.description": [
            .turkish: "DPI Bridge, Discord'u yalnızca bu Mac'te çalışan yerel proxy'ler üzerinden başlatır.",
            .english: "DPI Bridge launches Discord through local proxies that run only on this Mac."
        ],
        "setup.title": [.turkish: "İlk kullanım", .english: "First-time setup"],
        "setup.description": [
            .turkish: "İnternet sağlayıcınız Discord alan adlarını yanlış yönlendiriyorsa şifreli DNS profilini bir kez kurun.",
            .english: "Install the encrypted DNS profile once if your internet provider redirects Discord domains."
        ],
        "setup.openProfile": [.turkish: "Şifreli DNS Profilini Aç", .english: "Open Encrypted DNS Profile"],
        "connection.title": [.turkish: "Bağlantı", .english: "Connection"],
        "connection.start": [.turkish: "Discord'u Başlat", .english: "Launch Discord"],
        "connection.stop": [.turkish: "Durdur", .english: "Stop"],
        "connection.ports": [
            .turkish: "Yerel servisler: ByeDPI SOCKS5 127.0.0.1:1080 · Discord güncelleyici köprüsü 127.0.0.1:1081",
            .english: "Local services: ByeDPI SOCKS5 127.0.0.1:1080 · Discord updater bridge 127.0.0.1:1081"
        ],

        "status.ready": [.turkish: "Hazır", .english: "Ready"],
        "status.preparing": [.turkish: "Discord bağlantısı hazırlanıyor…", .english: "Preparing the Discord connection…"],
        "status.connected": [.turkish: "Discord proxy üzerinden başlatıldı", .english: "Discord launched through the proxy"],
        "status.stopping": [.turkish: "Yerel proxy'ler durduruluyor…", .english: "Stopping local proxies…"],
        "status.stopped": [.turkish: "Durduruldu", .english: "Stopped"],
        "status.error": [.turkish: "Hata", .english: "Error"],

        "error.connection.title": [.turkish: "Bağlantı kurulamadı", .english: "Connection failed"],
        "error.profile.title": [.turkish: "Profil bulunamadı", .english: "Profile not found"],
        "error.profile.missing": [
            .turkish: "Şifreli DNS profili uygulama paketinde bulunamadı. Uygulamayı yeniden indirin.",
            .english: "The encrypted DNS profile is missing from the app bundle. Download the app again."
        ],
        "error.port1080": [
            .turkish: "1080 portu başka bir uygulama tarafından kullanılıyor. Diğer proxy uygulamalarını kapatıp tekrar deneyin.",
            .english: "Port 1080 is in use by another app. Close other proxy apps and try again."
        ],
        "error.ciadpi.missing": [
            .turkish: "ByeDPI yardımcısı bulunamadı. Uygulamayı yeniden indirin.",
            .english: "The ByeDPI helper is missing. Download the app again."
        ],
        "error.ciadpi.start": [.turkish: "ByeDPI başlatılamadı.", .english: "ByeDPI could not be started."],
        "error.port1081": [
            .turkish: "1081 portu başka bir uygulama tarafından kullanılıyor. Diğer proxy uygulamalarını kapatıp tekrar deneyin.",
            .english: "Port 1081 is in use by another app. Close other proxy apps and try again."
        ],
        "error.bridge.missing": [
            .turkish: "Discord güncelleyici köprüsü bulunamadı. Uygulamayı yeniden indirin.",
            .english: "The Discord updater bridge is missing. Download the app again."
        ],
        "error.bridge.start": [
            .turkish: "Discord güncelleyici köprüsü başlatılamadı.",
            .english: "The Discord updater bridge could not be started."
        ],
        "error.discord.missing": [
            .turkish: "Discord /Applications klasöründe bulunamadı.",
            .english: "Discord was not found in /Applications."
        ],
        "alert.ok": [.turkish: "Tamam", .english: "OK"],

        "about.menu": [.turkish: "DPI-Bridge Hakkında", .english: "About DPI-Bridge"],
        "about.section": [.turkish: "Hakkında", .english: "About"],
        "about.description": [
            .turkish: "DPI-Bridge, macOS üzerinde Discord bağlantısını hazırlayan açık kaynaklı bir yardımcı uygulamadır.",
            .english: "DPI-Bridge is an open-source utility that prepares Discord connectivity on macOS."
        ],
        "about.security": [
            .turkish: "ByeDPI'ı ve Discord güncelleyici köprüsünü yalnızca localhost üzerinde çalıştırır; şifreli DNS profilini kullanıcı onayıyla açar.",
            .english: "It runs ByeDPI and the Discord updater bridge only on localhost and opens the encrypted DNS profile with user approval."
        ],
        "about.features": [.turkish: "Özellikler", .english: "Features"],
        "about.feature.byeDPI": [.turkish: "ByeDPI ile DPI aşımı (SOCKS5 proxy)", .english: "DPI circumvention with ByeDPI (SOCKS5 proxy)"],
        "about.feature.dns": [.turkish: "İsteğe bağlı şifreli DNS profili", .english: "Optional encrypted DNS profile"],
        "about.feature.discord": [.turkish: "Discord ve güncelleyici için otomatik proxy", .english: "Automatic proxy for Discord and its updater"],
        "about.components": [.turkish: "Açık Kaynak Bileşenler", .english: "Open-Source Components"],
        "about.components.description": [
            .turkish: "Bu uygulama ByeDPI / ciadpi bileşenini kullanır. Üçüncü taraf lisansları kaynak repoda korunur.",
            .english: "This app uses the ByeDPI / ciadpi component. Third-party licenses are preserved in the source repository."
        ],
        "about.license": [.turkish: "Lisans", .english: "License"],
        "about.contributors": [.turkish: "DPI Bridge katkıcıları", .english: "DPI Bridge contributors"],
        "about.repository": [.turkish: "Proje Reposu", .english: "Project Repository"]
    ]

    static func text(_ key: String, language: AppLanguage = .current) -> String {
        translations[key]?[language] ?? translations[key]?[.turkish] ?? key
    }
}

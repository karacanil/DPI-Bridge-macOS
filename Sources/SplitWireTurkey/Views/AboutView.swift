import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon and Version
                VStack(spacing: 12) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)

                    Text("SplitWire-Turkey")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("macOS Edition \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider()

                // Description
                GroupBox(label: Label("Hakkında", systemImage: "info.circle.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SplitWire-Turkey, macOS üzerinde Discord bağlantısını hazırlayan açık kaynaklı bir yardımcı uygulamadır.")
                            .fixedSize(horizontal: false, vertical: true)

                        Text("ByeDPI'ı ve Discord güncelleyici köprüsünü yalnızca localhost üzerinde çalıştırır; isteğe bağlı şifreli DNS profilini kullanıcı onayıyla açar.")
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // Features
                GroupBox(label: Label("Özellikler", systemImage: "star.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "shield.checkered", text: "ByeDPI ile DPI aşımı (SOCKS5 proxy)")
                        FeatureRow(icon: "lock.shield", text: "İsteğe bağlı şifreli DNS profili")
                        FeatureRow(icon: "command", text: "Discord ve güncelleyici için otomatik proxy")
                    }
                    .padding()
                }

                // Credits
                GroupBox(label: Label("Teşekkürler", systemImage: "heart.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Original Developer
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Orijinal Windows uygulaması:")
                                .fontWeight(.semibold)
                            Text("Çağrı Taşkın")
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // macOS Port Developer
                        VStack(alignment: .leading, spacing: 8) {
                            Text("macOS Portu:")
                                .fontWeight(.semibold)

                            HStack(spacing: 12) {
                                // GitHub Avatar style icon
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mert Dinçer")
                                        .fontWeight(.medium)

                                    Button(action: {
                                        if let url = URL(string: "https://github.com/a-mertdincer") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "link")
                                                .font(.caption)
                                            Text("@a-mertdincer")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Divider()

                        Text("Kullanılan Araçlar:")
                            .fontWeight(.semibold)
                        Text("• ByeDPI / ciadpi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // License
                GroupBox(label: Label("Lisans", systemImage: "doc.text.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MIT License")
                            .fontWeight(.semibold)
                        Text("SplitWire Turkey contributors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // Links
                VStack(spacing: 8) {
                    Button(action: {
                        if let url = URL(string: "https://github.com/cagritaskn/SplitWire-Turkey") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                            Text("GitHub Sayfası (Orijinal Proje)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.accentColor)
            Text(text)
            Spacer()
        }
    }
}

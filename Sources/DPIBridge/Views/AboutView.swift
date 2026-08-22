import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)

                    Text("DPI-Bridge")
                        .font(.largeTitle.bold())

                    Text("\(appState.text("header.edition")) \(version)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider()

                GroupBox(label: Label(appState.text("about.section"), systemImage: "info.circle.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(appState.text("about.description"))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(appState.text("about.security"))
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }

                GroupBox(label: Label(appState.text("about.features"), systemImage: "star.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "shield.checkered", text: appState.text("about.feature.byeDPI"))
                        FeatureRow(icon: "lock.shield", text: appState.text("about.feature.dns"))
                        FeatureRow(icon: "command", text: appState.text("about.feature.discord"))
                    }
                    .padding()
                }

                GroupBox(label: Label(appState.text("about.components"), systemImage: "shippingbox.fill")) {
                    Text(appState.text("about.components.description"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
                        .padding()
                }

                GroupBox(label: Label(appState.text("about.license"), systemImage: "doc.text.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MIT License").fontWeight(.semibold)
                        Text(appState.text("about.contributors"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }

                Button {
                    if let url = URL(string: "https://github.com/karacanil/DPI-Bridge-macOS") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label(appState.text("about.repository"), systemImage: "link.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
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

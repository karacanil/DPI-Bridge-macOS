import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            TabView(selection: $appState.selectedTab) {
                ByeDPIView()
                    .tabItem {
                        Label("Discord", systemImage: "message.fill")
                    }
                    .tag(1)

                AboutView()
                    .tabItem {
                        Label("Hakkında", systemImage: "info.circle")
                    }
                    .tag(3)
            }
            .padding()

        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
    }
}

struct HeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SplitWire-Turkey")
                    .font(.title)
                    .fontWeight(.bold)
                Text("macOS Edition")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $appState.isDarkMode)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: appState.isDarkMode) { _ in
                    appState.saveAppearance()
                }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

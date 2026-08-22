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
                        Label(appState.text("tab.about"), systemImage: "info.circle")
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
                Text("DPI-Bridge")
                    .font(.title)
                    .fontWeight(.bold)
                Text(appState.text("header.edition"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Picker("", selection: $appState.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 110)

            Toggle("", isOn: $appState.isDarkMode)
                .toggleStyle(.switch)
                .labelsHidden()
                .help(appState.text("appearance.dark"))
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

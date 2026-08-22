import SwiftUI

struct ByeDPIView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var service = ByeDPIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.text("connect.title"))
                    .font(.title2.bold())
                Text(appState.text("connect.description"))
                    .foregroundColor(.secondary)
            }

            GroupBox(appState.text("setup.title")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(appState.text("setup.description"))
                        .foregroundColor(.secondary)
                    Button(appState.text("setup.openProfile"), systemImage: "lock.shield") {
                        service.openEncryptedDNSProfile()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }

            GroupBox(appState.text("connection.title")) {
                VStack(alignment: .leading, spacing: 14) {
                    Label(
                        service.statusText(language: appState.language),
                        systemImage: service.isRunning ? "checkmark.circle.fill" : (service.hasError ? "exclamationmark.triangle.fill" : "circle")
                    )
                    .foregroundColor(service.isRunning ? .green : (service.hasError ? .red : .secondary))
                    if service.isProcessing {
                        ProgressView().progressViewStyle(.linear)
                    }
                    HStack {
                        Button(appState.text("connection.start"), systemImage: "play.fill") {
                            Task { await service.connectDiscord() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(service.isProcessing)

                        Button(appState.text("connection.stop"), systemImage: "stop.fill") {
                            Task { await service.stop() }
                        }
                        .disabled(service.isProcessing || !service.isRunning)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }

            Text(appState.text("connection.ports"))
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .frame(minWidth: 620, minHeight: 430)
        .onAppear { service.refreshStatus() }
    }
}

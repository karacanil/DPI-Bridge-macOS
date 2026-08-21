import SwiftUI

struct ByeDPIView: View {
    @ObservedObject private var service = ByeDPIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Discord'a Bağlan")
                    .font(.title2.bold())
                Text("SplitWire, Discord'u yalnızca bu Mac'te çalışan yerel proxy'ler üzerinden başlatır.")
                    .foregroundColor(.secondary)
            }

            GroupBox("İlk kullanım") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("İnternet sağlayıcınız Discord alan adlarını yanlış yönlendiriyorsa şifreli DNS profilini bir kez kurun.")
                        .foregroundColor(.secondary)
                    Button("Şifreli DNS Profilini Aç", systemImage: "lock.shield") {
                        service.openEncryptedDNSProfile()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }

            GroupBox("Bağlantı") {
                VStack(alignment: .leading, spacing: 14) {
                    Label(service.statusMessage, systemImage: service.isRunning ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(service.isRunning ? .green : .secondary)
                    if service.isProcessing {
                        ProgressView().progressViewStyle(.linear)
                    }
                    HStack {
                        Button("Discord'u Başlat", systemImage: "play.fill") {
                            Task { await service.connectDiscord() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(service.isProcessing)

                        Button("Durdur", systemImage: "stop.fill") {
                            Task { await service.stop() }
                        }
                        .disabled(service.isProcessing || !service.isRunning)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }

            Text("Yerel servisler: ByeDPI SOCKS5 127.0.0.1:1080 · Discord güncelleyici köprüsü 127.0.0.1:1081")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .frame(minWidth: 620, minHeight: 430)
        .onAppear { service.refreshStatus() }
    }
}

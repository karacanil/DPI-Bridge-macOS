import AppKit
import Combine
import Darwin
import Foundation

@MainActor
final class ByeDPIService: ObservableObject {
    static let shared = ByeDPIService()

    @Published private(set) var isRunning = false
    @Published private(set) var isProcessing = false
    @Published private(set) var statusMessage = "Hazır"

    private var byeDPIProcess: Process?
    private var proxyBridgeProcess: Process?

    func connectDiscord() async {
        guard !isProcessing else { return }
        isProcessing = true
        statusMessage = "Discord bağlantısı hazırlanıyor…"
        defer { isProcessing = false }

        do {
            if byeDPIProcess?.isRunning != true {
                try startByeDPI()
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            try startProxyBridge()
            try await Task.sleep(nanoseconds: 300_000_000)
            try await launchDiscord()
            isRunning = true
            statusMessage = "Discord proxy üzerinden başlatıldı"
        } catch {
            await stopManagedProcesses()
            statusMessage = "Hata: \(error.localizedDescription)"
            showAlert(title: "Bağlantı kurulamadı", message: error.localizedDescription)
        }
    }

    func stop() async {
        guard !isProcessing else { return }
        isProcessing = true
        statusMessage = "Yerel proxy'ler durduruluyor…"
        await stopManagedProcesses()
        statusMessage = "Durduruldu"
        isProcessing = false
    }

    func shutdown() {
        for process in [proxyBridgeProcess, byeDPIProcess].compactMap({ $0 }) where process.isRunning {
            process.terminate()
            if process.isRunning {
                Darwin.kill(process.processIdentifier, SIGKILL)
            }
        }
        proxyBridgeProcess = nil
        byeDPIProcess = nil
        isRunning = false
    }

    func refreshStatus() {
        isRunning = byeDPIProcess?.isRunning == true && proxyBridgeProcess?.isRunning == true
    }

    func openEncryptedDNSProfile() {
        guard let profilePath = firstExistingPath(profileCandidates()) else {
            showAlert(title: "Profil bulunamadı", message: "Şifreli DNS profili uygulama paketinde bulunamadı. Uygulamayı yeniden indirin.")
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: profilePath))
    }

    private func startByeDPI() throws {
        guard !isPortListening(1080) else {
            throw serviceError("1080 portu başka bir uygulama tarafından kullanılıyor. Diğer proxy uygulamalarını kapatıp tekrar deneyin.")
        }
        guard let path = firstExistingPath(ciadpiCandidates()) else {
            throw serviceError("ByeDPI yardımcısı bulunamadı. Uygulamayı yeniden indirin.")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = [
            "--ip", "127.0.0.1",
            "--disorder", "1", "--auto=torst", "--tlsrec", "1+s"
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        guard process.isRunning else { throw serviceError("ByeDPI başlatılamadı.") }
        byeDPIProcess = process
    }

    private func startProxyBridge() throws {
        if proxyBridgeProcess?.isRunning == true { return }
        guard !isPortListening(1081) else {
            throw serviceError("1081 portu başka bir uygulama tarafından kullanılıyor. Diğer proxy uygulamalarını kapatıp tekrar deneyin.")
        }
        guard let path = firstExistingPath(proxyBridgeCandidates()) else {
            throw serviceError("Discord güncelleyici köprüsü bulunamadı. Uygulamayı yeniden indirin.")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        guard process.isRunning else { throw serviceError("Discord güncelleyici köprüsü başlatılamadı.") }
        proxyBridgeProcess = process
    }

    private func launchDiscord() async throws {
        let path = "/Applications/Discord.app/Contents/MacOS/Discord"
        guard FileManager.default.fileExists(atPath: path) else {
            throw serviceError("Discord /Applications klasöründe bulunamadı.")
        }

        let runningDiscord = NSRunningApplication.runningApplications(withBundleIdentifier: "com.hnc.Discord")
        runningDiscord.forEach { $0.terminate() }
        if !runningDiscord.isEmpty { try? await Task.sleep(nanoseconds: 1_000_000_000) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--proxy-server=socks5://127.0.0.1:1080", "--disable-quic"]
        var environment = ProcessInfo.processInfo.environment
        let updaterProxy = "http://127.0.0.1:1081"
        for key in ["HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "https_proxy", "http_proxy", "all_proxy"] {
            environment[key] = updaterProxy
        }
        environment["NO_PROXY"] = "127.0.0.1,localhost"
        environment["no_proxy"] = "127.0.0.1,localhost"
        process.environment = environment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private func stopManagedProcesses() async {
        let processes = [proxyBridgeProcess, byeDPIProcess].compactMap { $0 }
        processes.filter(\.isRunning).forEach { $0.terminate() }
        try? await Task.sleep(nanoseconds: 300_000_000)
        for process in processes where process.isRunning {
            Darwin.kill(process.processIdentifier, SIGKILL)
        }
        proxyBridgeProcess = nil
        byeDPIProcess = nil
        isRunning = false
    }

    private func isPortListening(_ port: Int) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func ciadpiCandidates() -> [String] {
        resourcePath("bin/ciadpi") + developmentPaths("Sources/SplitWireTurkey/Resources/bin/ciadpi")
    }

    private func proxyBridgeCandidates() -> [String] {
        resourcePath("bin/discord-http-proxy")
            + developmentPaths(".build/universal/release/discord-http-proxy")
            + developmentPaths(".build/debug/discord-http-proxy")
    }

    private func profileCandidates() -> [String] {
        resourcePath("profiles/SplitWire-Cloudflare-Encrypted-DNS.mobileconfig")
            + developmentPaths("SplitWire-Cloudflare-Encrypted-DNS.mobileconfig")
    }

    private func resourcePath(_ relativePath: String) -> [String] {
        guard let base = Bundle.main.resourcePath else { return [] }
        return [(base as NSString).appendingPathComponent(relativePath)]
    }

    private func developmentPaths(_ relativePath: String) -> [String] {
        [(FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(relativePath)]
    }

    private func firstExistingPath(_ candidates: [String]) -> String? {
        candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    private func serviceError(_ message: String) -> NSError {
        NSError(domain: "SplitWire", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
}

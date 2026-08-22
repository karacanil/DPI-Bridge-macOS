import AppKit
import Combine
import Darwin
import Foundation

@MainActor
final class ByeDPIService: ObservableObject {
    enum Status {
        case ready
        case preparing
        case connected
        case stopping
        case stopped
        case error(String)
    }

    static let shared = ByeDPIService()

    @Published private(set) var isRunning = false
    @Published private(set) var isProcessing = false
    @Published private(set) var status = Status.ready

    private var byeDPIProcess: Process?
    private var proxyBridgeProcess: Process?

    func connectDiscord() async {
        guard !isProcessing else { return }
        isProcessing = true
        status = .preparing
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
            status = .connected
        } catch {
            await stopManagedProcesses()
            status = .error(error.localizedDescription)
            showAlert(titleKey: "error.connection.title", message: error.localizedDescription)
        }
    }

    func stop() async {
        guard !isProcessing else { return }
        isProcessing = true
        status = .stopping
        await stopManagedProcesses()
        status = .stopped
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

    func statusText(language: AppLanguage) -> String {
        switch status {
        case .ready: return L10n.text("status.ready", language: language)
        case .preparing: return L10n.text("status.preparing", language: language)
        case .connected: return L10n.text("status.connected", language: language)
        case .stopping: return L10n.text("status.stopping", language: language)
        case .stopped: return L10n.text("status.stopped", language: language)
        case .error(let message):
            return "\(L10n.text("status.error", language: language)): \(message)"
        }
    }

    var hasError: Bool {
        if case .error = status { return true }
        return false
    }

    func openEncryptedDNSProfile() {
        guard let profilePath = firstExistingPath(profileCandidates()) else {
            showAlert(
                titleKey: "error.profile.title",
                message: L10n.text("error.profile.missing")
            )
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: profilePath))
    }

    private func startByeDPI() throws {
        guard !isPortListening(1080) else {
            throw serviceError(L10n.text("error.port1080"))
        }
        guard let path = firstExistingPath(ciadpiCandidates()) else {
            throw serviceError(L10n.text("error.ciadpi.missing"))
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
        guard process.isRunning else { throw serviceError(L10n.text("error.ciadpi.start")) }
        byeDPIProcess = process
    }

    private func startProxyBridge() throws {
        if proxyBridgeProcess?.isRunning == true { return }
        guard !isPortListening(1081) else {
            throw serviceError(L10n.text("error.port1081"))
        }
        guard let path = firstExistingPath(proxyBridgeCandidates()) else {
            throw serviceError(L10n.text("error.bridge.missing"))
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        guard process.isRunning else { throw serviceError(L10n.text("error.bridge.start")) }
        proxyBridgeProcess = process
    }

    private func launchDiscord() async throws {
        let path = "/Applications/Discord.app/Contents/MacOS/Discord"
        guard FileManager.default.fileExists(atPath: path) else {
            throw serviceError(L10n.text("error.discord.missing"))
        }

        let runningDiscord = NSRunningApplication.runningApplications(withBundleIdentifier: "com.hnc.Discord")
        runningDiscord.forEach { $0.terminate() }
        if !runningDiscord.isEmpty { try? await Task.sleep(nanoseconds: 1_000_000_000) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        let updaterProxy = "http://127.0.0.1:1081"
        var arguments = ["-n", "-b", "com.hnc.Discord"]
        for key in ["HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "https_proxy", "http_proxy", "all_proxy"] {
            arguments += ["--env", "\(key)=\(updaterProxy)"]
        }
        arguments += [
            "--env", "NO_PROXY=127.0.0.1,localhost",
            "--env", "no_proxy=127.0.0.1,localhost",
            "--args", "--proxy-server=socks5://127.0.0.1:1080", "--disable-quic"
        ]
        process.arguments = arguments
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
        resourcePath("bin/ciadpi") + developmentPaths("Sources/DPIBridge/Resources/bin/ciadpi")
    }

    private func proxyBridgeCandidates() -> [String] {
        resourcePath("bin/discord-http-proxy")
            + developmentPaths(".build/universal/release/discord-http-proxy")
            + developmentPaths(".build/debug/discord-http-proxy")
    }

    private func profileCandidates() -> [String] {
        resourcePath("profiles/DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig")
            + developmentPaths("DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig")
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
        NSError(domain: "DPIBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func showAlert(titleKey: String, message: String) {
        let alert = NSAlert()
        alert.messageText = L10n.text(titleKey)
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.text("alert.ok"))
        alert.runModal()
    }
}

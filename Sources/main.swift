import AppKit
import ServiceManagement

final class BarButton: NSButton {
    override var acceptsFirstResponder: Bool { false }
    override func rightMouseDown(with event: NSEvent) { performClick(nil) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private let button = BarButton()
    private var timer: Timer?
    private var snapshot: MemorySnapshot?
    private let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A second launch does not create a duplicate overlay.
        let duplicates = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.memoryusagebar")
        if duplicates.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        button.isBordered = false
        button.bezelStyle = .inline
        button.alignment = .left
        button.lineBreakMode = .byClipping
        button.target = self
        button.action = #selector(showMenu)
        button.setAccessibilityLabel("Memory usage")
        panel.contentView = button
        refresh()
        panel.orderFrontRegardless()
        timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        timer?.tolerance = 5
        RunLoop.main.add(timer!, forMode: .common)
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.reposition() })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.refresh() })
    }

    private func refresh() {
        snapshot = MemoryReader.read()
        let title = NSMutableAttributedString(string: "内存 ", attributes: [.font: font, .foregroundColor: NSColor.labelColor])
        title.append(NSAttributedString(string: snapshot.map { "\($0.percentage)%" } ?? "—", attributes: [
            .font: font, .foregroundColor: snapshot == nil ? NSColor.secondaryLabelColor : NSColor.systemGreen
        ]))
        button.attributedTitle = title
        button.setAccessibilityValue(snapshot.map { "\($0.percentage) percent" } ?? "Unavailable")
        button.toolTip = snapshot.map { String(format: "Memory used: %.2f GiB / %.2f GiB\nClick for options", Double($0.used) / 1_073_741_824, Double($0.physical) / 1_073_741_824) } ?? "Unable to read memory usage. Click to retry."
        reposition()
    }

    private func reposition() {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 && $0.auxiliaryTopRightArea != nil }) ?? NSScreen.screens.first else {
            panel.orderOut(nil)
            return
        }
        // Reserve enough space for 100%, avoiding width changes as usage changes.
        let width = ceil(("内存 100%" as NSString).size(withAttributes: [.font: font]).width) + 10
        let frame = BarPlacement.frame(screen: screen.frame, rightArea: screen.auxiliaryTopRightArea,
                                       topInset: screen.safeAreaInsets.top, width: width,
                                       menuHeight: NSStatusBar.system.thickness)
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    @objc private func showMenu() {
        let menu = NSMenu()
        let heading = NSMenuItem(title: "MemoryUsageBar 1.0.0", action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit MemoryUsageBar", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: button)
    }

    @objc private func refreshNow() { refresh() }
    @objc private func quitApp() { NSApp.terminate(nil) }
    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not update Launch at Login"
            alert.informativeText = error.localizedDescription + "\nMove MemoryUsageBar to /Applications and try again."
            alert.runModal()
        }
    }
}

if CommandLine.arguments.contains("--sample") {
    if let sample = MemoryReader.read() {
        print("内存 \(sample.percentage)% (\(sample.used)/\(sample.physical) bytes)")
    } else {
        fputs("Unable to read host memory statistics\n", stderr)
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    app.run()
}

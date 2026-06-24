import AppKit
import LidRunnerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let powerManager = PowerManager()
    private let pmset = PMSetService()
    private let privilegedPMSet = PrivilegedPMSetService()
    private let preferencesStore = PreferencesStore()
    private let powerSourceMonitor = PowerSourceMonitor()
    private let lidStateMonitor = LidStateMonitor()
    private let loginItemService = LoginItemService()
    private let screenLockService = ScreenLockService()

    private var preferences = AppPreferences.defaults
    private var currentPowerSource = PowerSource.unknown
    private var currentLidState = LidState.unknown
    private var isChangingClosedLidMode = false

    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var powerSourceStatus = NSTextField(labelWithString: "")
    private var appStatus = NSTextField(labelWithString: "")
    private var lidStateStatus = NSTextField(labelWithString: "")
    private var lidStatus = NSTextField(labelWithString: "")
    private var loginStatus = NSTextField(labelWithString: "")
    private var messageLabel = NSTextField(wrappingLabelWithString: "")
    private var enableAppCheckbox = NSButton()
    private var acOnlyCheckbox = NSButton()
    private var launchAtLoginCheckbox = NSButton()

    func applicationDidFinishLaunching(_ notification: Notification) {
        preferences = preferencesStore.load()
        currentPowerSource = powerSourceMonitor.currentPowerSource()
        currentLidState = lidStateMonitor.currentLidState()

        NSApp.setActivationPolicy(.regular)
        configureMainMenu()
        configureStatusItem()
        configureWindow()
        configurePowerSourceMonitor()
        configureLidStateMonitor()
        updateControlValues()
        applyPowerPolicy(message: "Ready")

        if shouldShowWindowOnLaunch {
            showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        powerSourceMonitor.stop()
        lidStateMonitor.stop()
        powerManager.stop()
    }

    private var shouldShowWindowOnLaunch: Bool {
        preferences.showWindowOnLaunch && loginItemService.status != .enabled
    }

    private func configurePowerSourceMonitor() {
        powerSourceMonitor.onChange = { [weak self] source in
            DispatchQueue.main.async {
                self?.powerSourceDidChange(source)
            }
        }
        powerSourceMonitor.start()
    }

    private func configureLidStateMonitor() {
        lidStateMonitor.onChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.lidStateDidChange(state)
            }
        }
        lidStateMonitor.start()
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(withTitle: "Show \(AppInfo.name)", action: #selector(showWindow(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit \(AppInfo.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: AppInfo.name)
        item.button?.imagePosition = .imageLeading
        item.button?.title = "Lid"
        statusItem = item
        updateStatusMenu()
    }

    private func configureWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppInfo.name
        window.center()
        window.contentView = makeContentView()
        self.window = window
    }

    private func makeContentView() -> NSView {
        let root = NSView()

        let title = NSTextField(labelWithString: AppInfo.name)
        title.font = .systemFont(ofSize: 28, weight: .semibold)
        title.alignment = .center

        let subtitle = NSTextField(wrappingLabelWithString: "One switch keeps the Mac running; charger-only pauses it on battery.")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center

        powerSourceStatus = statusValueLabel()
        appStatus = statusValueLabel()
        lidStateStatus = statusValueLabel()
        lidStatus = statusValueLabel()
        loginStatus = statusValueLabel()
        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 2

        let statusGrid = NSGridView(views: [
            [statusNameLabel("Power"), powerSourceStatus],
            [statusNameLabel("LidRunner"), appStatus],
            [statusNameLabel("Lid"), lidStateStatus],
            [statusNameLabel("Closed lid"), lidStatus],
            [statusNameLabel("Login"), loginStatus]
        ])
        statusGrid.column(at: 0).xPlacement = .trailing
        statusGrid.column(at: 1).xPlacement = .leading
        statusGrid.rowSpacing = 10
        statusGrid.columnSpacing = 14

        enableAppCheckbox = checkbox(
            title: "Enable LidRunner",
            action: #selector(toggleLidRunner(_:))
        )
        acOnlyCheckbox = checkbox(
            title: "Only on Charger",
            action: #selector(toggleOnlyWhenOnACPower(_:))
        )
        launchAtLoginCheckbox = checkbox(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:))
        )

        let controlStack = NSStackView(views: [
            enableAppCheckbox,
            acOnlyCheckbox,
            launchAtLoginCheckbox
        ])
        controlStack.orientation = .vertical
        controlStack.alignment = .leading
        controlStack.spacing = 10

        let stack = NSStackView(views: [
            title,
            subtitle,
            statusGrid,
            controlStack,
            messageLabel
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -22),
            controlStack.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        return root
    }

    private func statusNameLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func statusValueLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        return label
    }

    private func checkbox(title: String, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.controlSize = .large
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func updateStatusMenu() {
        let menu = NSMenu()

        let enableItem = menu.addItem(withTitle: "Enable LidRunner", action: #selector(toggleLidRunner(_:)), keyEquivalent: "")
        enableItem.state = preferences.awakeModeEnabled ? .on : .off

        let acOnlyItem = menu.addItem(withTitle: "Only on Charger", action: #selector(toggleOnlyWhenOnACPower(_:)), keyEquivalent: "")
        acOnlyItem.state = preferences.onlyWhenOnACPower ? .on : .off

        let loginItem = menu.addItem(withTitle: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.state = loginItemService.status == .enabled ? .on : .off

        menu.addItem(.separator())
        menu.addItem(disabledMenuItem("Power: \(currentPowerSource.title)"))
        menu.addItem(disabledMenuItem("Lid: \(currentLidState.title)"))
        menu.addItem(disabledMenuItem("State: \(appStateTitle)"))
        menu.addItem(disabledMenuItem("Closed lid: \(pmset.readClosedLidStatus().title)"))
        menu.addItem(disabledMenuItem("Helper: \(privilegedPMSet.status.title)"))

        menu.addItem(.separator())
        if privilegedPMSet.status == .enabled {
            menu.addItem(withTitle: "Remove Privileged Helper", action: #selector(uninstallPrivilegedHelper(_:)), keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "Install Privileged Helper", action: #selector(installPrivilegedHelper(_:)), keyEquivalent: "")
        }

        menu.addItem(.separator())
        menu.addItem(withTitle: "Show \(AppInfo.name)", action: #selector(showWindow(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    private func disabledMenuItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private var currentDecision: PowerPolicyDecision {
        PowerPolicy.decision(preferences: preferences, powerSource: currentPowerSource)
    }

    private var appStateTitle: String {
        if isChangingClosedLidMode {
            return "Updating"
        }

        switch currentDecision {
        case .runAssertions:
            return powerManager.isAwake ? "Running" : "Starting"
        case .disabledByPreference:
            return "Off"
        case .blockedByPowerSource:
            return "Paused"
        }
    }

    private var shouldRun: Bool {
        currentDecision == .runAssertions
    }

    private func updateControlValues() {
        enableAppCheckbox.state = preferences.awakeModeEnabled ? .on : .off
        acOnlyCheckbox.state = preferences.onlyWhenOnACPower ? .on : .off
        launchAtLoginCheckbox.state = loginItemService.status == .enabled ? .on : .off
    }

    private func updateStatusLabels() {
        powerSourceStatus.stringValue = currentPowerSource.title
        appStatus.stringValue = appStateTitle
        lidStateStatus.stringValue = currentLidState.title
        lidStatus.stringValue = pmset.readClosedLidStatus().title
        loginStatus.stringValue = loginItemService.status.title
        updateControlValues()
        setControlsEnabled(!isChangingClosedLidMode)
        updateStatusMenu()
    }

    private func setControlsEnabled(_ enabled: Bool) {
        enableAppCheckbox.isEnabled = enabled
        acOnlyCheckbox.isEnabled = enabled
        launchAtLoginCheckbox.isEnabled = enabled
    }

    private func savePreferences() {
        preferencesStore.save(preferences)
    }

    private func applyPowerPolicy(message: String? = nil) {
        do {
            if shouldRun {
                try powerManager.start()
            } else {
                powerManager.stop()
            }
        } catch {
            showError(error)
            messageLabel.stringValue = "Could not update awake assertion"
            updateStatusLabels()
            return
        }

        let desiredClosedLidMode = shouldRun
        updateStatusLabels()
        reconcileClosedLidMode(enabled: desiredClosedLidMode, message: message ?? defaultMessage())
    }

    private func defaultMessage() -> String {
        switch currentDecision {
        case .runAssertions:
            return "LidRunner is running"
        case .disabledByPreference:
            return "LidRunner is off"
        case .blockedByPowerSource:
            return "Paused until charger is connected"
        }
    }

    private func reconcileClosedLidMode(enabled: Bool, message: String) {
        let status = pmset.readClosedLidStatus()

        if !enabled && status != .enabled {
            messageLabel.stringValue = message
            updateStatusLabels()
            return
        }

        if enabled && status == .enabled {
            messageLabel.stringValue = message
            updateStatusLabels()
            return
        }

        if enabled && preferences.onlyWhenOnACPower && currentPowerSource != .acPower {
            messageLabel.stringValue = "Paused until charger is connected"
            updateStatusLabels()
            return
        }

        setClosedLidMode(enabled: enabled, successMessage: message)
    }

    private func setClosedLidMode(enabled: Bool, successMessage: String) {
        isChangingClosedLidMode = true
        updateStatusLabels()
        messageLabel.stringValue = enabled ? "Enabling closed-lid mode..." : "Disabling closed-lid mode..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let result = Result {
                if self.privilegedPMSet.status == .enabled {
                    try self.privilegedPMSet.setClosedLidMode(enabled: enabled)
                } else {
                    try self.pmset.setClosedLidMode(enabled: enabled)
                }
            }

            DispatchQueue.main.async {
                self.isChangingClosedLidMode = false

                switch result {
                case .success:
                    self.updateStatusLabels()
                    self.messageLabel.stringValue = successMessage
                case let .failure(error):
                    self.showError(error)
                    self.updateStatusLabels()
                    self.messageLabel.stringValue = "Closed-lid mode did not change"
                }
            }
        }
    }

    private func powerSourceDidChange(_ source: PowerSource) {
        guard source != currentPowerSource else {
            updateStatusLabels()
            return
        }

        currentPowerSource = source
        applyPowerPolicy(message: "Power source: \(source.title)")
    }

    private func lidStateDidChange(_ state: LidState) {
        let previousState = currentLidState
        currentLidState = state

        if previousState != .closed && state == .closed {
            lockScreenForClosedLidIfNeeded()
        }

        updateStatusLabels()
    }

    private func lockScreenForClosedLidIfNeeded() {
        guard shouldRun else { return }

        messageLabel.stringValue = "Locking screen and sleeping displays..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result = Result {
                try self.screenLockService.lockScreenAndSleepDisplays()
            }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.messageLabel.stringValue = "Screen locked and displays sleeping"
                case let .failure(error):
                    self.messageLabel.stringValue = "Could not sleep displays: \(error.localizedDescription)"
                }
            }
        }
    }

    @objc private func showWindow(_ sender: Any?) {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleLidRunner(_ sender: Any?) {
        preferences.awakeModeEnabled = desiredState(from: sender, current: preferences.awakeModeEnabled)
        savePreferences()
        applyPowerPolicy()
    }

    @objc private func toggleOnlyWhenOnACPower(_ sender: Any?) {
        preferences.onlyWhenOnACPower = desiredState(from: sender, current: preferences.onlyWhenOnACPower)
        savePreferences()
        applyPowerPolicy()
    }

    @objc private func toggleLaunchAtLogin(_ sender: Any?) {
        let enabled = desiredState(from: sender, current: loginItemService.status == .enabled)
        setControlsEnabled(false)

        do {
            try loginItemService.setEnabled(enabled)
            messageLabel.stringValue = enabled ? "Launch at login enabled" : "Launch at login disabled"
        } catch {
            showError(error)
            messageLabel.stringValue = "Launch at login did not change"
        }

        setControlsEnabled(true)
        updateStatusLabels()
    }

    @objc private func installPrivilegedHelper(_ sender: Any?) {
        do {
            try privilegedPMSet.register()
            messageLabel.stringValue = helperInstallMessage()
        } catch {
            showError(error)
            messageLabel.stringValue = "Privileged helper did not change"
        }

        updateStatusLabels()
    }

    @objc private func uninstallPrivilegedHelper(_ sender: Any?) {
        do {
            try privilegedPMSet.unregister()
            messageLabel.stringValue = "Privileged helper removed"
        } catch {
            showError(error)
            messageLabel.stringValue = "Privileged helper did not change"
        }

        updateStatusLabels()
    }

    private func helperInstallMessage() -> String {
        switch privilegedPMSet.status {
        case .enabled:
            return "Privileged helper enabled"
        case .requiresApproval:
            return "Approve LidRunner in Login Items & Background Items"
        case .notFound:
            return "Privileged helper was not found in this app bundle"
        case .disabled:
            return "Privileged helper registered"
        case .unavailable:
            return "Privileged helper is unavailable"
        }
    }

    private func desiredState(from sender: Any?, current: Bool) -> Bool {
        if let button = sender as? NSButton {
            return button.state == .on
        }

        if sender is NSMenuItem {
            return !current
        }

        return !current
    }

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\(AppInfo.name) could not finish that action"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

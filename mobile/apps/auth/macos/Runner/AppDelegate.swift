import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {

  private var wasLaunchedAtLogin = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Detect if the app was launched as a login item by checking the Apple Event.
    // macOS sends kAEOpenApplication with keyAELaunchedAsLogInItem ('lgni')
    // when the app is opened at login via SMAppService.
    let event = NSAppleEventManager.shared().currentAppleEvent
    let loginItemCode = UInt32(0x6C676E69) // 'lgni' = keyAELaunchedAsLogInItem
    wasLaunchedAtLogin = event?.paramDescriptor(forKeyword: keyAEPropData)?
      .enumCodeValue == loginItemCode

    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "io.ente.auth/launchAtLogin",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "enable":
        self.enableLaunchAtLogin(result: result)
      case "disable":
        self.disableLaunchAtLogin(result: result)
      case "isEnabled":
        self.isLaunchAtLoginEnabled(result: result)
      case "wasAutoLaunched":
        result(self.wasLaunchedAtLogin)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      sender.windows.first?.makeKeyAndOrderFront(self)
    }
    return true
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    NSApp.setActivationPolicy(.accessory)
    return false
  }

  // MARK: - Launch at Login (macOS 13+)

  private func enableLaunchAtLogin(result: @escaping FlutterResult) {
    if #available(macOS 13.0, *) {
      do {
        try SMAppService.mainApp.register()
        result(true)
      } catch {
        result(FlutterError(code: "REGISTER_FAILED",
                            message: error.localizedDescription,
                            details: nil))
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED",
                          message: "Launch at login requires macOS 13.0 or later",
                          details: nil))
    }
  }

  private func disableLaunchAtLogin(result: @escaping FlutterResult) {
    if #available(macOS 13.0, *) {
      do {
        try SMAppService.mainApp.unregister()
        result(true)
      } catch {
        result(FlutterError(code: "UNREGISTER_FAILED",
                            message: error.localizedDescription,
                            details: nil))
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED",
                          message: "Launch at login requires macOS 13.0 or later",
                          details: nil))
    }
  }

  private func isLaunchAtLoginEnabled(result: @escaping FlutterResult) {
    if #available(macOS 13.0, *) {
      result(SMAppService.mainApp.status == .enabled)
    } else {
      result(false)
    }
  }
}

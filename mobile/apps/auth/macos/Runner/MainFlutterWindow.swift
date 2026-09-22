import Cocoa
import FlutterMacOS
import ServiceManagement
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    FlutterMethodChannel(
      name: "io.ente.auth/launch_at_login",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { (call, result) in
      MainFlutterWindow.handleLaunchAtLogin(call: call, result: result)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }

  private static func handleLaunchAtLogin(
    call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    guard #available(macOS 13.0, *) else {
      if call.method == "isSupported" || call.method == "isEnabled" {
        result(false)
      } else {
        result(
          FlutterError(
            code: "unsupported",
            message: "Launch at login requires macOS 13 or later",
            details: nil
          ))
      }
      return
    }

    switch call.method {
    case "isSupported":
      result(true)
    case "isEnabled":
      result(SMAppService.mainApp.status == .enabled)
    case "setEnabled":
      guard let enabled = call.arguments as? Bool else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "setEnabled expects a Bool argument",
            details: nil
          ))
        return
      }
      do {
        if enabled {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "launch_at_login_failed",
            message: error.localizedDescription,
            details: nil
          ))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

import Cocoa
import FlutterMacOS
import ApplicationServices
import SelectedTextKit
import desktop_multi_window
import desktop_lifecycle

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register the plugin which you want access from other isolate.
      // DesktopLifecyclePlugin.register(with: controller.registrar(forPlugin: "DesktopLifecyclePlugin"))
      DesktopLifecyclePlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
      // DesktopLifecyclePlugin.register(with: controller.registrar(forPlugin: "FlutterMultiWindowPlugin"))
    }

    // Set up method channel to fetch selected text from any app via macOS Accessibility API
    let channel = FlutterMethodChannel(name: "global_text_selection",
                                       binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getSelectedText":
        Task {
          let selectionData = await self?.getSelectedTextFromFocusedElement()
          result(selectionData)
        }
      case "ensureAccessibilityPermission":
        let granted = self?.ensureAccessibilityPermission() ?? false
        result(granted)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  // Prompt for Accessibility permission and return current trust state
  private func ensureAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  // Try to get selected text from the currently focused UI element across apps
  private func getSelectedTextFromFocusedElement() async -> [String: Any]? {
    // Ensure we have Accessibility permission
    let isTrusted = AXIsProcessTrusted()
    if !isTrusted {
      // Return nil to let Dart side prompt the user as needed
      return nil
    }

    do {
      // Use SelectedTextKit to get selected text with multiple fallback methods
      let selectedText = try await SelectedTextManager.shared.getSelectedText()
      
      // Get current mouse position
      let mouseLocation = NSEvent.mouseLocation
      let screenFrame = NSScreen.main?.frame ?? NSRect.zero
      
      // Convert mouse position to screen coordinates (flip Y-axis for macOS coordinate system)
      let cursorX = mouseLocation.x
      let cursorY = screenFrame.height - mouseLocation.y
      
      return [
        "text": selectedText ?? "",
        "cursorX": cursorX,
        "cursorY": cursorY
      ]
    } catch {
      // Log error and return nil if SelectedTextKit fails
      print("SelectedTextKit error: \(error)")
      return nil
    }
  }
}

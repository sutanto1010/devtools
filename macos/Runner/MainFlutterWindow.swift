import Cocoa
import FlutterMacOS
import ApplicationServices
import SelectedTextKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Set up method channel to fetch selected text from any app via macOS Accessibility API
    let channel = FlutterMethodChannel(name: "global_text_selection",
                                       binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getSelectedText":
        Task {
          let selectedText = await self?.getSelectedTextFromFocusedElement()
          result(selectedText)
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
  private func getSelectedTextFromFocusedElement() async -> String? {
    // Ensure we have Accessibility permission
    let isTrusted = AXIsProcessTrusted()
    if !isTrusted {
      // Return nil to let Dart side prompt the user as needed
      return nil
    }

    do {
      // Use SelectedTextKit to get selected text with multiple fallback methods
      return try await SelectedTextManager.shared.getSelectedText()
    } catch {
      // Log error and return nil if SelectedTextKit fails
      print("SelectedTextKit error: \(error)")
      return nil
    }
  }
}

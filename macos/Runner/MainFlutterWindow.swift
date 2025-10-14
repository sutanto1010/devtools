import Cocoa
import FlutterMacOS
import ApplicationServices

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
        result(self?.getSelectedTextFromFocusedElement())
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
  private func getSelectedTextFromFocusedElement() -> String? {
    // Ensure we have Accessibility permission
    let isTrusted = AXIsProcessTrusted()
    if !isTrusted {
      // Return nil to let Dart side prompt the user as needed
      return nil
    }

    let systemWide = AXUIElementCreateSystemWide()
    var focused: AnyObject?
    let focusedStatus = AXUIElementCopyAttributeValue(systemWide,
                                                      kAXFocusedUIElementAttribute as CFString,
                                                      &focused)
    guard focusedStatus == .success, let focusedElement = focused else {
      return nil
    } 
    
    // Cast to AXUIElement for use in subsequent calls
    let axElement = focusedElement as! AXUIElement

    // First, try direct selected text attribute
    var selectedText: AnyObject?
    let selTextStatus = AXUIElementCopyAttributeValue(axElement,
                                                      kAXSelectedTextAttribute as CFString,
                                                      &selectedText)
    if selTextStatus == .success, let text = selectedText as? String, !text.isEmpty {
      return text
    }

    // Fallback: read full value and slice by selected text range
    var valueObj: AnyObject?
    let valueStatus = AXUIElementCopyAttributeValue(axElement,
                                                    kAXValueAttribute as CFString,
                                                    &valueObj)
    guard valueStatus == .success, let fullText = valueObj as? String else {
      return nil
    }

    var rangeObj: AnyObject?
    let rangeStatus = AXUIElementCopyAttributeValue(axElement,
                                                    kAXSelectedTextRangeAttribute as CFString,
                                                    &rangeObj)
    if rangeStatus == .success {
      let axRange = rangeObj as! AXValue
      var cfRange = CFRange(location: 0, length: 0)
      if AXValueGetValue(axRange, .cfRange, &cfRange), cfRange.length > 0 {
        let nsText = fullText as NSString
        let start = cfRange.location
        let length = cfRange.length
        if start >= 0 && length > 0 && start + length <= nsText.length {
          return nsText.substring(with: NSRange(location: start, length: length))
        }
      }
    }

    return nil
  }
}

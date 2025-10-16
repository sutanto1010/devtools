import Cocoa
import FlutterMacOS
import ApplicationServices
import SelectedTextKit
import desktop_multi_window
import desktop_lifecycle
import hotkey_manager_macos
import clipboard_watcher
import desktop_multi_window
import device_info_plus
import file_picker
import irondash_engine_context
import openpgp
import package_info_plus
import path_provider_foundation
import screen_capturer_macos
import screen_retriever_macos
import shared_preferences_foundation
import sqflite_darwin
import super_native_extensions
import tray_manager
import url_launcher_macos
import webview_flutter_wkwebview
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
        ClipboardWatcherPlugin.register(with: controller.registrar(forPlugin: "ClipboardWatcherPlugin"))
        DesktopLifecyclePlugin.register(with: controller.registrar(forPlugin: "DesktopLifecyclePlugin"))
        FlutterMultiWindowPlugin.register(with: controller.registrar(forPlugin: "FlutterMultiWindowPlugin"))
        DeviceInfoPlusMacosPlugin.register(with: controller.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
        FilePickerPlugin.register(with: controller.registrar(forPlugin: "FilePickerPlugin"))
        HotkeyManagerMacosPlugin.register(with: controller.registrar(forPlugin: "HotkeyManagerMacosPlugin"))
        IrondashEngineContextPlugin.register(with: controller.registrar(forPlugin: "IrondashEngineContextPlugin"))
        OpenpgpPlugin.register(with: controller.registrar(forPlugin: "OpenpgpPlugin"))
        FPPPackageInfoPlusPlugin.register(with: controller.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
        PathProviderPlugin.register(with: controller.registrar(forPlugin: "PathProviderPlugin"))
        ScreenCapturerMacosPlugin.register(with: controller.registrar(forPlugin: "ScreenCapturerMacosPlugin"))
        ScreenRetrieverMacosPlugin.register(with: controller.registrar(forPlugin: "ScreenRetrieverMacosPlugin"))
        SharedPreferencesPlugin.register(with: controller.registrar(forPlugin: "SharedPreferencesPlugin"))
        SqflitePlugin.register(with: controller.registrar(forPlugin: "SqflitePlugin"))
        SuperNativeExtensionsPlugin.register(with: controller.registrar(forPlugin: "SuperNativeExtensionsPlugin"))
        TrayManagerPlugin.register(with: controller.registrar(forPlugin: "TrayManagerPlugin"))
        UrlLauncherPlugin.register(with: controller.registrar(forPlugin: "UrlLauncherPlugin"))
        WebViewFlutterPlugin.register(with: controller.registrar(forPlugin: "WebViewFlutterPlugin"))
        // WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
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

//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import file_picker
import openpgp
import path_provider_foundation
import shared_preferences_foundation
import sqflite_darwin
import tray_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  OpenpgpPlugin.register(with: registry.registrar(forPlugin: "OpenpgpPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  TrayManagerPlugin.register(with: registry.registrar(forPlugin: "TrayManagerPlugin"))
}

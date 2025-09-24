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
import system_tray

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  OpenpgpPlugin.register(with: registry.registrar(forPlugin: "OpenpgpPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  SystemTrayPlugin.register(with: registry.registrar(forPlugin: "SystemTrayPlugin"))
}

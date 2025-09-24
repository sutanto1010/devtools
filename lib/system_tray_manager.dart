import 'package:system_tray/system_tray.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  final SystemTray _systemTray = SystemTray();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Function(String toolId)? onToolSelected;

  Future<void> initSystemTray() async {
    // Initialize system tray
    await _systemTray.initSystemTray(
      title: "Dev Tools",
      iconPath: "assets/devtools-icon.ico", // You'll need to add this icon
    );

    // Set up the context menu
    await _updateTrayMenu();

    // Register tray event
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        _updateTrayMenu();
      }
    });
  }

  Future<void> _updateTrayMenu() async {
    final recentTools = await _dbHelper.getRecentTools(limit: 5);
    
    final Menu menu = Menu();
    
    if (recentTools.isNotEmpty) {
      // Add recent tools section
      await menu.buildFrom([
        MenuItemLabel(label: 'Recent Tools', enabled: false),
        MenuSeparator(),
        ...recentTools.map((tool) => MenuItemLabel(
          label: tool['title'],
          onClicked: (menuItem) => _handleToolSelection(tool['id']),
        )),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Show App',
          onClicked: (menuItem) => _showMainWindow(),
        ),
        MenuItemLabel(
          label: 'Exit',
          onClicked: (menuItem) => _exitApp(),
        ),
      ]);
    } else {
      // No recent tools available
      await menu.buildFrom([
        MenuItemLabel(label: 'No recent tools', enabled: false),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Show App',
          onClicked: (menuItem) => _showMainWindow(),
        ),
        MenuItemLabel(
          label: 'Exit',
          onClicked: (menuItem) => _exitApp(),
        ),
      ]);
    }

    await _systemTray.setContextMenu(menu);
  }

  void _handleToolSelection(String toolId) {
    if (onToolSelected != null) {
      onToolSelected!(toolId);
    }
    _showMainWindow();
  }

  void _showMainWindow() {
    // This will be handled in main.dart to show the window
    // You might need to use window_manager package for better window control
  }

  void _exitApp() {
    // Exit the application
    // You might want to add proper cleanup here
  }

  Future<void> updateRecentTools() async {
    await _updateTrayMenu();
  }

  void dispose() {
    _systemTray.destroy();
  }
}
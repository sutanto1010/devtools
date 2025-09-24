import 'package:system_tray/system_tray.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:io' show Platform;

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  final SystemTray _systemTray = SystemTray();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Function(String toolId)? onToolSelected;

  Future<void> initSystemTray() async {
    try {
      // Use platform-appropriate icon
      String iconPath;
      if (Platform.isMacOS) {
        iconPath = "assets/devtools-icon.png";
      } else {
        iconPath = "assets/devtools-icon.ico";
      }
      
      print('Initializing system tray with icon: $iconPath');
      
      // Initialize system tray
      await _systemTray.initSystemTray(
        title: "Dev Tools",
        iconPath: iconPath,
      );
      
      print('System tray initialized successfully');

      // Set up the context menu
      await _updateTrayMenu();
      print('System tray menu updated');

      // Register tray event
      _systemTray.registerSystemTrayEventHandler((eventName) {
        print('System tray event: $eventName');
        if (eventName == kSystemTrayEventClick) {
          _updateTrayMenu();
        } else if (eventName == kSystemTrayEventRightClick) {
          // Force menu update on right click
          _updateTrayMenu();
        }
      });
      
      print('System tray event handler registered');
    } catch (e) {
      print('Error initializing system tray: $e');
      // You might want to show a dialog or notification to the user
    }
  }

  Future<void> _updateTrayMenu() async {
    try {
      print('Updating tray menu...');
      final recentTools = await _dbHelper.getRecentTools(limit: 5);
      print('Recent tools count: ${recentTools.length}');
      
      final Menu menu = Menu();
      
      if (recentTools.isNotEmpty) {
        // Add recent tools section
        await menu.buildFrom([
          MenuItemLabel(label: 'Recent Tools', enabled: false),
          MenuSeparator(),
          ...recentTools.map((tool) => MenuItemLabel(
            label: tool['title'],
            onClicked: (menuItem) {
              print('Tool selected: ${tool['id']}');
              _handleToolSelection(tool['id']);
            },
          )),
          MenuSeparator(),
          MenuItemLabel(
            label: 'Show App',
            onClicked: (menuItem) {
              print('Show App clicked');
              _showMainWindow();
            },
          ),
          MenuItemLabel(
            label: 'Exit',
            onClicked: (menuItem) {
              print('Exit clicked');
              _exitApp();
            },
          ),
        ]);
      } else {
        // No recent tools available
        await menu.buildFrom([
          MenuItemLabel(label: 'No recent tools', enabled: false),
          MenuSeparator(),
          MenuItemLabel(
            label: 'Show App',
            onClicked: (menuItem) {
              print('Show App clicked');
              _showMainWindow();
            },
          ),
          MenuItemLabel(
            label: 'Exit',
            onClicked: (menuItem) {
              print('Exit clicked');
              _exitApp();
            },
          ),
        ]);
      }

      await _systemTray.setContextMenu(menu);
      print('Context menu set successfully');
    } catch (e) {
      print('Error updating tray menu: $e');
    }
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
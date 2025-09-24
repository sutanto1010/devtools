import 'package:tray_manager/tray_manager.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:io' show Platform;

class SystemTrayManager with TrayListener {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();
  Function()? onExitApp;
  Function()? onShowApp;
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
      
      // Add tray listener
      trayManager.addListener(this);
      
      // Initialize system tray
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('Dev Tools');
      
      print('System tray initialized successfully');

      // Set up the context menu
      await _updateTrayMenu();
      print('System tray menu updated');
      
      print('System tray event handler registered');
    } catch (e) {
      print('Error initializing system tray: $e');
      // You might want to show a dialog or notification to the user
    }
  }

  @override
  void onTrayIconMouseDown() async {
    print('System tray event: onTrayIconMouseDown');
    await _updateTrayMenu();
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() async {
    print('System tray event: onTrayIconRightMouseDown');
    // Force menu update on right click
    await _updateTrayMenu();
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    print('Menu item clicked: ${menuItem.key}');
    
    if (menuItem.key == 'show_app') {
      print('Show App clicked');
      _showMainWindow();
    } else if (menuItem.key == 'exit') {
      print('Exit clicked');
      _exitApp();
    } else if (menuItem.key?.startsWith('tool_') == true) {
      final toolId = menuItem.key!.substring(5); // Remove 'tool_' prefix
      print('Tool selected: $toolId');
      _handleToolSelection(toolId);
    }
  }

  Future<void> _updateTrayMenu() async {
    try {
      print('Updating tray menu...');
      final recentTools = await _dbHelper.getRecentTools(limit: 5);
      print('Recent tools count: ${recentTools.length}');
      
      List<MenuItem> menuItems = [];
      
      if (recentTools.isNotEmpty) {
        // Add recent tools section
        menuItems.add(MenuItem(
          key: 'recent_tools_header',
          label: 'Recent Tools',
          disabled: true,
        ));
        menuItems.add(MenuItem.separator());
        
        // Add recent tools
        for (var tool in recentTools) {
          menuItems.add(MenuItem(
            key: 'tool_${tool['id']}',
            label: tool['title'],
          ));
        }
        
        menuItems.add(MenuItem.separator());
      } else {
        // No recent tools available
        menuItems.add(MenuItem(
          key: 'no_recent_tools',
          label: 'No recent tools',
          disabled: true,
        ));
        menuItems.add(MenuItem.separator());
      }
      
      // Add common menu items
      menuItems.add(MenuItem(
        key: 'show_app',
        label: 'Show App',
      ));
      menuItems.add(MenuItem(
        key: 'exit',
        label: 'Exit',
      ));

      Menu menu = Menu(items: menuItems);
      await trayManager.setContextMenu(menu);
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
    onShowApp?.call();
  }

  void _exitApp() {
    // Perform cleanup before exiting
    dispose();
    
    // Exit the application
    onExitApp?.call();
  }

  Future<void> updateRecentTools() async {
    await _updateTrayMenu();
  }

  void dispose() {
    trayManager.removeListener(this);
    trayManager.destroy();
  }
}
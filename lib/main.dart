import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:devtools/services/global_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart'; // Add this import
import 'pages/home_page.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/htmlbars.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/highlight_core.dart' show highlight;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  if (args.isEmpty) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
    final appDocDirectory = await getApplicationDocumentsDirectory();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Dev Tools',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await configureNetworkTools(appDocDirectory.path, enableDebugging: true);
    highlight.registerLanguage('json', json);
    highlight.registerLanguage('htmlbars', htmlbars);
    highlight.registerLanguage('javascript', javascript);
    highlight.registerLanguage('xml', xml);
    highlight.registerLanguage('yaml', yaml);
    highlight.registerLanguage('go', go);

    // ⌥ + Q
    HotKey _hotKey = HotKey(
      key: PhysicalKeyboardKey.keyQ,
      modifiers: [HotKeyModifier.alt],
      // Set hotkey scope (default is HotKeyScope.system)
      scope: HotKeyScope.system, // Set as inapp-wide hotkey.
    );
    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        print('onKeyDown+${hotKey.toJson()}');
        final hasPermission =
            await GlobalSelectionService.ensureAccessibilityPermission();
        if (!hasPermission) {
          print('Accessibility permission not granted');
          return;
        }
        final selectedText = await GlobalSelectionService.getSelectedText();
        print('selectedText: $selectedText');

        final window = await DesktopMultiWindow.createWindow(
          jsonEncode({
            'args1': 'Sub window',
            'args2': 100,
            'args3': true,
            'business': 'business_test',
          }),
        );
        window
          ..setFrame(const Offset(0, 0) & const Size(1280, 720))
          ..center()
          ..setTitle('Another window')
          ..show();
      },
      // Only works on macOS.
      keyUpHandler: (hotKey) {
        print('onKeyUp+${hotKey.toJson()}');
      },
    );
  }
  if (args.isNotEmpty) {
    runApp(const QuickApp());
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget with WindowListener {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}

class QuickApp extends StatelessWidget {
  const QuickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quick App')
          ),
        ),
    );
  }
}

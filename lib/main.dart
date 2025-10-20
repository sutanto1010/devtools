import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:devtools/balloon_tip_painter.dart';
import 'package:devtools/quick_app.dart';
import 'package:devtools/services/global_selection.dart';
import 'package:devtools/services/pub_sub_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:multi_window_native/multi_window_native.dart';

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


WindowController? quickWindowCtrl;
int quickWindowId = -1;
@pragma('vm:entry-point')
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  print('args: $args Length: ${args.length}');
   await windowManager.ensureInitialized();
  final isMainWindow = args.length == 0;
  // Initialize window manager
  if (isMainWindow) {
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
        final data = await GlobalSelectionService.getSelectedTextWithCursor();
        print('selectedData text: ${data?.text} cursorX: ${data?.cursorX} cursorY: ${data?.cursorY}');
        // windowManager.hide();
        // quickWindowCtrl ??= await DesktopMultiWindow.createWindow(
        //     jsonEncode({
        //       'args1': 'Sub window',
        //     }),
        //   );
        //  await DesktopMultiWindow.invokeMethod(1, "quickWindow",[data?.text,data?.cursorX,data?.cursorY]);
          // await quickWindowCtrl!.setFrame(const Offset(-99999, -99999) & const Size(800, 800));
          // await quickWindowCtrl!.center();
          // // ..setTitle('Another window')
          // await quickWindowCtrl!.show();
          // await DesktopMultiWindow.invokeMethod(1, "quickWindow",[data?.text,data?.cursorX,data?.cursorY]);
          final windowCount = await MultiWindowNative.windowCount();
          if(windowCount == 0) {
             await MultiWindowNative.createWindow([
                'secondScreen', 
                '{}',    
                "foo"
              ]);
          }else{
            await MultiWindowNative.notifyAllWindows("quickWindow",[data?.text,data?.cursorX,data?.cursorY]);
          }
      },
    );
  }else{
     WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Quick App',
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // await windowManager.show();
      // await windowManager.focus();
    });
  }
  int windowId = await windowManager.getId();
  if(!isMainWindow) {
    quickWindowId = windowId;
  }
  MultiWindowNative.init(windowId);
  runApp(MyApp(args: args,));
}

AppLifecycleListener? _appLifecycleListener;

class MyApp extends StatelessWidget with WindowListener {
  final List<String> args;
  const MyApp({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    if(args.isNotEmpty) {
      return const QuickApp();
    }
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

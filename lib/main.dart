
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';  // Add this import
import 'pages/home_page.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/htmlbars.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/highlight_core.dart' show highlight;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
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
  final appDocDirectory = await getApplicationDocumentsDirectory();
  await configureNetworkTools(appDocDirectory.path, enableDebugging: true);
  highlight.registerLanguage('json', json);
  highlight.registerLanguage('htmlbars', htmlbars);
  highlight.registerLanguage('javascript', javascript);
  runApp(const MyApp());
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
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
  print('args: $args Length: ${args.length}');
  final isMainWindow = args.length == 0;
  // Initialize window manager
  if (isMainWindow) {
    await windowManager.ensureInitialized();
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
          // ..setTitle('Another window')
          ..show();
      },
      // Only works on macOS.
      keyUpHandler: (hotKey) {
        print('onKeyUp+${hotKey.toJson()}');
      },
    );
  }
  if (!isMainWindow) {
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

class BalloonTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double cornerRadius = 12.0;
    const double arrowWidth = 16.0;
    const double arrowHeight = 10.0;
    
    // Calculate arrow position (bottom center)
    final double arrowX = size.width / 2;
    final double arrowY = size.height - arrowHeight;

    // Create the balloon path
    final path = Path();
    
    // Start from top-left corner
    path.moveTo(cornerRadius, 0);
    
    // Top edge
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Right edge
    path.lineTo(size.width, arrowY - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, arrowY),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Bottom edge to arrow start
    path.lineTo(arrowX + arrowWidth / 2, arrowY);
    
    // Arrow tip
    path.lineTo(arrowX, size.height);
    path.lineTo(arrowX - arrowWidth / 2, arrowY);
    
    // Continue bottom edge
    path.lineTo(cornerRadius, arrowY);
    path.arcToPoint(
      Offset(0, arrowY - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Left edge
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );
    
    path.close();

    // Draw shadow (offset slightly)
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw main balloon
    canvas.drawPath(path, paint);
    
    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: CustomPaint(
              painter: BalloonTipPainter(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 400,
                  minHeight: 100,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Quick App',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your quick development tools',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

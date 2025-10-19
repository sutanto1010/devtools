import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:devtools/balloon_tip_painter.dart';
import 'package:devtools/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:window_manager/window_manager.dart';

class QuickApp extends StatefulWidget {
  static QuickApp? _instance = QuickApp();
  static QuickApp Instance() {
    _instance ??= QuickApp();
    return _instance!;
  }
  const QuickApp({super.key});

  @override
  State<QuickApp> createState() => _QuickAppState();
}


class _QuickAppState extends State<QuickApp> {
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Schedule the height measurement after the widget is built and displayed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _measureWidgetHeight();
      DesktopMultiWindow.setMethodHandler(multiWindowHandler);
    });
  }

  Future<Size> _measureWidgetHeight() async {
    final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
     return renderBox.size;
    }
    return Size.zero;
  }

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
            key: _containerKey,
            margin: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
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
                // Close button positioned at top-left
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () async {
                      // Close the quick window
                      // DesktopMultiWindow.invokeMethod(1, 'closeQuickWindow');
                      await windowManager.hide();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future multiWindowHandler(MethodCall call, int fromWindowId) async {
    final text = call.arguments[0] as String;
    final cursorX = call.arguments[1] as double;
    final cursorY = call.arguments[2] as double;

    print('multiWindowHandler: ${call.method} text: $text cursorX: $cursorX cursorY: $cursorY');
    final size = await _measureWidgetHeight();
    await windowManager.setSize(size, animate: false);
    final x = cursorX - size.width / 2;
    final y = cursorY-size.height;
    await windowManager.setSize(size, animate: false);
    await windowManager.setPosition(Offset(x, y), animate: false);
  }
}
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:devtools/balloon_tip_painter.dart';
import 'package:devtools/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:window_manager/window_manager.dart';

class QuickApp extends StatefulWidget {
  const QuickApp({super.key});

  @override
  State<QuickApp> createState() => _QuickAppState();
}


class _QuickAppState extends State<QuickApp> {
  final GlobalKey _containerKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  String selectedText = '';
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
      color: Colors.transparent,
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    painter: BalloonTipPainter(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedText,
                          ),
                          const Text(
                            'Quick App',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          MaterialButton(
                            onPressed: () async {
                             setState(() {
                               selectedText = "Hello random text"+DateTime.now().toString();
                             });
                            },
                            child: const Text('Close'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _textController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Enter text',
                              border: OutlineInputBorder(),
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
    await windowManager.focus();
    setState(() {
      selectedText = text;
    });
  }
}
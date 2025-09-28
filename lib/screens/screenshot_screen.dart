import 'package:devtools/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'dart:io';
import 'dart:typed_data';

class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key, this.toolParam});

  final String? toolParam;

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  Uint8List? _imageData;
  bool _isCapturing = false;
  final captureModes = <String, CaptureMode>{
    'region': CaptureMode.region,
    'window': CaptureMode.window,
    'desktop': CaptureMode.screen,
  };
  final GlobalKey<ProImageEditorState> _imageEditorKey = GlobalKey<ProImageEditorState>();

  @override
  void initState() {
    super.initState();
    // Schedule the post-render callback
    WidgetsBinding.instance.addPostFrameCallback( (_) async{
      await _onUIRendered();
      // print('ScreenshotScreen initState');
    });
  }

  // Method that gets called after UI is completely rendered
  Future<void> _onUIRendered() async {
    if(widget.toolParam != null){
      await _takeScreenshot(mode: captureModes[widget.toolParam!] ?? CaptureMode.region);
      await HomePage.showAndFocusWindow();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

    Future<void> _loadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        Uint8List? imageData;
        
        // For web platforms, use bytes directly
        if (result.files.single.bytes != null) {
          imageData = result.files.single.bytes!;
        } 
        // For desktop platforms, read from file path
        else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          if (await file.exists()) {
            imageData = await file.readAsBytes();
          }
        }
        
        if (imageData != null) {
          setState(() {
            _imageData = imageData;
          });
          _showSnackBar('Image loaded successfully!');
        } else {
          _showSnackBar('Failed to load image data');
        }
      }
    } catch (e) {
      _showSnackBar('Error loading image: $e');
    }
  }

  Future<void> _takeScreenshot({CaptureMode mode = CaptureMode.region}) async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      // Create a temporary directory for the screenshot
      final directory = await getTemporaryDirectory();
      final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/$fileName';

      // Capture screenshot using screen_capturer
      CapturedData? capturedData = await screenCapturer.capture(
        mode: mode,
        imagePath: imagePath,
        copyToClipboard: false,
      );

      if (capturedData != null && capturedData.imagePath != null) {
        // Read the captured image file
        final file = File(capturedData.imagePath!);
        if (await file.exists()) {
          final imageData = await file.readAsBytes();
          setState(() {
            _imageData = imageData;
          });
          
          // Clean up temporary file
          await file.delete();
        }
      } else {
        _showSnackBar('Screenshot capture was cancelled or failed');
      }
    } catch (e) {
      _showSnackBar('Error taking screenshot: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _captureFullScreen() async {
    await _takeScreenshot(mode: CaptureMode.screen);
  }

  Future<void> _captureWindow() async {
    await _takeScreenshot(mode: CaptureMode.window);
  }

  Future<void> _captureRegion() async {
    await _takeScreenshot(mode: CaptureMode.region);
  }


  void _showEditCompleteDialog(Uint8List editedImageData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Edited Successfully'),
        content: const Text('What would you like to do with the edited image?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Continue Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(editedImageData);
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveImage(editedImageData);
            },
            child: const Text('Save Image'),
          ),
        ],
      ),
    );
  }

    Future<void> _saveImage([Uint8List? imageData]) async {
    final editorState = _imageEditorKey.currentState;
    var dataToSave = (await editorState?.captureEditorImage()) ?? _imageData;

    try {
      // First, let user pick a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose folder to save screenshot',
      );

      if (selectedDirectory != null) {
        // Show dialog to get filename from user
        String? fileName = await _showFileNameDialog();
        
        if (fileName != null && fileName.isNotEmpty) {
          // Ensure .png extension
          if (!fileName.toLowerCase().endsWith('.png')) {
            fileName += '.png';
          }
          
          final file = File('$selectedDirectory/$fileName');
          await file.writeAsBytes(dataToSave!);
          _showSnackBar('Image saved to: ${file.path}');
        } else {
          _showSnackBar('Save cancelled - no filename provided');
        }
      } else {
        _showSnackBar('Save cancelled - no folder selected');
      }
    } catch (e) {
      _showSnackBar('Error saving image: $e');
    }
  }

  Future<String?> _showFileNameDialog() async {
    final TextEditingController controller = TextEditingController(
      text: 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Screenshot'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'File name',
              hintText: 'Enter filename (with or without .png)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyToClipboard([Uint8List? imageData]) async {
    final editorState = _imageEditorKey.currentState;
    _imageData = (await editorState?.captureEditorImage());
  
    try {
      // Use super_clipboard to copy binary image data
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem();
        item.add(Formats.png(_imageData!));
        await clipboard.write([item]);
        _showSnackBar('Image copied to clipboard!');
      } else {
        _showSnackBar('Clipboard not available');
      }
    } catch (e) {
      _showSnackBar('Error copying to clipboard: $e');
      print('Clipboard error details: $e'); // Debug info
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_imageData != null) ...[
            IconButton(
              onPressed: () => _copyToClipboard(),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy to clipboard',
            ),
            IconButton(
              onPressed: () => _saveImage(),
              icon: const Icon(Icons.save),
              tooltip: 'Save image',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Action buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isCapturing ? null : _captureRegion,
                      icon: _isCapturing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.crop_free),
                      label: const Text('Capture Region'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isCapturing ? null : _captureFullScreen,
                      icon: _isCapturing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fullscreen),
                      label: const Text('Full Screen'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isCapturing ? null : _captureWindow,
                      icon: _isCapturing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.web_asset),
                      label: const Text('Capture Window'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Load Image'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image display area
          Expanded(
            child: _imageData != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: ProImageEditor.memory(
                          _imageData!,
                          key: _imageEditorKey,
                          configs: ProImageEditorConfigs(
                            designMode: ImageEditorDesignMode.material,
                            theme: ThemeData.light(),
                            heroTag: "screenshot_editor",
                            mainEditor: MainEditorConfigs(
                              enableZoom: true,
                              enableCloseButton: false
                            ),
                            paintEditor: PaintEditorConfigs(
                              enabled: true,
                              enableModeBlur: true,
                              initialPaintMode: PaintMode.freeStyle,
                              enableModeFreeStyle: true,
                            ),
                            blurEditor: BlurEditorConfigs(
                            
                            ),
                          ),
                          callbacks: ProImageEditorCallbacks(
                            onImageEditingComplete: (Uint8List bytes) async {
                              // Update the image data with edited version
                              setState(() {
                                _imageData = bytes;
                              });
                              
                              // Show options for what to do with the edited image
                              _showEditCompleteDialog(bytes);
                            },
                            onImageEditingStarted: () {
                              // Optional: Show loading or perform setup
                            },
                          ),
                        ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.screenshot_monitor,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No screenshot taken yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use the buttons above to capture a screenshot or load an image',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
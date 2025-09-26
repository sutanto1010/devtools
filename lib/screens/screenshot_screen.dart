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
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  Uint8List? _imageData;
  bool _isCapturing = false;

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

      if (result != null && result.files.single.bytes != null) {
        final imageData = result.files.single.bytes!;
        setState(() {
          _imageData = imageData;
        });
        _openImageEditor();
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
          
          // Open the image editor
          _openImageEditor();
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

  void _openImageEditor() {
    if (_imageData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          _imageData!,
          configs: ProImageEditorConfigs(
            designMode: ImageEditorDesignMode.material,
            theme: ThemeData.light(),
            heroTag: "screenshot_editor",
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
      ),
    );
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
    final dataToSave = imageData ?? _imageData;
    if (dataToSave == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'edited_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(dataToSave);
      _showSnackBar('Image saved to: ${file.path}');
    } catch (e) {
      _showSnackBar('Error saving image: $e');
    }
  }

  Future<void> _copyToClipboard([Uint8List? imageData]) async {
    final dataToCopy = imageData ?? _imageData;
    if (dataToCopy == null) return;

    try {
      // Use super_clipboard to copy binary image data
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem();
        item.add(Formats.png(dataToCopy));
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
            IconButton(
              onPressed: _openImageEditor,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit image',
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
                if (_imageData != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openImageEditor,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Image display area
          Expanded(
            child: _imageData != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [ 
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _imageData!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Click "Edit Image" to add annotations, text, shapes, filters, and more!',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
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
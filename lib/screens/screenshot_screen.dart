import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

enum DrawingTool { none, line, rectangle, circle, arrow, text, crop, select }

class DrawingPoint {
  Offset point;
  final Paint paint;
  final DrawingTool tool;
  final String? text;
  Offset? endPoint;
  bool isSelected;

  DrawingPoint({
    required this.point,
    required this.paint,
    required this.tool,
    this.text,
    this.endPoint,
    this.isSelected = false,
  });

  // Create a copy of the drawing point with updated positions
  DrawingPoint copyWith({
    Offset? point,
    Offset? endPoint,
    bool? isSelected,
  }) {
    return DrawingPoint(
      point: point ?? this.point,
      paint: paint,
      tool: tool,
      text: text,
      endPoint: endPoint ?? this.endPoint,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Get the bounding box of the drawing element
  Rect getBounds() {
    switch (tool) {
      case DrawingTool.line:
      case DrawingTool.arrow:
        if (endPoint != null) {
          return Rect.fromPoints(point, endPoint!).inflate(10);
        }
        return Rect.fromCenter(center: point, width: 20, height: 20);
      case DrawingTool.rectangle:
        if (endPoint != null) {
          return Rect.fromPoints(point, endPoint!).inflate(5);
        }
        return Rect.fromCenter(center: point, width: 20, height: 20);
      case DrawingTool.circle:
        if (endPoint != null) {
          final radius = (endPoint! - point).distance;
          return Rect.fromCenter(center: point, width: (radius + 10) * 2, height: (radius + 10) * 2);
        }
        return Rect.fromCenter(center: point, width: 20, height: 20);
      case DrawingTool.text:
        if (text != null) {
          // Calculate accurate text bounds using TextPainter
          final fontSize = paint.strokeWidth * 5;
          final textPainter = TextPainter(
            text: TextSpan(
              text: text!,
              style: TextStyle(
                color: paint.color,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          // Add some padding around the text for easier selection
          const padding = 8.0;
          return Rect.fromLTWH(
            point.dx - padding,
            point.dy - padding,
            textPainter.width + (padding * 2),
            textPainter.height + (padding * 2),
          );
        }
        return Rect.fromCenter(center: point, width: 50, height: 20);
      default:
        return Rect.fromCenter(center: point, width: 20, height: 20);
    }
  }

  // Check if a point is within this drawing element
  bool containsPoint(Offset testPoint) {
    return getBounds().contains(testPoint);
  }

  // Move the drawing element by an offset
  void moveBy(Offset delta) {
    point = point + delta;
    if (endPoint != null) {
      endPoint = endPoint! + delta;
    }
  }
}

class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  Uint8List? _imageData;
  ui.Image? _decodedImage;
  List<DrawingPoint> _drawingPoints = [];
  DrawingTool _selectedTool = DrawingTool.none;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  bool _isDrawing = false;
  Offset? _startPoint;
  Offset? _endPoint;
  Rect? _cropRect;
  bool _isCropping = false;
  bool _isCapturing = false;
  
  // New variables for dragging functionality
  DrawingPoint? _selectedDrawingPoint;
  bool _isDragging = false;
  Offset? _dragStartPosition;

  @override
  void dispose() {
    _textController.dispose();
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage(Uint8List imageData) async {
    try {
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      setState(() {
        _decodedImage?.dispose();
        _decodedImage = frame.image;
      });
    } catch (e) {
      _showSnackBar('Error decoding image: $e');
    }
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
          _drawingPoints.clear();
          _cropRect = null;
        });
        await _decodeImage(imageData);
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
            _drawingPoints.clear();
            _cropRect = null;
          });
          await _decodeImage(imageData);
          
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

  Future<void> _saveImage() async {
    if (_imageData == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'edited_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      
      // Create a canvas to draw the image with annotations
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Decode and draw the original image
      final codec = await ui.instantiateImageCodec(_imageData!);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      canvas.drawImage(image, Offset.zero, Paint());
      
      // Draw all annotations
      for (final point in _drawingPoints) {
        _drawOnCanvas(canvas, point);
      }
      
      final picture = recorder.endRecording();
      final img = await picture.toImage(image.width, image.height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
        _showSnackBar('Image saved to: ${file.path}');
      }
    } catch (e) {
      _showSnackBar('Error saving image: $e');
    }
  }

  Future<void> _copyToClipboard() async {
    if (_imageData == null) return;

    try {
      // Capture the RepaintBoundary widget as an image
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      // Convert the widget to an image
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Use super_clipboard to copy binary image data
        final clipboard = SystemClipboard.instance;
        if (clipboard != null) {
          final item = DataWriterItem();
          item.add(Formats.png(byteData.buffer.asUint8List()));
          await clipboard.write([item]);
          _showSnackBar('Image with annotations copied to clipboard!');
        } else {
          _showSnackBar('Clipboard not available');
        }
      }
      
      // Clean up resources
      image.dispose();
      
    } catch (e) {
      _showSnackBar('Error copying to clipboard: $e');
      print('Clipboard error details: $e'); // Debug info
    }
  }

  void _drawOnCanvas(Canvas canvas, DrawingPoint point) {
    switch (point.tool) {
      case DrawingTool.line:
        if (point.endPoint != null) {
          canvas.drawLine(point.point, point.endPoint!, point.paint);
        }
        break;
      case DrawingTool.rectangle:
        if (point.endPoint != null) {
          final rect = Rect.fromPoints(point.point, point.endPoint!);
          canvas.drawRect(rect, point.paint);
        }
        break;
      case DrawingTool.circle:
        if (point.endPoint != null) {
          final center = point.point;
          final radius = (point.endPoint! - point.point).distance;
          canvas.drawCircle(center, radius, point.paint);
        }
        break;
      case DrawingTool.arrow:
        if (point.endPoint != null) {
          _drawArrow(canvas, point.point, point.endPoint!, point.paint);
        }
        break;
      case DrawingTool.text:
        if (point.text != null) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: point.text!,
              style: TextStyle(
                color: point.paint.color,
                fontSize: point.paint.strokeWidth * 5,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, point.point);
        }
        break;
      default:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    // Draw arrowhead
    const arrowLength = 20.0;
    const arrowAngle = 0.5;
    
    final direction = (end - start).direction;
    final arrowPoint1 = end + Offset.fromDirection(direction + arrowAngle + 3.14159, arrowLength);
    final arrowPoint2 = end + Offset.fromDirection(direction - arrowAngle + 3.14159, arrowLength);
    
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    
    // If select tool is active, check for existing drawings to select/drag
    if (_selectedTool == DrawingTool.select) {
      _handleSelectStart(position);
      return;
    }
    
    // Clear any existing selections when starting to draw
    _clearSelections();
    
    if (_selectedTool == DrawingTool.none) return;
    
    setState(() {
      _isDrawing = true;
      _startPoint = position;
      
      if (_selectedTool == DrawingTool.text) {
        _showTextDialog(position);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    
    // Handle dragging selected elements
    if (_isDragging && _selectedDrawingPoint != null && _dragStartPosition != null) {
      final delta = position - _dragStartPosition!;
      setState(() {
        _selectedDrawingPoint!.moveBy(delta);
        _dragStartPosition = position;
      });
      return;
    }
    
    // Handle drawing new elements
    if (!_isDrawing || _selectedTool == DrawingTool.text || _selectedTool == DrawingTool.select) return;
    
    setState(() {
      _endPoint = position;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Handle end of dragging
    if (_isDragging) {
      setState(() {
        _isDragging = false;
        _dragStartPosition = null;
      });
      return;
    }
    
    // Handle end of drawing
    if (!_isDrawing) return;
    
    if (_startPoint != null && _endPoint != null && _selectedTool != DrawingTool.text) {
      final paint = Paint()
        ..color = _selectedColor
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke;
      
      setState(() {
        _drawingPoints.add(DrawingPoint(
          point: _startPoint!,
          endPoint: _endPoint,
          paint: paint,
          tool: _selectedTool,
        ));
      });
    }
    
    setState(() {
      _isDrawing = false;
      _startPoint = null;
      _endPoint = null;
    });
  }

  void _handleSelectStart(Offset position) {
    // Find the topmost drawing element at this position
    DrawingPoint? hitElement;
    for (int i = _drawingPoints.length - 1; i >= 0; i--) {
      if (_drawingPoints[i].containsPoint(position)) {
        hitElement = _drawingPoints[i];
        break;
      }
    }
    
    // Clear all selections first
    _clearSelections();
    
    if (hitElement != null) {
      setState(() {
        hitElement!.isSelected = true;
        _selectedDrawingPoint = hitElement;
        _isDragging = true;
        _dragStartPosition = position;
      });
    }
  }

  void _clearSelections() {
    setState(() {
      for (var point in _drawingPoints) {
        point.isSelected = false;
      }
      _selectedDrawingPoint = null;
    });
  }

  void _deleteSelectedElement() {
    if (_selectedDrawingPoint != null) {
      setState(() {
        _drawingPoints.remove(_selectedDrawingPoint);
        _selectedDrawingPoint = null;
      });
    }
  }

  void _showTextDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isDrawing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                final paint = Paint()
                  ..color = _selectedColor
                  ..strokeWidth = _strokeWidth;
                
                setState(() {
                  _drawingPoints.add(DrawingPoint(
                    point: position,
                    paint: paint,
                    tool: DrawingTool.text,
                    text: _textController.text,
                  ));
                });
                
                _textController.clear();
              }
              Navigator.pop(context);
              setState(() {
                _isDrawing = false;
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _cropImage() {
    if (_imageData == null || _cropRect == null) return;
    
    // For simplicity, we'll just show a message about cropping
    // In a real implementation, you'd use image processing libraries
    _showSnackBar('Crop functionality would be implemented with image processing');
  }

  void _clearDrawings() {
    setState(() {
      _drawingPoints.clear();
      _cropRect = null;
    });
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
          if (_selectedDrawingPoint != null)
            IconButton(
              onPressed: _deleteSelectedElement,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected element',
            ),
          IconButton(
            onPressed: _clearDrawings,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all drawings',
          ),
          IconButton(
            onPressed: _imageData != null ? _copyToClipboard : null,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
          ),
          IconButton(
            onPressed: _saveImage,
            icon: const Icon(Icons.save),
            tooltip: 'Save image',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            child: Column(
              children: [
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Load Image'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Drawing tools
                Wrap(
                  spacing: 8,
                  children: [
                    _buildToolButton(DrawingTool.select, Icons.near_me, 'Select'),
                    _buildToolButton(DrawingTool.line, Icons.remove, 'Line'),
                    _buildToolButton(DrawingTool.rectangle, Icons.crop_square, 'Rectangle'),
                    _buildToolButton(DrawingTool.circle, Icons.circle_outlined, 'Circle'),
                    _buildToolButton(DrawingTool.arrow, Icons.arrow_forward, 'Arrow'),
                    _buildToolButton(DrawingTool.text, Icons.text_fields, 'Text'),
                  ],
                ),
                const SizedBox(height: 8),
                // Color and stroke width controls
                Row(
                  children: [
                    const Text('Color: '),
                    ...Colors.primaries.take(6).map((color) => 
                      GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.grey,
                              width: _selectedColor == color ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Width: '),
                    SizedBox(
                      width: 100,
                      child: Slider(
                        value: _strokeWidth,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (value) => setState(() => _strokeWidth = value),
                      ),
                    ),
                    Text('${_strokeWidth.toInt()}'),
                  ],
                ),
              ],
            ),
          ),
          // Image display area
          Expanded(
            child: _imageData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.screenshot, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Capture a screenshot or load an image to start editing',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Capture Modes:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text('• Region: Drag to select an area'),
                                const Text('• Full Screen: Capture entire screen'),
                                const Text('• Window: Select a specific window'),
                                const SizedBox(height: 8),
                                const Text(
                                  'Drawing Tools:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text('• Select: Click and drag to move elements'),
                                const Text('• Draw shapes and add text annotations'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: ImagePainter(
                            imageData: _imageData!,
                            decodedImage: _decodedImage,
                            drawingPoints: _drawingPoints,
                            currentTool: _selectedTool,
                            startPoint: _startPoint,
                            endPoint: _endPoint,
                            currentColor: _selectedColor,
                            currentStrokeWidth: _strokeWidth,
                            isDrawing: _isDrawing,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;
    return FilterChip(
      showCheckmark: false,
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTool = selected ? tool : DrawingTool.none;
        });
      },
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class ImagePainter extends CustomPainter {
  final Uint8List imageData;
  final List<DrawingPoint> drawingPoints;
  final DrawingTool currentTool;
  final Offset? startPoint;
  final Offset? endPoint;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isDrawing;
  final ui.Image? decodedImage;

  ImagePainter({
    required this.imageData,
    required this.drawingPoints,
    required this.currentTool,
    this.startPoint,
    this.endPoint,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.isDrawing,
    this.decodedImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the background image
    _drawImage(canvas, size);
    
    // Draw all completed drawings
    for (final point in drawingPoints) {
      _drawPoint(canvas, point);
      
      // Draw selection indicator
      if (point.isSelected) {
        _drawSelectionIndicator(canvas, point);
      }
    }
    
    // Draw current drawing in progress
    if (isDrawing && startPoint != null && endPoint != null && currentTool != DrawingTool.text && currentTool != DrawingTool.select) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..style = PaintingStyle.stroke;
      
      final tempPoint = DrawingPoint(
        point: startPoint!,
        endPoint: endPoint,
        paint: paint,
        tool: currentTool,
      );
      
      _drawPoint(canvas, tempPoint);
    }
  }

  void _drawSelectionIndicator(Canvas canvas, DrawingPoint point) {
    final bounds = point.getBounds();
    final selectionPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw selection rectangle
    canvas.drawRect(bounds, selectionPaint);
    
    // Draw corner handles
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    final corners = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ];
    
    for (final corner in corners) {
      canvas.drawRect(
        Rect.fromCenter(center: corner, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  void _drawImage(Canvas canvas, Size size) {
    if (decodedImage != null) {
      // Calculate aspect ratios
      final imageAspectRatio = decodedImage!.width / decodedImage!.height;
      final canvasAspectRatio = size.width / size.height;
      
      double drawWidth, drawHeight;
      double offsetX = 0, offsetY = 0;
      
      if (imageAspectRatio > canvasAspectRatio) {
        // Image is wider than canvas
        drawWidth = size.width;
        drawHeight = size.width / imageAspectRatio;
        offsetY = (size.height - drawHeight) / 2;
      } else {
        // Image is taller than canvas
        drawHeight = size.height;
        drawWidth = size.height * imageAspectRatio;
        offsetX = (size.width - drawWidth) / 2;
      }
      
      final destRect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
      final srcRect = Rect.fromLTWH(0, 0, decodedImage!.width.toDouble(), decodedImage!.height.toDouble());
      
      canvas.drawImageRect(decodedImage!, srcRect, destRect, Paint());
    } else {
      // Show loading or placeholder
      final paint = Paint();
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(rect, paint..color = Colors.grey[200]!);
      
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Loading image...',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawPoint(Canvas canvas, DrawingPoint point) {
    switch (point.tool) {
      case DrawingTool.line:
        if (point.endPoint != null) {
          canvas.drawLine(point.point, point.endPoint!, point.paint);
        }
        break;
      case DrawingTool.rectangle:
        if (point.endPoint != null) {
          final rect = Rect.fromPoints(point.point, point.endPoint!);
          canvas.drawRect(rect, point.paint);
        }
        break;
      case DrawingTool.circle:
        if (point.endPoint != null) {
          final center = point.point;
          final radius = (point.endPoint! - point.point).distance;
          canvas.drawCircle(center, radius, point.paint);
        }
        break;
      case DrawingTool.arrow:
        if (point.endPoint != null) {
          _drawArrow(canvas, point.point, point.endPoint!, point.paint);
        }
        break;
      case DrawingTool.text:
        if (point.text != null) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: point.text!,
              style: TextStyle(
                color: point.paint.color,
                fontSize: point.paint.strokeWidth * 5,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, point.point);
        }
        break;
      default:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    // Draw arrowhead
    const arrowLength = 20.0;
    const arrowAngle = 0.5;
    
    final direction = (end - start).direction;
    final arrowPoint1 = end + Offset.fromDirection(direction + arrowAngle + 3.14159, arrowLength);
    final arrowPoint2 = end + Offset.fromDirection(direction - arrowAngle + 3.14159, arrowLength);
    
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
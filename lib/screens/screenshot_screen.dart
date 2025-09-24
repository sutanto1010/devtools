import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

enum DrawingTool { none, line, rectangle, circle, arrow, text, crop }

class DrawingPoint {
  final Offset point;
  final Paint paint;
  final DrawingTool tool;
  final String? text;
  final Offset? endPoint;

  DrawingPoint({
    required this.point,
    required this.paint,
    required this.tool,
    this.text,
    this.endPoint,
  });
}

class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();
  
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

  Future<void> _takeScreenshot() async {
    try {
      final imageData = await _screenshotController.capture();
      if (imageData != null) {
        setState(() {
          _imageData = imageData;
          _drawingPoints.clear();
          _cropRect = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error taking screenshot: $e');
    }
  }

  Future<void> _saveImage() async {
    if (_imageData == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
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
    if (_selectedTool == DrawingTool.none) return;
    
    setState(() {
      _isDrawing = true;
      _startPoint = details.localPosition;
      
      if (_selectedTool == DrawingTool.text) {
        _showTextDialog(details.localPosition);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _selectedTool == DrawingTool.text) return;
    
    setState(() {
      _endPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
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
        title: const Text('Screenshot Tool'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearDrawings,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all drawings',
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _takeScreenshot,
                      icon: const Icon(Icons.screenshot),
                      label: const Text('Take Screenshot'),
                    ),
                    const SizedBox(width: 8),
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
                    _buildToolButton(DrawingTool.line, Icons.remove, 'Line'),
                    _buildToolButton(DrawingTool.rectangle, Icons.crop_square, 'Rectangle'),
                    _buildToolButton(DrawingTool.circle, Icons.circle_outlined, 'Circle'),
                    _buildToolButton(DrawingTool.arrow, Icons.arrow_forward, 'Arrow'),
                    _buildToolButton(DrawingTool.text, Icons.text_fields, 'Text'),
                    _buildToolButton(DrawingTool.crop, Icons.crop, 'Crop'),
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.screenshot, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Take a screenshot or load an image to start editing',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
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
    }
    
    // Draw current drawing in progress
    if (isDrawing && startPoint != null && endPoint != null && currentTool != DrawingTool.text) {
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

  void _drawImage(Canvas canvas, Size size) {
    if (decodedImage != null) {
      // Calculate scaling to fit the image within the canvas while maintaining aspect ratio
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
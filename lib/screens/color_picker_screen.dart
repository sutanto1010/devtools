import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  Color _selectedColor = Colors.blue;
  String _hexColor = '#2196F3';
  String _rgbColor = 'rgb(33, 150, 243)';
  String _hslColor = 'hsl(207, 90%, 54%)';
  bool _isPickingFromScreen = false;

  @override
  void initState() {
    super.initState();
    _updateColorFormats(_selectedColor);
  }

  void _updateColorFormats(Color color) {
    setState(() {
      _selectedColor = color;
      _hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      _rgbColor = 'rgb(${color.red}, ${color.green}, ${color.blue})';
      
      // Convert to HSL
      final hsl = HSLColor.fromColor(color);
      _hslColor = 'hsl(${hsl.hue.round()}, ${(hsl.saturation * 100).round()}%, ${(hsl.lightness * 100).round()}%)';
    });
  }

  void _copyToClipboard(String text, String format) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$format copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _pickColorFromScreen() {
    setState(() {
      _isPickingFromScreen = true;
    });
    
    // Show overlay for screen color picking
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ScreenColorPicker(
            onColorPicked: (color) {
              _updateColorFormats(color);
              setState(() {
                _isPickingFromScreen = false;
              });
              Navigator.of(context).pop();
            },
            onCancel: () {
              setState(() {
                _isPickingFromScreen = false;
              });
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  Widget _buildColorPreview() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: _selectedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedColor.computeLuminance() > 0.5 
                ? Colors.black.withOpacity(0.7)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _hexColor,
            style: TextStyle(
              color: _selectedColor.computeLuminance() > 0.5 
                  ? Colors.white
                  : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorFormatCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () => _copyToClipboard(value, title),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      children: [
        // Hue slider
        SizedBox(
          height: 40,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 30,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            ),
            child: Slider(
              value: HSLColor.fromColor(_selectedColor).hue,
              min: 0,
              max: 360,
              onChanged: (value) {
                final hsl = HSLColor.fromColor(_selectedColor);
                _updateColorFormats(hsl.withHue(value).toColor());
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Saturation slider
        SizedBox(
          height: 40,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 30,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            ),
            child: Slider(
              value: HSLColor.fromColor(_selectedColor).saturation,
              min: 0,
              max: 1,
              onChanged: (value) {
                final hsl = HSLColor.fromColor(_selectedColor);
                _updateColorFormats(hsl.withSaturation(value).toColor());
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Lightness slider
        SizedBox(
          height: 40,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 30,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            ),
            child: Slider(
              value: HSLColor.fromColor(_selectedColor).lightness,
              min: 0,
              max: 1,
              onChanged: (value) {
                final hsl = HSLColor.fromColor(_selectedColor);
                _updateColorFormats(hsl.withLightness(value).toColor());
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview
            _buildColorPreview(),
            const SizedBox(height: 24),
            
            // Screen color picker button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPickingFromScreen ? null : _pickColorFromScreen,
                icon: const Icon(Icons.colorize),
                label: Text(_isPickingFromScreen ? 'Picking Color...' : 'Pick Color from Screen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Color picker sliders
            Text(
              'Adjust Color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 24),
            
            // Color formats
            Text(
              'Color Formats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildColorFormatCard('HEX', _hexColor, Icons.tag),
            _buildColorFormatCard('RGB', _rgbColor, Icons.palette),
            _buildColorFormatCard('HSL', _hslColor, Icons.tune),
            
            const SizedBox(height: 24),
            
            // Preset colors
            Text(
              'Preset Colors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.black,
              ].map((color) => GestureDetector(
                onTap: () => _updateColorFormats(color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedColor == color 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: _selectedColor == color ? 3 : 1,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenColorPicker extends StatefulWidget {
  final Function(Color) onColorPicked;
  final VoidCallback onCancel;

  const ScreenColorPicker({
    super.key,
    required this.onColorPicked,
    required this.onCancel,
  });

  @override
  State<ScreenColorPicker> createState() => _ScreenColorPickerState();
}

class _ScreenColorPickerState extends State<ScreenColorPicker> {
  Color? _hoveredColor;
  Offset? _cursorPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          // Mouse region for color picking
          MouseRegion(
            onHover: (event) {
              setState(() {
                _cursorPosition = event.position;
              });
              // In a real implementation, you would capture the screen pixel here
              // For demo purposes, we'll use a random color based on position
              final color = Color.fromRGBO(
                (event.position.dx % 255).toInt(),
                (event.position.dy % 255).toInt(),
                ((event.position.dx + event.position.dy) % 255).toInt(),
                1.0,
              );
              setState(() {
                _hoveredColor = color;
              });
            },
            child: GestureDetector(
              onTap: () {
                if (_hoveredColor != null) {
                  widget.onColorPicked(_hoveredColor!);
                }
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
          ),
          
          // Cursor indicator
          if (_cursorPosition != null && _hoveredColor != null)
            Positioned(
              left: _cursorPosition!.dx - 50,
              top: _cursorPosition!.dy - 80,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hoveredColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${_hoveredColor!.value.toRadixString(16).substring(2).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Instructions
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Click anywhere to pick a color',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
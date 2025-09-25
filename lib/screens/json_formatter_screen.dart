import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:syntax_highlight/syntax_highlight.dart';

class JsonFormatterScreen extends StatefulWidget {
  const JsonFormatterScreen({super.key});

  @override
  State<JsonFormatterScreen> createState() => _JsonFormatterScreenState();
}

class _JsonFormatterScreenState extends State<JsonFormatterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  Highlighter? _jsonHighlighter;
  bool _isHighlighterReady = false;

  @override
  void initState() {
    super.initState();
    _initializeHighlighter();
  }

  Future<void> _initializeHighlighter() async {
    try {
      await Highlighter.initialize(['json']);
      _jsonHighlighter = Highlighter(
        language: 'json',
        theme: await HighlighterTheme.loadLightTheme(),
      );
      setState(() {
        _isHighlighterReady = true;
      });
    } catch (e) {
      // Fallback if highlighter fails to initialize
      setState(() {
        _isHighlighterReady = false;
      });
    }
  }

  void _formatJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON to format';
        });
        return;
      }

      final jsonObject = jsonDecode(input);
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(jsonObject);
      
      setState(() {
        _outputController.text = formattedJson;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  void _minifyJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON to minify';
        });
        return;
      }

      final jsonObject = jsonDecode(input);
      final minifiedJson = jsonEncode(jsonObject);
      
      setState(() {
        _outputController.text = minifiedJson;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
    });
  }

  Widget _buildHighlightedTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
  }) {
    if (!_isHighlighterReady || _jsonHighlighter == null) {
      // Fallback to regular TextField if highlighter is not ready
      return TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        readOnly: readOnly,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hintText,
        ),
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    }

    return TextField(
      controller: controller,
      maxLines: null,
      expands: true,
      readOnly: readOnly,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hintText,
      ),
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      onChanged: (value) {
        setState(() {}); // Trigger rebuild for syntax highlighting
      },
    );
  }

  Widget _buildHighlightedText(String text, String hintText) {
    if (text.isEmpty) {
      return Text(
        hintText,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Colors.grey,
        ),
      );
    }

    try {
      // Validate JSON before highlighting
      jsonDecode(text);
      final highlighted = _jsonHighlighter!.highlight(text);
      return Text.rich(
        highlighted,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    } catch (e) {
      // If JSON is invalid, show plain text
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Formatter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side - Input
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Input JSON:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildHighlightedTextField(
                      controller: _inputController,
                      hintText: 'Paste your JSON here...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Center - Buttons and Error
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatJson,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _minifyJson,
                  icon: const Icon(Icons.compress),
                  label: const Text('Minify'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            // Right side - Output
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Formatted Output:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildHighlightedTextField(
                      controller: _outputController,
                      hintText: 'Formatted JSON will appear here...',
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';


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
  late HighlighterTheme _jsonTheme;
  @override
  void initState() {
    super.initState();
    _initializeHighlighter();
  }

  Future<void> _initializeHighlighter() async {
    try {
      _jsonTheme = await HighlighterTheme.loadLightTheme();
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

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _inputController.text = clipboardData.text!;
          _errorMessage = '';
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('JSON pasted from clipboard!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Clipboard is empty';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to paste from clipboard';
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

  void _copyToClipboard() async {
    final output = _outputController.text;
    if (output.isEmpty) {
      setState(() {
        _errorMessage = 'No formatted JSON to copy';
      });
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: output));
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to copy to clipboard';
      });
    }
  }

  Widget _buildHighlightedTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
    bool isInput = true,
  }) {
    Widget textField;
    
    if (!_isHighlighterReady || _jsonHighlighter == null || isInput) {
      // Fallback to regular TextField if highlighter is not ready
      textField = TextField(
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
          fontFamily: 'SF Mono, Monaco, Inconsolata, Roboto Mono, Consolas, Courier New, monospace',
          fontSize: 14,
        ),
      );
    } else {
      final codeController = CodeController(
        text: controller.text,
        language: json,
      );
      textField = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: SingleChildScrollView(
                    child: CodeTheme(
                      data: CodeThemeData(styles: githubTheme),
                      child: CodeField(controller: codeController),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Wrap in Stack to add overlay buttons
    return Stack(
      children: [
        textField,
        // Overlay buttons in top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInput) ...[
                // Paste button for input field
                Tooltip(
                  message: 'Paste from clipboard',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.paste, size: 16),
                      iconSize: 16,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Copy button for output field
                Tooltip(
                  message: 'Copy to clipboard',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, size: 16),
                      iconSize: 16,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String hintText) {
    if (text.isEmpty) {
      return Text(
        hintText,
        style: const TextStyle(
          fontFamily: 'SF Mono, Monaco, Inconsolata, Roboto Mono, Consolas, Courier New, monospace',
          fontSize: 14,
          color: Colors.grey,
        ),
      );
    }

    try {
      // Validate JSON before highlighting
      jsonDecode(text);
      final highlighted = _jsonHighlighter!.highlight(text);
      return SelectableText.rich(
        highlighted,
        style: const TextStyle(
          fontFamily: 'SF Mono, Monaco, Inconsolata, Roboto Mono, Consolas, Courier New, monospace',
          fontSize: 14,
        ),
      );
    } catch (e) {
      // If JSON is invalid, show plain text
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'SF Mono, Monaco, Inconsolata, Roboto Mono, Consolas, Courier New, monospace',
          fontSize: 14,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top - Input
            Expanded(
              flex: 2,
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
                      isInput: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Center - Buttons and Error
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatJson,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _minifyJson,
                  icon: const Icon(Icons.compress),
                  label: const Text('Minify'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
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
            const SizedBox(height: 16),
            // Bottom - Output
            Expanded(
              flex: 2,
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
                      isInput: false,
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
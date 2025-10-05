import 'package:devtools/services/pub_sub_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';
import 'package:flutter_highlight/themes/github.dart';


class JsonFormatterScreen extends StatefulWidget {
  JsonFormatterScreen({super.key});
  @override
  State<JsonFormatterScreen> createState() => _JsonFormatterScreenState();
}

class _JsonFormatterScreenState extends State<JsonFormatterScreen> {
  // final PubSubService _pubSub = PubSubService();
  String _errorMessage = '';
  bool _isFullscreenOutput = false;
  bool _isFullscreenInput = false;
  
  final CodeController _inputCodeController = CodeController(
    text: '',
    language: json,
  );
  final CodeController _outputCodeController = CodeController(
    text: '',
    language: json,
  );

  @override
  void initState() {
    super.initState();
    // _pubSub.subscribe<int>('on_tab_closed').listen((event) {
    //   setState(() {
    //     _errorMessage = _errorMessage;
    //     _isFullscreenOutput = _isFullscreenOutput;
    //     _isFullscreenInput = _isFullscreenInput;
    //   });
    // });
  }
  void _toggleFullscreen(bool isInput) {
    setState(() {
      if (isInput) {
        _isFullscreenInput = !_isFullscreenInput;
      } else {
        _isFullscreenOutput = !_isFullscreenOutput;
      }
    });
  }


  void _formatJson() {
    setState(() {
      _errorMessage = '';
      _outputCodeController.clear();
    });

    try {
      final input = _inputCodeController.text.trim();
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
        _outputCodeController.text = formattedJson;
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
      _outputCodeController.clear();
    });

    try {
      final input = _inputCodeController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON to minify';
        });
        return;
      }

      final jsonObject = jsonDecode(input);
      final minifiedJson = jsonEncode(jsonObject);
      
      setState(() {
        _outputCodeController.text = minifiedJson;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }
  bool get _isFullScreen => _isFullscreenInput || _isFullscreenOutput;
  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _inputCodeController.text = clipboardData.text!;
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
      _inputCodeController.clear();
      _outputCodeController.clear();
      _errorMessage = '';
    });
  }

  void _copyToClipboard() async {
    final output = _outputCodeController.text;
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
    required String hintText,
    bool readOnly = false,
    bool isInput = true,
  }) {
      var textField = Container(
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
                      child: CodeField(controller: isInput ? _inputCodeController : _outputCodeController, key: UniqueKey(),),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

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
              IconButton(
                onPressed: () => _toggleFullscreen(isInput),
                icon: _isFullScreen ? const Icon(Icons.fullscreen_exit, size: 16) : const Icon(Icons.fullscreen, size: 16),
                iconSize: 16,
                padding: const EdgeInsets.all(4),
                tooltip: _isFullScreen ?  'Exit full window' : 'Full window',
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
              if (isInput) ...[
                // Paste button for input field
                IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste, size: 16),
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Paste from clipboard',
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ] else ...[
                // Copy button for output field
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 16),
                  iconSize: 16,
                  tooltip: 'Copy to clipboard',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
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
            if(!_isFullscreenOutput)
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
                      hintText: 'Paste your JSON here...',
                      isInput: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Center - Buttons and Error
            if(!(_isFullscreenInput || _isFullscreenOutput))
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
            if(!_isFullscreenOutput)
            const SizedBox(height: 16),
            // Bottom - Output
            if(!_isFullscreenInput)
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
    _inputCodeController.dispose();
    _outputCodeController.dispose();
    super.dispose();
  }
}
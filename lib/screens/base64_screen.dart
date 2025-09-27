import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class Base64Screen extends StatefulWidget {
  const Base64Screen({super.key});

  @override
  State<Base64Screen> createState() => _Base64ScreenState();
}

class _Base64ScreenState extends State<Base64Screen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _isEncoding = true;

  void _processBase64() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter text to ${_isEncoding ? 'encode' : 'decode'}';
        });
        return;
      }

      String result;
      if (_isEncoding) {
        // Encode to Base64
        final bytes = utf8.encode(input);
        result = base64.encode(bytes);
      } else {
        // Decode from Base64
        // Clean and validate the input
        String cleanInput = input.replaceAll(RegExp(r'\s'), ''); // Remove whitespace
        
        // Check if the string contains only valid Base64 characters
        if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(cleanInput)) {
          throw const FormatException('Invalid Base64 characters detected');
        }
        
        // Add proper padding if missing
        while (cleanInput.length % 4 != 0) {
          cleanInput += '=';
        }
        
        final bytes = base64.decode(cleanInput);
        result = utf8.decode(bytes);
      }
      
      setState(() {
        _outputController.text = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error ${_isEncoding ? 'encoding' : 'decoding'}: ${e.toString()}';
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

  void _switchMode() {
    setState(() {
      _isEncoding = !_isEncoding;
      _errorMessage = '';
      // Optionally swap input and output
      final temp = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = temp;
    });
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _inputController.text = clipboardData!.text!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text pasted from clipboard'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to paste from clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildTextFieldWithOverlay({
    required TextEditingController controller,
    required String hintText,
    required bool showPaste,
    required bool showCopy,
    bool readOnly = false,
  }) {
    return Stack(
      children: [
        TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hintText,
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPaste)
                Tooltip(
                  message: 'Paste from clipboard',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pasteFromClipboard,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.content_paste,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showPaste && showCopy) const SizedBox(width: 4),
              if (showCopy)
                Tooltip(
                  message: 'Copy to clipboard',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _copyToClipboard(controller.text),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.content_copy,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Input ${_isEncoding ? '(Plain Text)' : '(Base64)'}:',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: _isEncoding,
                  onChanged: (value) {
                    setState(() {
                      _isEncoding = value;
                      _errorMessage = '';
                    });
                  },
                ),
                Text(_isEncoding ? 'Encode' : 'Decode'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _buildTextFieldWithOverlay(
                controller: _inputController,
                hintText: _isEncoding 
                    ? 'Enter plain text to encode...'
                    : 'Enter Base64 string to decode...',
                showPaste: true,
                showCopy: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _processBase64,
                  icon: Icon(_isEncoding ? Icons.lock : Icons.lock_open),
                  label: Text(_isEncoding ? 'Encode' : 'Decode'),
                ),
                ElevatedButton.icon(
                  onPressed: _switchMode,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Switch'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_errorMessage.isNotEmpty) const SizedBox(height: 8),
            Text(
              'Output ${_isEncoding ? '(Base64)' : '(Plain Text)'}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _buildTextFieldWithOverlay(
                controller: _outputController,
                hintText: _isEncoding 
                    ? 'Base64 encoded text will appear here...'
                    : 'Decoded plain text will appear here...',
                showPaste: false,
                showCopy: true,
                readOnly: true,
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
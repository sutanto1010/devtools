import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UriEncoderScreen extends StatefulWidget {
  const UriEncoderScreen({super.key});

  @override
  State<UriEncoderScreen> createState() => _UriEncoderScreenState();
}

class _UriEncoderScreenState extends State<UriEncoderScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _isEncoding = true;

  void _processUri() {
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
        // Encode URI
        result = Uri.encodeComponent(input);
      } else {
        // Decode URI
        result = Uri.decodeComponent(input);
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

  void _copyToClipboard(String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Input ${_isEncoding ? '(Plain Text)' : '(URI Encoded)'}' , 
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
              child: TextField(
                controller: _inputController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: _isEncoding 
                      ? 'Enter text to encode (e.g., "Hello World!", "user@example.com")'
                      : 'Enter URI encoded text to decode (e.g., "Hello%20World%21", "user%40example.com")',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _inputController.clear(),
                  ),
                ),
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _processUri,
                  icon: Icon(_isEncoding ? Icons.lock : Icons.lock_open),
                  label: Text(_isEncoding ? 'Encode' : 'Decode'),
                ),
                ElevatedButton.icon(
                  onPressed: _switchMode,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Switch Mode'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Output ${_isEncoding ? '(URI Encoded)' : '(Plain Text)'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_outputController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(_outputController.text),
                    tooltip: 'Copy to clipboard',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _outputController,
                maxLines: null,
                expands: true,
                readOnly: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Result will appear here...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URI Encoding Information:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• URI encoding converts special characters to percent-encoded format\n'
                      '• Spaces become %20, @ becomes %40, ! becomes %21\n'
                      '• Used in URLs, form data, and HTTP requests\n'
                      '• Also known as URL encoding or percent encoding',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
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
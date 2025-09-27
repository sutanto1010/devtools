import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class HexToAsciiScreen extends StatefulWidget {
  const HexToAsciiScreen({super.key});

  @override
  State<HexToAsciiScreen> createState() => _HexToAsciiScreenState();
}

class _HexToAsciiScreenState extends State<HexToAsciiScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _isHexToAscii = true;
  bool _includeSpaces = true;
  bool _uppercase = true;
  String _delimiter = ' ';
  
  final List<String> _delimiters = [' ', '', ':', '-', ',', '\\x'];

  void _processConversion() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter ${_isHexToAscii ? 'hex' : 'ASCII'} text to convert';
        });
        return;
      }

      String result;
      if (_isHexToAscii) {
        result = _hexToAscii(input);
      } else {
        result = _asciiToHex(input);
      }
      
      setState(() {
        _outputController.text = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting: ${e.toString()}';
      });
    }
  }

  String _hexToAscii(String hexString) {
    // Remove common prefixes and clean the string
    String cleanHex = hexString
        .replaceAll('0x', '')
        .replaceAll('\\x', '')
        .replaceAll(' ', '')
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll(',', '');

    // Validate hex string
    if (!RegExp(r'^[0-9A-Fa-f]*$').hasMatch(cleanHex)) {
      throw Exception('Invalid hex string. Only 0-9, A-F, a-f characters are allowed.');
    }

    if (cleanHex.length % 2 != 0) {
      throw Exception('Hex string must have an even number of characters.');
    }

    List<int> bytes = [];
    for (int i = 0; i < cleanHex.length; i += 2) {
      String hexByte = cleanHex.substring(i, i + 2);
      int byte = int.parse(hexByte, radix: 16);
      bytes.add(byte);
    }

    try {
      return utf8.decode(bytes);
    } catch (e) {
      // If UTF-8 decoding fails, return raw ASCII representation
      return String.fromCharCodes(bytes);
    }
  }

  String _asciiToHex(String asciiString) {
    List<int> bytes = utf8.encode(asciiString);
    List<String> hexBytes = bytes.map((byte) {
      String hex = byte.toRadixString(16);
      if (hex.length == 1) hex = '0$hex';
      return _uppercase ? hex.toUpperCase() : hex.toLowerCase();
    }).toList();

    String delimiter = _delimiter;
    if (delimiter == '\\x') {
      return hexBytes.map((hex) => '\\x$hex').join('');
    }
    
    return hexBytes.join(delimiter);
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
      _isHexToAscii = !_isHexToAscii;
      _errorMessage = '';
      // Swap input and output
      final temp = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = temp;
    });
  }

  void _copyToClipboard() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard!')),
      );
    }
  }

  void _copyInputToClipboard() {
    if (_inputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _inputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Input copied to clipboard!')),
      );
    }
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      setState(() {
        _inputController.text = clipboardData!.text!;
      });
    }
  }

  void _pasteToOutput() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      setState(() {
        _outputController.text = clipboardData!.text!;
      });
    }
  }

  Widget _buildHexInfo() {
    if (!_isHexToAscii || _inputController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      String cleanHex = _inputController.text
          .replaceAll('0x', '')
          .replaceAll('\\x', '')
          .replaceAll(' ', '')
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll(',', '');

      if (cleanHex.isNotEmpty && RegExp(r'^[0-9A-Fa-f]*$').hasMatch(cleanHex)) {
        int byteCount = cleanHex.length ~/ 2;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hex Analysis:', style: Theme.of(context).textTheme.titleSmall),
                Text('Bytes: $byteCount'),
                Text('Hex length: ${cleanHex.length} characters'),
                if (cleanHex.length % 2 != 0)
                  const Text('⚠️ Odd number of hex characters', 
                      style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Ignore errors in analysis
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildAsciiInfo() {
    if (_isHexToAscii || _inputController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    String input = _inputController.text;
    List<int> bytes = utf8.encode(input);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASCII Analysis:', style: Theme.of(context).textTheme.titleSmall),
            Text('Characters: ${input.length}'),
            Text('Bytes (UTF-8): ${bytes.length}'),
            Text('Printable chars: ${input.runes.where((r) => r >= 32 && r <= 126).length}'),
          ],
        ),
      ),
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
            // Mode selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mode: ${_isHexToAscii ? 'Hex → ASCII' : 'ASCII → Hex'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: _isHexToAscii,
                      onChanged: (value) {
                        setState(() {
                          _isHexToAscii = value;
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // ASCII to Hex options
            if (!_isHexToAscii) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Output Options:', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _uppercase,
                            onChanged: (value) {
                              setState(() {
                                _uppercase = value ?? true;
                              });
                            },
                          ),
                          const Text('Uppercase'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Delimiter: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _delimiter,
                            items: _delimiters.map((String delimiter) {
                              String displayText = delimiter;
                              if (delimiter == '') displayText = 'None';
                              if (delimiter == ' ') displayText = 'Space';
                              if (delimiter == '\\x') displayText = '\\x prefix';
                              
                              return DropdownMenuItem<String>(
                                value: delimiter,
                                child: Text(displayText),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _delimiter = newValue ?? ' ';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Input section
            Text(
              'Input ${_isHexToAscii ? '(Hex)' : '(ASCII)'}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  TextField(
                    controller: _inputController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: _isHexToAscii 
                          ? 'Enter hex string (e.g., 48656C6C6F or 48 65 6C 6C 6F)...'
                          : 'Enter ASCII text to convert to hex...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild for info panels
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Paste from clipboard',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _pasteFromClipboard,
                              icon: const Icon(Icons.paste, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Copy input to clipboard',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _copyInputToClipboard,
                              icon: const Icon(Icons.copy, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Info panels
            _buildHexInfo(),
            _buildAsciiInfo(),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _processConversion,
                  icon: Icon(_isHexToAscii ? Icons.transform : Icons.code),
                  label: Text(_isHexToAscii ? 'Convert' : 'Convert'),
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

            // Error message
            if (_errorMessage.isNotEmpty) ...[
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
              const SizedBox(height: 8),
            ],

            // Output section
            Text(
              'Output ${_isHexToAscii ? '(ASCII)' : '(Hex)'}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  TextField(
                    controller: _outputController,
                    maxLines: null,
                    expands: true,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: _isHexToAscii 
                          ? 'ASCII text will appear here...'
                          : 'Hex string will appear here...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Copy output to clipboard',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _copyToClipboard,
                              icon: const Icon(Icons.copy, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
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
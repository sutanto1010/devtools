import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class UuidScreen extends StatefulWidget {
  const UuidScreen({super.key});

  @override
  State<UuidScreen> createState() => _UuidScreenState();
}

class _UuidScreenState extends State<UuidScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  String _validationMessage = '';
  bool _isGenerating = true;
  int _uuidVersion = 4;

  // Generate UUID v4 (random)
  String _generateUuidV4() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10
    
    return '${_bytesToHex(bytes.sublist(0, 4))}-'
           '${_bytesToHex(bytes.sublist(4, 6))}-'
           '${_bytesToHex(bytes.sublist(6, 8))}-'
           '${_bytesToHex(bytes.sublist(8, 10))}-'
           '${_bytesToHex(bytes.sublist(10, 16))}';
  }

  // Generate UUID v1 (timestamp-based)
  String _generateUuidV1() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch * 10000 + 0x01B21DD213814000;
    
    // Time low (32 bits)
    final timeLow = timestamp & 0xFFFFFFFF;
    
    // Time mid (16 bits)
    final timeMid = (timestamp >> 32) & 0xFFFF;
    
    // Time high and version (16 bits)
    final timeHiAndVersion = ((timestamp >> 48) & 0x0FFF) | 0x1000; // Version 1
    
    // Clock sequence (14 bits) + variant (2 bits)
    final clockSeq = (random.nextInt(0x3FFF)) | 0x8000; // Variant 10
    
    // Node (48 bits) - using random for simplicity
    final node = List<int>.generate(6, (i) => random.nextInt(256));
    
    return '${timeLow.toRadixString(16).padLeft(8, '0')}-'
           '${timeMid.toRadixString(16).padLeft(4, '0')}-'
           '${timeHiAndVersion.toRadixString(16).padLeft(4, '0')}-'
           '${clockSeq.toRadixString(16).padLeft(4, '0')}-'
           '${node.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}';
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  void _generateUuid() {
    setState(() {
      _errorMessage = '';
      _validationMessage = '';
    });

    try {
      String uuid;
      if (_uuidVersion == 1) {
        uuid = _generateUuidV1();
      } else {
        uuid = _generateUuidV4();
      }
      
      setState(() {
        _outputController.text = uuid;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating UUID: ${e.toString()}';
      });
    }
  }

  void _validateUuid() {
    setState(() {
      _errorMessage = '';
      _validationMessage = '';
    });

    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a UUID to validate';
      });
      return;
    }

    // UUID regex pattern
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );

    if (!uuidRegex.hasMatch(input)) {
      setState(() {
        _validationMessage = '❌ Invalid UUID format';
      });
      return;
    }

    // Extract version and variant
    final parts = input.split('-');
    final versionHex = parts[2][0];
    final variantHex = parts[3][0];
    
    final version = int.parse(versionHex, radix: 16);
    final variantBits = int.parse(variantHex, radix: 16);
    
    String versionInfo = '';
    switch (version) {
      case 1:
        versionInfo = 'Version 1 (Timestamp-based)';
        break;
      case 2:
        versionInfo = 'Version 2 (DCE Security)';
        break;
      case 3:
        versionInfo = 'Version 3 (MD5 hash)';
        break;
      case 4:
        versionInfo = 'Version 4 (Random)';
        break;
      case 5:
        versionInfo = 'Version 5 (SHA-1 hash)';
        break;
      default:
        versionInfo = 'Unknown version';
    }

    String variantInfo = '';
    if ((variantBits & 0x8) == 0) {
      variantInfo = 'NCS backward compatibility';
    } else if ((variantBits & 0xC) == 0x8) {
      variantInfo = 'RFC 4122 variant';
    } else if ((variantBits & 0xE) == 0xC) {
      variantInfo = 'Microsoft GUID';
    } else {
      variantInfo = 'Reserved for future use';
    }

    setState(() {
      _validationMessage = '✅ Valid UUID\n'
                          'Format: Standard UUID\n'
                          'Version: $versionInfo\n'
                          'Variant: $variantInfo';
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
      _validationMessage = '';
    });
  }

  void _switchMode() {
    setState(() {
      _isGenerating = !_isGenerating;
      _errorMessage = '';
      _validationMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UUID Generator/Validator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isGenerating ? 'UUID Generator' : 'UUID Validator',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: _isGenerating,
                  onChanged: (value) => _switchMode(),
                ),
                Text(_isGenerating ? 'Generate' : 'Validate'),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isGenerating) ..._buildGeneratorUI() else ..._buildValidatorUI(),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isGenerating ? _generateUuid : _validateUuid,
                  icon: Icon(_isGenerating ? Icons.refresh : Icons.check_circle),
                  label: Text(_isGenerating ? 'Generate' : 'Validate'),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            if (_validationMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _validationMessage.startsWith('✅') 
                      ? Colors.green.shade100 
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _validationMessage,
                  style: TextStyle(
                    color: _validationMessage.startsWith('✅') 
                        ? Colors.green.shade700 
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGeneratorUI() {
    return [
      Row(
        children: [
          const Text('UUID Version: ', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<int>(
            value: _uuidVersion,
            items: const [
              DropdownMenuItem(value: 1, child: Text('Version 1 (Timestamp)')),
              DropdownMenuItem(value: 4, child: Text('Version 4 (Random)')),
            ],
            onChanged: (value) {
              setState(() {
                _uuidVersion = value!;
              });
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'Generated UUID:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _outputController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Generated UUID will appear here...',
                ),
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
      ),
    ];
  }

  List<Widget> _buildValidatorUI() {
    return [
      const Text(
        'Enter UUID to validate:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _inputController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'e.g., 550e8400-e29b-41d4-a716-446655440000',
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
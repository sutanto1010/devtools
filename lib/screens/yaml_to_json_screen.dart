import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'dart:convert';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/json.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
class YamlToJsonScreen extends StatefulWidget {
  const YamlToJsonScreen({super.key});

  @override
  State<YamlToJsonScreen> createState() => _YamlToJsonScreenState();
}

class _YamlToJsonScreenState extends State<YamlToJsonScreen> {
  String _errorMessage = '';
  bool _isYamlToJson = true;
  bool isFullscreenInput = false;
  bool isFullscreenOutput = false;
  final CodeController _jsonCodeController = CodeController(
    text: '',
    language: json,
  );
  final CodeController _yamlCodeController = CodeController(
    text: '',
    language: yaml,
  );

  // Sample data constants
  static const String _sampleYaml = '''name: John Doe
age: 30
email: john.doe@example.com
address:
  street: 123 Main St
  city: New York
  country: USA
hobbies:
  - reading
  - swimming
  - coding
active: true
balance: 1250.75''';

  static const String _sampleJson = '''{
  "name": "Jane Smith",
  "age": 28,
  "email": "jane.smith@example.com",
  "address": {
    "street": "456 Oak Ave",
    "city": "Los Angeles",
    "country": "USA"
  },
  "hobbies": [
    "photography",
    "hiking",
    "cooking"
  ],
  "active": true,
  "balance": 2340.50
}''';

  void _convertYamlToJson() {
    setState(() {
      _errorMessage = '';
      _jsonCodeController.clear();
    });

    try {
      final input = _yamlCodeController.fullText;
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter YAML data to convert';
        });
        return;
      }

      final yamlData = loadYaml(input);
      final jsonData = _yamlToJson(yamlData);
      
      String jsonString;
      const encoder = JsonEncoder.withIndent('  ');
      jsonString = encoder.convert(jsonData);
     
      
      setState(() {
        _jsonCodeController.text = jsonString;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting YAML: ${e.toString()}';
      });
    }
  }

  void _convertJsonToYaml() {
    setState(() {
      _errorMessage = '';
      _yamlCodeController.clear();
    });

    try {
      final input = _jsonCodeController.fullText;
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON data to convert';
        });
        return;
      }

      final jsonData = jsonDecode(input);
      final yamlString = _jsonToYaml(jsonData);
      
      setState(() {
        _yamlCodeController.text = yamlString;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting JSON: ${e.toString()}';
      });
    }
  }

  dynamic _yamlToJson(dynamic yamlData) {
    if (yamlData is YamlMap) {
      final Map<String, dynamic> result = {};
      for (final key in yamlData.keys) {
        result[key.toString()] = _yamlToJson(yamlData[key]);
      }
      return result;
    } else if (yamlData is YamlList) {
      return yamlData.map((item) => _yamlToJson(item)).toList();
    } else {
      return yamlData;
    }
  }

  String _jsonToYaml(dynamic jsonData, {int indent = 0}) {
    final indentStr = '  ' * indent;
    
    if (jsonData is Map<String, dynamic>) {
      if (jsonData.isEmpty) return '{}';
      
      final buffer = StringBuffer();
      final entries = jsonData.entries.toList();
      
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final key = entry.key;
        final value = entry.value;
        
        if (i > 0) buffer.writeln();
        
        if (value is Map<String, dynamic> || value is List) {
          buffer.write('$indentStr$key:');
          if (value is Map<String, dynamic> && value.isEmpty) {
            buffer.write(' {}');
          } else if (value is List && value.isEmpty) {
            buffer.write(' []');
          } else {
            buffer.writeln();
            buffer.write(_jsonToYaml(value, indent: indent + 1));
          }
        } else {
          final yamlValue = _formatYamlValue(value);
          buffer.write('$indentStr$key: $yamlValue');
        }
      }
      
      return buffer.toString();
    } else if (jsonData is List) {
      if (jsonData.isEmpty) return '[]';
      
      final buffer = StringBuffer();
      
      for (int i = 0; i < jsonData.length; i++) {
        final item = jsonData[i];
        
        if (i > 0) buffer.writeln();
        
        if (item is Map<String, dynamic> || item is List) {
          buffer.write('$indentStr-');
          if (item is Map<String, dynamic> && item.isNotEmpty) {
            buffer.writeln();
            final itemYaml = _jsonToYaml(item, indent: indent + 1);
            // Add proper indentation for nested maps in lists
            final lines = itemYaml.split('\n');
            for (int j = 0; j < lines.length; j++) {
              if (j == 0) {
                buffer.write('$indentStr  ${lines[j]}');
              } else {
                buffer.write('\n$indentStr  ${lines[j]}');
              }
            }
          } else if (item is List && item.isNotEmpty) {
            buffer.writeln();
            buffer.write(_jsonToYaml(item, indent: indent + 1));
          } else {
            buffer.write(' ${_formatYamlValue(item)}');
          }
        } else {
          buffer.write('$indentStr- ${_formatYamlValue(item)}');
        }
      }
      
      return buffer.toString();
    } else {
      return _formatYamlValue(jsonData);
    }
  }

  String _formatYamlValue(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is String) {
      // Check if string needs quoting
      if (value.contains('\n') || 
          value.contains(':') || 
          value.contains('#') ||
          value.contains('[') ||
          value.contains(']') ||
          value.contains('{') ||
          value.contains('}') ||
          value.startsWith(' ') ||
          value.endsWith(' ') ||
          value.isEmpty) {
        return '"${value.replaceAll('"', '\\"')}"';
      }
      return value;
    } else if (value is bool) {
      return value.toString();
    } else if (value is num) {
      return value.toString();
    } else {
      return value.toString();
    }
  }

  void _clearAll() {
    setState(() {
      _yamlCodeController.clear();
      _jsonCodeController.clear();
      _errorMessage = '';
    });
  }

  void _swapConversion() {
    setState(() {
      _isYamlToJson = !_isYamlToJson;
      _errorMessage = '';
    });
  }

  void _loadSample() {
    setState(() {
      final inputCodeCtrl = _isYamlToJson ? _yamlCodeController : _jsonCodeController;
      inputCodeCtrl.clear();
      inputCodeCtrl.text = _isYamlToJson ? _sampleYaml : _sampleJson;
      _errorMessage = '';
    });
  }

  void _copyToClipboard(String text, String type) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      setState(() {
        if (_isYamlToJson) {
          _jsonCodeController.clear();
          _yamlCodeController.text = clipboardData!.text!;
        } else {
          _yamlCodeController.clear();
          _jsonCodeController.text = clipboardData!.text!;
        }
      });
    }
  }

  Widget _buildCodeEditor({
    required String hintText,
    required bool isInput,
  }) {
    var codeCtl = _jsonCodeController;
    if (_isYamlToJson){
      if (isInput) {
        codeCtl = _yamlCodeController;
      }else{
        codeCtl = _jsonCodeController;
      }
    }else{
      if (isInput) {
        codeCtl = _jsonCodeController;
      }else{
        codeCtl = _yamlCodeController;
      }
    }
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: SingleChildScrollView(
            child: CodeTheme(
              data: CodeThemeData(styles: githubTheme),
              child: CodeField(controller: codeCtl, key: UniqueKey(),),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInput)
                IconButton(
                  icon: const Icon(Icons.paste, size: 16),
                  tooltip: 'Paste from clipboard',
                  iconSize: 16,
                  onPressed: _pasteFromClipboard,
                ),
              if (isInput) const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy to clipboard',
                iconSize: 16,
                onPressed: () => _copyToClipboard(codeCtl.fullText, _isYamlToJson ? 'YAML' : 'JSON'),
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
            // Input Section
            Text(
              _isYamlToJson ? 'Input YAML:' : 'Input JSON:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _buildCodeEditor(
                hintText: _isYamlToJson 
                    ? 'Paste your YAML data here...' 
                    : 'Paste your JSON data here...',
                isInput: true,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isYamlToJson ? _convertYamlToJson : _convertJsonToYaml,
                  icon: const Icon(Icons.transform),
                  label: Text(_isYamlToJson ? 'Convert to JSON' : 'Convert to YAML'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _swapConversion,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Swap'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadSample,
                  icon: const Icon(Icons.file_copy),
                  label: const Text('Sample'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Error Message
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
            
            // Output Section
            Text(
              _isYamlToJson ? 'JSON Output:' : 'YAML Output:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _buildCodeEditor(
                hintText: _isYamlToJson 
                    ? 'Converted JSON will appear here...' 
                    : 'Converted YAML will appear here...',
                isInput: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void  _toggleFullscreen(bool isInput) {
    setState(() {
      if (isInput) {
        isFullscreenInput = !isFullscreenInput;
      } else {
        isFullscreenOutput = !isFullscreenOutput;
      }
    });
  }

  @override
  void dispose() {
    _jsonCodeController.dispose();
    _yamlCodeController.dispose();
    super.dispose();
  }
}
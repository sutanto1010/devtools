import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'dart:convert';

class YamlToJsonScreen extends StatefulWidget {
  const YamlToJsonScreen({super.key});

  @override
  State<YamlToJsonScreen> createState() => _YamlToJsonScreenState();
}

class _YamlToJsonScreenState extends State<YamlToJsonScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _isYamlToJson = true;
  bool _prettyPrint = true;

  void _convertYamlToJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter YAML data to convert';
        });
        return;
      }

      final yamlData = loadYaml(input);
      final jsonData = _yamlToJson(yamlData);
      
      String jsonString;
      if (_prettyPrint) {
        const encoder = JsonEncoder.withIndent('  ');
        jsonString = encoder.convert(jsonData);
      } else {
        jsonString = jsonEncode(jsonData);
      }
      
      setState(() {
        _outputController.text = jsonString;
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
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON data to convert';
        });
        return;
      }

      final jsonData = jsonDecode(input);
      final yamlString = _jsonToYaml(jsonData);
      
      setState(() {
        _outputController.text = yamlString;
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
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
    });
  }

  void _swapConversion() {
    setState(() {
      _isYamlToJson = !_isYamlToJson;
      final temp = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = temp;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isYamlToJson ? 'YAML to JSON Converter' : 'JSON to YAML Converter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Options Row
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Pretty print JSON'),
                    subtitle: const Text('Format JSON with indentation'),
                    value: _prettyPrint,
                    onChanged: _isYamlToJson ? (value) {
                      setState(() {
                        _prettyPrint = value ?? true;
                      });
                    } : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Input Section
            Text(
              _isYamlToJson ? 'Input YAML:' : 'Input JSON:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _inputController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isYamlToJson 
                      ? 'Paste your YAML data here...' 
                      : 'Paste your JSON data here...',
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isYamlToJson ? _convertYamlToJson : _convertJsonToYaml,
                  icon: const Icon(Icons.transform),
                  label: Text(_isYamlToJson ? 'Convert to JSON' : 'Convert to YAML'),
                ),
                ElevatedButton.icon(
                  onPressed: _swapConversion,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Swap'),
                ),
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
              child: TextField(
                controller: _outputController,
                maxLines: null,
                expands: true,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isYamlToJson 
                      ? 'Converted JSON will appear here...' 
                      : 'Converted YAML will appear here...',
                ),
                textAlignVertical: TextAlignVertical.top,
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
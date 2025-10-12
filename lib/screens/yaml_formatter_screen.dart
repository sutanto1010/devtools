import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:flutter_highlight/themes/github.dart';

class YamlFormatterScreen extends StatefulWidget {
  const YamlFormatterScreen({super.key});

  @override
  State<YamlFormatterScreen> createState() => _YamlFormatterScreenState();
}

class _YamlFormatterScreenState extends State<YamlFormatterScreen> {
  final CodeController _inputController = CodeController(
    text: '',
    language: yaml,
  );
  final CodeController _outputController = CodeController(
    text: '',
    language: yaml,
  );
  String _errorMessage = '';

  static const String _sampleYaml = '''# Sample YAML Configuration
name: "My Application"
version: "1.0.0"
description: "A sample application configuration"

database:
  host: "localhost"
  port: 5432
  name: "myapp_db"
  credentials:
    username: "admin"
    password: "secret123"

server:
  host: "0.0.0.0"
  port: 8080
  ssl:
    enabled: true
    certificate: "/path/to/cert.pem"
    key: "/path/to/key.pem"

features:
  - authentication
  - logging
  - monitoring
  - caching

logging:
  level: "info"
  outputs:
    - type: "console"
      format: "json"
    - type: "file"
      path: "/var/log/app.log"
      rotation:
        max_size: "100MB"
        max_files: 5

cache:
  type: "redis"
  ttl: 3600
  settings:
    max_memory: "256mb"
    eviction_policy: "allkeys-lru"
''';

  void _formatYaml() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter YAML to format';
        });
        return;
      }

      // Parse YAML using the yaml package
      final yamlDoc = loadYaml(input);
      
      // Convert back to formatted YAML string
      final formattedYaml = _yamlToString(yamlDoc, 0);
      
      setState(() {
        _outputController.text = formattedYaml;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error formatting YAML: ${e.toString()}';
      });
    }
  }

  String _yamlToString(dynamic value, int indent) {
    final indentStr = '  ' * indent;
    
    if (value == null) {
      return 'null';
    } else if (value is Map) {
      if (value.isEmpty) return '{}';
      
      final buffer = StringBuffer();
      final entries = value.entries.toList();
      
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final key = entry.key.toString();
        final val = entry.value;
        
        if (i > 0) buffer.write('\n');
        
        if (val is Map && val.isNotEmpty) {
          buffer.write('$indentStr$key:');
          final nestedContent = _yamlToString(val, indent + 1);
          buffer.write('\n$nestedContent');
        } else if (val is List && val.isNotEmpty) {
          buffer.write('$indentStr$key:');
          final nestedContent = _yamlToString(val, indent + 1);
          buffer.write('\n$nestedContent');
        } else {
          final valueStr = _yamlToString(val, indent);
          buffer.write('$indentStr$key: $valueStr');
        }
      }
      
      return buffer.toString();
    } else if (value is List) {
      if (value.isEmpty) return '[]';
      
      final buffer = StringBuffer();
      
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        
        if (i > 0) buffer.write('\n');
        
        if (item is Map && item.isNotEmpty) {
          // For maps in lists, we need special handling
          final entries = (item as Map).entries.toList();
          buffer.write('$indentStr-');
          
          for (int j = 0; j < entries.length; j++) {
            final entry = entries[j];
            final key = entry.key.toString();
            final val = entry.value;
            
            if (j == 0) {
              // First key-value pair goes on the same line as the dash
              if (val is Map && val.isNotEmpty) {
                buffer.write(' $key:');
                final nestedContent = _yamlToString(val, indent + 2);
                buffer.write('\n$nestedContent');
              } else if (val is List && val.isNotEmpty) {
                buffer.write(' $key:');
                final nestedContent = _yamlToString(val, indent + 2);
                buffer.write('\n$nestedContent');
              } else {
                final valueStr = _yamlToString(val, indent + 1);
                buffer.write(' $key: $valueStr');
              }
            } else {
              // Subsequent key-value pairs are indented to align with the first key
              buffer.write('\n$indentStr ');
              if (val is Map && val.isNotEmpty) {
                buffer.write(' $key:');
                final nestedContent = _yamlToString(val, indent + 2);
                buffer.write('\n$nestedContent');
              } else if (val is List && val.isNotEmpty) {
                buffer.write(' $key:');
                final nestedContent = _yamlToString(val, indent + 2);
                buffer.write('\n$nestedContent');
              } else {
                final valueStr = _yamlToString(val, indent + 1);
                buffer.write(' $key: $valueStr');
              }
            }
          }
        } else if (item is List && item.isNotEmpty) {
          buffer.write('$indentStr-');
          final nestedContent = _yamlToString(item, indent + 1);
          buffer.write('\n$nestedContent');
        } else {
          final valueStr = _yamlToString(item, indent);
          buffer.write('$indentStr- $valueStr');
        }
      }
      
      return buffer.toString();
    } else if (value is String) {
      // Handle special string cases
      if (value.contains('\n')) {
        // Use literal block scalar for multiline strings
        final currentIndentStr = '  ' * (indent + 1);
        return '|\n${value.split('\n').map((line) => '$currentIndentStr$line').join('\n')}';
      } else if (value.contains('"') || value.contains("'")) {
        // Quote strings that contain quotes
        return '"${value.replaceAll('"', '\\"')}"';
      }
      // Check if string needs quoting (starts with special chars, looks like number, etc.)
      if (value.isEmpty || 
          RegExp(r'^[\d\-\+\.]').hasMatch(value) ||
          ['true', 'false', 'null', 'yes', 'no', 'on', 'off'].contains(value.toLowerCase()) ||
          value.contains(':') ||
          value.contains('#') ||
          value.startsWith(' ') ||
          value.endsWith(' ')) {
        return '"$value"';
      }
      return value;
    } else {
      return value.toString();
    }
  }

  void _validateYaml() {
    setState(() {
      _errorMessage = '';
    });

    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter YAML to validate';
      });
      return;
    }

    try {
      // Use the yaml package to validate
      loadYaml(input);
      setState(() {
        _errorMessage = 'YAML is valid!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'YAML validation error: ${e.toString()}';
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

  void _loadSample() {
    setState(() {
      _inputController.text = _sampleYaml;
      _outputController.clear();
      _errorMessage = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample YAML loaded'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _inputController.text = clipboardData!.text!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasted from clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to paste from clipboard: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      if (_outputController.text.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: _outputController.text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No output to copy'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy to clipboard: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCodeEditor(CodeController controller) {
    return Container(
       decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey)),
          borderRadius: BorderRadius.circular(4),
        ),
      child: SingleChildScrollView(
        child: CodeTheme(
          data: CodeThemeData(styles: githubTheme),
          child: CodeField(controller: controller)
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
            const Text(
              'Input YAML:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  _buildCodeEditor(_inputController),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.content_paste),
                      iconSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _pasteFromClipboard,
                      tooltip: "Paste from clipboard",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatYaml,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _validateYaml,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validate'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadSample,
                  icon: const Icon(Icons.description),
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
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _errorMessage == 'YAML is valid!' 
                      ? Colors.green.shade100 
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: _errorMessage == 'YAML is valid!' 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
              ),
            if (_errorMessage.isNotEmpty) const SizedBox(height: 8),
            const Text(
              'Formatted Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  _buildCodeEditor(_outputController),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.content_copy),
                      iconSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _copyToClipboard,
                      tooltip: "Copy to clipboard",
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
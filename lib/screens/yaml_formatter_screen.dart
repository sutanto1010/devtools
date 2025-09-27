import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class YamlFormatterScreen extends StatefulWidget {
  const YamlFormatterScreen({super.key});

  @override
  State<YamlFormatterScreen> createState() => _YamlFormatterScreenState();
}

class _YamlFormatterScreenState extends State<YamlFormatterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';

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
          buffer.write('$indentStr$key:\n');
          buffer.write(_yamlToString(val, indent + 1));
        } else if (val is List && val.isNotEmpty) {
          buffer.write('$indentStr$key:\n');
          buffer.write(_yamlToString(val, indent + 1));
        } else {
          buffer.write('$indentStr$key: ${_yamlToString(val, 0)}');
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
          buffer.write('$indentStr- ');
          final itemStr = _yamlToString(item, indent + 1);
          // Remove the first indent from the first line since we already added "- "
          final lines = itemStr.split('\n');
          buffer.write(lines.first.substring(2));
          if (lines.length > 1) {
            buffer.write('\n');
            buffer.write(lines.skip(1).join('\n'));
          }
        } else if (item is List && item.isNotEmpty) {
          buffer.write('$indentStr- \n');
          buffer.write(_yamlToString(item, indent + 1));
        } else {
          buffer.write('$indentStr- ${_yamlToString(item, 0)}');
        }
      }
      
      return buffer.toString();
    } else if (value is String) {
      // Handle special string cases
      if (value.contains('\n') || value.contains('"') || value.contains("'")) {
        // Use literal block scalar for multiline strings
        if (value.contains('\n')) {
          return '|\n${value.split('\n').map((line) => '  $line').join('\n')}';
        }
        // Quote strings that contain quotes or special characters
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
                  TextField(
                    controller: _inputController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste your YAML here...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: 'Paste from clipboard',
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatYaml,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                ElevatedButton.icon(
                  onPressed: _validateYaml,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validate'),
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
                  TextField(
                    controller: _outputController,
                    maxLines: null,
                    expands: true,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Formatted YAML will appear here...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: 'Copy to clipboard',
                        child: InkWell(
                          onTap: _copyToClipboard,
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
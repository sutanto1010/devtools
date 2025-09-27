import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

      // Basic YAML formatting (indentation normalization)
      final lines = input.split('\n');
      final formattedLines = <String>[];
      int indentLevel = 0;
      
      for (String line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) {
          formattedLines.add('');
          continue;
        }
        
        // Decrease indent for closing brackets/braces
        if (trimmedLine.startsWith(']') || trimmedLine.startsWith('}')) {
          indentLevel = (indentLevel - 1).clamp(0, double.infinity).toInt();
        }
        
        // Add proper indentation
        final indent = '  ' * indentLevel;
        formattedLines.add('$indent$trimmedLine');
        
        // Increase indent for opening brackets/braces or list items
        if (trimmedLine.endsWith(':') || 
            trimmedLine.endsWith('[') || 
            trimmedLine.endsWith('{') ||
            trimmedLine.startsWith('-')) {
          indentLevel++;
        }
      }
      
      setState(() {
        _outputController.text = formattedLines.join('\n');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error formatting YAML: ${e.toString()}';
      });
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

    // Basic YAML validation
    final lines = input.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      
      // Check for basic YAML syntax issues
      if (line.contains('\t')) {
        setState(() {
          _errorMessage = 'Line ${i + 1}: YAML should use spaces, not tabs';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = 'YAML appears to be valid!';
    });
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
                  color: _errorMessage.contains('valid') 
                      ? Colors.green.shade100 
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: _errorMessage.contains('valid') 
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
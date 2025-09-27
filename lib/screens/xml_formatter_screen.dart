import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class XmlFormatterScreen extends StatefulWidget {
  const XmlFormatterScreen({super.key});

  @override
  State<XmlFormatterScreen> createState() => _XmlFormatterScreenState();
}

class _XmlFormatterScreenState extends State<XmlFormatterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';
  bool _sortAttributes = false;
  int _indentSize = 2;

  void _formatXml() {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter XML to format';
        });
        return;
      }

      final formattedXml = _formatXmlString(input, _indentSize, _sortAttributes);
      
      setState(() {
        _outputController.text = formattedXml;
        _successMessage = 'XML formatted successfully';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid XML: ${e.toString()}';
      });
    }
  }

  void _minifyXml() {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter XML to minify';
        });
        return;
      }

      final minifiedXml = _minifyXmlString(input);
      
      setState(() {
        _outputController.text = minifiedXml;
        _successMessage = 'XML minified successfully';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid XML: ${e.toString()}';
      });
    }
  }

  void _validateXml() {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter XML to validate';
        });
        return;
      }

      _parseXmlString(input);
      
      setState(() {
        _successMessage = 'XML is valid!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid XML: ${e.toString()}';
      });
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _inputController.text = clipboardData.text!;
          _errorMessage = '';
          _successMessage = 'Text pasted from clipboard';
        });
      } else {
        setState(() {
          _errorMessage = 'Clipboard is empty or contains no text';
          _successMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to paste from clipboard: ${e.toString()}';
        _successMessage = '';
      });
    }
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Output copied to clipboard')),
      );
    }
  }

  String _formatXmlString(String xml, int indentSize, bool sortAttributes) {
    // Remove extra whitespace and newlines
    xml = xml.replaceAll(RegExp(r'>\s+<'), '><');
    
    final buffer = StringBuffer();
    int indentLevel = 0;
    final indent = ' ' * indentSize;
    
    // Simple XML parser and formatter
    final tagRegex = RegExp(r'<[^>]+>');
    final matches = tagRegex.allMatches(xml);
    
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text content before tag
      final textContent = xml.substring(lastEnd, match.start).trim();
      if (textContent.isNotEmpty) {
        buffer.writeln('${indent * indentLevel}$textContent');
      }
      
      final tag = match.group(0)!;
      
      if (tag.startsWith('<?') && tag.endsWith('?>')) {
        // Processing instruction (like <?xml version="1.0"?>)
        buffer.writeln('${indent * indentLevel}$tag');
      } else if (tag.startsWith('<!--') && tag.endsWith('-->')) {
        // Comment
        buffer.writeln('${indent * indentLevel}$tag');
      } else if (tag.startsWith('</')) {
        // Closing tag
        indentLevel--;
        buffer.writeln('${indent * indentLevel}$tag');
      } else if (tag.endsWith('/>')) {
        // Self-closing tag
        final formattedTag = sortAttributes ? _sortTagAttributes(tag) : tag;
        buffer.writeln('${indent * indentLevel}$formattedTag');
      } else {
        // Opening tag
        final formattedTag = sortAttributes ? _sortTagAttributes(tag) : tag;
        buffer.writeln('${indent * indentLevel}$formattedTag');
        indentLevel++;
      }
      
      lastEnd = match.end;
    }
    
    // Add remaining text content
    final remainingText = xml.substring(lastEnd).trim();
    if (remainingText.isNotEmpty) {
      buffer.writeln('${indent * indentLevel}$remainingText');
    }
    
    return buffer.toString().trim();
  }

  String _minifyXmlString(String xml) {
    // Remove whitespace between tags and normalize
    return xml
        .replaceAll(RegExp(r'>\s+<'), '><')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _sortTagAttributes(String tag) {
    if (!tag.contains(' ')) return tag;
    
    final tagNameMatch = RegExp(r'<(/?\w+)').firstMatch(tag);
    if (tagNameMatch == null) return tag;
    
    final tagName = tagNameMatch.group(1)!;
    final attributesString = tag.substring(tagNameMatch.end, tag.length - (tag.endsWith('/>') ? 2 : 1));
    
    if (attributesString.trim().isEmpty) return tag;
    
    // Parse attributes - fixed regex to properly handle quoted values
    final attributeRegex = RegExp('(\w+)\s*=\s*("[^"]*"|\'[^\']*\')');
    final attributes = <String>[];
    
    for (final match in attributeRegex.allMatches(attributesString)) {
      attributes.add(match.group(0)!);
    }
    
    attributes.sort();
    
    final ending = tag.endsWith('/>') ? '/>' : '>';
    return '<$tagName ${attributes.join(' ')}$ending';
  }

  void _parseXmlString(String xml) {
    // Basic XML validation
    final stack = <String>[];
    final tagRegex = RegExp(r'<([^>]+)>');
    
    for (final match in tagRegex.allMatches(xml)) {
      final tag = match.group(1)!;
      
      if (tag.startsWith('?') && tag.endsWith('?')) {
        // Processing instruction (like ?xml version="1.0"?)
        continue; // Skip processing instructions in validation
      } else if (tag.startsWith('!--') && tag.endsWith('--')) {
        // Comment
        continue; // Skip comments in validation
      } else if (tag.startsWith('/')) {
        // Closing tag
        final tagName = tag.substring(1).split(' ')[0];
        if (stack.isEmpty) {
          throw Exception('Unexpected closing tag: <$tag>');
        }
        final expectedTag = stack.removeLast();
        if (expectedTag != tagName) {
          throw Exception('Mismatched tags: expected </$expectedTag>, found <$tag>');
        }
      } else if (!tag.endsWith('/')) {
        // Opening tag
        final tagName = tag.split(' ')[0];
        stack.add(tagName);
      }
      // Self-closing tags don't need to be tracked
    }
    
    if (stack.isNotEmpty) {
      throw Exception('Unclosed tags: ${stack.join(', ')}');
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
              'Input XML:',
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
                      hintText: 'Paste your XML here...',
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
                              icon: const Icon(Icons.content_paste, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Clear input',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _inputController.clear();
                                  _errorMessage = '';
                                  _successMessage = '';
                                });
                              },
                              icon: const Icon(Icons.clear, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Options Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _sortAttributes,
                        onChanged: (value) {
                          setState(() {
                            _sortAttributes = value ?? false;
                          });
                        },
                      ),
                      const Text('Sort Attributes'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Indent Size:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _indentSize,
                  items: [2, 4, 8].map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text('$size spaces'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _indentSize = value ?? 2;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatXml,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                ElevatedButton.icon(
                  onPressed: _minifyXml,
                  icon: const Icon(Icons.compress),
                  label: const Text('Minify'),
                ),
                ElevatedButton.icon(
                  onPressed: _validateXml,
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
            
            // Status Messages
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_errorMessage.isNotEmpty || _successMessage.isNotEmpty) 
              const SizedBox(height: 8),
            
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
                      hintText: 'Formatted XML will appear here...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Tooltip(
                      message: 'Copy to clipboard',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          onPressed: _copyOutput,
                          icon: const Icon(Icons.content_copy, size: 18),
                          iconSize: 18,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: const EdgeInsets.all(4),
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
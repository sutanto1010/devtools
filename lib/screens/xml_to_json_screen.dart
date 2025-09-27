import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'dart:convert';

class XmlToJsonScreen extends StatefulWidget {
  const XmlToJsonScreen({super.key});

  @override
  State<XmlToJsonScreen> createState() => _XmlToJsonScreenState();
}

class _XmlToJsonScreenState extends State<XmlToJsonScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _isXmlToJson = true;
  bool _includeAttributes = false;
  bool _preserveWhitespace = false;

  void _convertXmlToJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter XML data to convert';
        });
        return;
      }

      final document = XmlDocument.parse(input);
      final jsonData = _xmlToJson(document.rootElement);
      
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonData);
      
      setState(() {
        _outputController.text = jsonString;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting XML: ${e.toString()}';
      });
    }
  }

  void _convertJsonToXml() {
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
      final xmlString = _jsonToXml(jsonData);
      
      setState(() {
        _outputController.text = xmlString;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting JSON: ${e.toString()}';
      });
    }
  }

  dynamic _xmlToJson(XmlElement element) {
    final Map<String, dynamic> result = {};
    
    // Add attributes if enabled
    if (_includeAttributes && element.attributes.isNotEmpty) {
      for (final attr in element.attributes) {
        result['@${attr.name}'] = attr.value;
      }
    }
    
    // Handle child elements
    final Map<String, List<dynamic>> childGroups = {};
    
    for (final child in element.children) {
      if (child is XmlElement) {
        final childJson = _xmlToJson(child);
        final childName = child.name.toString();
        
        if (childGroups.containsKey(childName)) {
          childGroups[childName]!.add(childJson);
        } else {
          childGroups[childName] = [childJson];
        }
      } else if (child is XmlText) {
        final text = _preserveWhitespace ? child.value : child.value.trim();
        if (text.isNotEmpty) {
          if (result.containsKey('#text')) {
            if (result['#text'] is List) {
              (result['#text'] as List).add(text);
            } else {
              result['#text'] = [result['#text'], text];
            }
          } else {
            result['#text'] = text;
          }
        }
      }
    }
    
    // Add child elements to result
    for (final entry in childGroups.entries) {
      if (entry.value.length == 1) {
        result[entry.key] = entry.value.first;
      } else {
        result[entry.key] = entry.value;
      }
    }
    
    // If the element has only text content and no attributes, return just the text
    if (result.length == 1 && result.containsKey('#text') && !_includeAttributes) {
      return result['#text'];
    }
    
    // If the element is empty, return empty string
    if (result.isEmpty) {
      return '';
    }
    
    return result;
  }

  String _jsonToXml(dynamic json, {String rootName = 'root', int indent = 0}) {
    final indentStr = '  ' * indent;
    final buffer = StringBuffer();
    
    if (json is Map<String, dynamic>) {
      if (indent == 0) {
        buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      }
      
      buffer.write('$indentStr<$rootName');
      
      // Handle attributes (keys starting with @)
      final attributes = <String, dynamic>{};
      final elements = <String, dynamic>{};
      String? textContent;
      
      for (final entry in json.entries) {
        if (entry.key.startsWith('@')) {
          attributes[entry.key.substring(1)] = entry.value;
        } else if (entry.key == '#text') {
          textContent = entry.value.toString();
        } else {
          elements[entry.key] = entry.value;
        }
      }
      
      // Add attributes
      for (final attr in attributes.entries) {
        buffer.write(' ${attr.key}="${attr.value}"');
      }
      
      if (elements.isEmpty && textContent == null) {
        buffer.writeln('/>');
      } else {
        buffer.write('>');
        
        if (textContent != null && elements.isEmpty) {
          buffer.write(textContent);
          buffer.writeln('</$rootName>');
        } else {
          buffer.writeln();
          
          if (textContent != null) {
            buffer.writeln('$indentStr  $textContent');
          }
          
          for (final entry in elements.entries) {
            if (entry.value is List) {
              for (final item in entry.value) {
                buffer.write(_jsonToXml(item, rootName: entry.key, indent: indent + 1));
              }
            } else {
              buffer.write(_jsonToXml(entry.value, rootName: entry.key, indent: indent + 1));
            }
          }
          
          buffer.writeln('$indentStr</$rootName>');
        }
      }
    } else if (json is List) {
      for (final item in json) {
        buffer.write(_jsonToXml(item, rootName: rootName, indent: indent));
      }
    } else {
      if (indent == 0) {
        buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      }
      buffer.writeln('$indentStr<$rootName>$json</$rootName>');
    }
    
    return buffer.toString();
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _inputController.text = clipboardData!.text!;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing clipboard: ${e.toString()}';
      });
    }
  }

  void _copyInputToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _inputController.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Input copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error copying to clipboard: ${e.toString()}';
      });
    }
  }

  void _copyOutputToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _outputController.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Output copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error copying to clipboard: ${e.toString()}';
      });
    }
  }

  void _pasteToInput() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _inputController.text = clipboardData!.text!;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing clipboard: ${e.toString()}';
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

  void _swapConversion() {
    setState(() {
      _isXmlToJson = !_isXmlToJson;
      final temp = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = temp;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    title: const Text('Include attributes'),
                    subtitle: const Text('Include XML attributes in JSON'),
                    value: _includeAttributes,
                    onChanged: (value) {
                      setState(() {
                        _includeAttributes = value ?? true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Preserve whitespace'),
                    subtitle: const Text('Keep whitespace in text content'),
                    value: _preserveWhitespace,
                    onChanged: (value) {
                      setState(() {
                        _preserveWhitespace = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Input Section
            Text(
              _isXmlToJson ? 'Input XML:' : 'Input JSON:',
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
                      hintText: _isXmlToJson 
                          ? 'Paste your XML data here...' 
                          : 'Paste your JSON data here...',
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
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _pasteToInput,
                              icon: const Icon(Icons.paste, size: 16),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Copy to clipboard',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _copyInputToClipboard,
                              icon: const Icon(Icons.copy, size: 16),
                              iconSize: 16,
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
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isXmlToJson ? _convertXmlToJson : _convertJsonToXml,
                  icon: const Icon(Icons.transform),
                  label: Text(_isXmlToJson ? 'Convert to JSON' : 'Convert to XML'),
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
              _isXmlToJson ? 'JSON Output:' : 'XML Output:',
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
                      hintText: _isXmlToJson 
                          ? 'Converted JSON will appear here...' 
                          : 'Converted XML will appear here...',
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        child: IconButton(
                          onPressed: _copyOutputToClipboard,
                          icon: const Icon(Icons.copy, size: 16),
                          iconSize: 16,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
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
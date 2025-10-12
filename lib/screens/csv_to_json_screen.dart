import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

class CsvToJsonScreen extends StatefulWidget {
  const CsvToJsonScreen({super.key});

  @override
  State<CsvToJsonScreen> createState() => _CsvToJsonScreenState();
}

class _CsvToJsonScreenState extends State<CsvToJsonScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _hasHeaders = true;
  String _delimiter = ',';

  void _convertCsvToJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter CSV data to convert';
        });
        return;
      }

      final lines = input.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        setState(() {
          _errorMessage = 'No valid CSV data found';
        });
        return;
      }

      List<String> headers;
      List<List<String>> dataRows;

      if (_hasHeaders) {
        headers = _parseCsvLine(lines[0]);
        dataRows = lines.skip(1).map((line) => _parseCsvLine(line)).toList();
      } else {
        final firstRow = _parseCsvLine(lines[0]);
        headers = List.generate(firstRow.length, (index) => 'column_${index + 1}');
        dataRows = lines.map((line) => _parseCsvLine(line)).toList();
      }

      final jsonList = <Map<String, dynamic>>[];
      
      for (final row in dataRows) {
        final jsonObject = <String, dynamic>{};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          jsonObject[headers[i]] = _parseValue(row[i]);
        }
        jsonList.add(jsonObject);
      }

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonList);
      
      setState(() {
        _outputController.text = jsonString;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting CSV: ${e.toString()}';
      });
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          currentField += '"';
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == _delimiter && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    result.add(currentField.trim());
    return result;
  }

  dynamic _parseValue(String value) {
    value = value.trim();
    
    // Remove surrounding quotes if present
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    
    // Try to parse as number
    if (RegExp(r'^-?\d+$').hasMatch(value)) {
      return int.tryParse(value) ?? value;
    }
    
    if (RegExp(r'^-?\d*\.\d+$').hasMatch(value)) {
      return double.tryParse(value) ?? value;
    }
    
    // Try to parse as boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    
    // Return as string
    return value;
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
    });
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _inputController.text = clipboardData!.text!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasted from clipboard!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to paste: ${e.toString()}')),
      );
    }
  }

  void _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: ${e.toString()}')),
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
                  child: CheckboxListTile(
                    title: const Text('First row contains headers'),
                    value: _hasHeaders,
                    onChanged: (value) {
                      setState(() {
                        _hasHeaders = value ?? true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _delimiter,
                    decoration: const InputDecoration(
                      labelText: 'Delimiter',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: ',', child: Text('Comma (,)')),
                      DropdownMenuItem(value: ';', child: Text('Semicolon (;)')),
                      DropdownMenuItem(value: '\t', child: Text('Tab')),
                      DropdownMenuItem(value: '|', child: Text('Pipe (|)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _delimiter = value ?? ',';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Input CSV:',
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
                      hintText: 'Paste your CSV data here...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Tooltip(
                        message: 'Paste CSV data from clipboard',
                        child: IconButton(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.paste),
                          iconSize: 20,
                        ),
                      ),
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
                  onPressed: _convertCsvToJson,
                  icon: const Icon(Icons.transform),
                  label: const Text('Convert to JSON'),
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
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_errorMessage.isNotEmpty) const SizedBox(height: 8),
            const Text(
              'JSON Output:',
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
                      hintText: 'Converted JSON will appear here...',
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Tooltip(
                        message: 'Copy JSON output to clipboard',
                        child: IconButton(
                          onPressed: _outputController.text.isNotEmpty ? _copyToClipboard : null,
                          icon: const Icon(Icons.copy),
                          iconSize: 20,
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
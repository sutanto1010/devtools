import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class CsvExplorerScreen extends StatefulWidget {
  const CsvExplorerScreen({super.key});

  @override
  State<CsvExplorerScreen> createState() => _CsvExplorerScreenState();
}

class _CsvExplorerScreenState extends State<CsvExplorerScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _errorMessage = '';
  bool _hasHeaders = true;
  String _delimiter = ',';
  List<List<String>> _csvData = [];
  List<String> _headers = [];
  bool _isDataLoaded = false;
  int _totalRows = 0;
  int _totalColumns = 0;
  String _fileName = '';

  @override
  void initState() {
    super.initState();
  }

  void _parseCsvData() {
    setState(() {
      _errorMessage = '';
      _csvData.clear();
      _headers.clear();
      _isDataLoaded = false;
      _totalRows = 0;
      _totalColumns = 0;
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter CSV data or load a file';
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

      List<List<String>> allRows = lines.map((line) => _parseCsvLine(line)).toList();
      
      if (_hasHeaders && allRows.isNotEmpty) {
        _headers = allRows[0];
        _csvData = allRows.skip(1).toList();
      } else {
        if (allRows.isNotEmpty) {
          _headers = List.generate(allRows[0].length, (index) => 'Column ${index + 1}');
          _csvData = allRows;
        }
      }

      setState(() {
        _isDataLoaded = true;
        _totalRows = _csvData.length;
        _totalColumns = _headers.length;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing CSV: ${e.toString()}';
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
          currentField += '"';
          i++;
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

  void _loadCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        
        setState(() {
          _inputController.text = contents;
          _fileName = result.files.single.name;
        });
        
        _parseCsvData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded file: ${result.files.single.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load file: ${e.toString()}')),
      );
    }
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _inputController.text = clipboardData!.text!;
          _fileName = '';
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

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _csvData.clear();
      _headers.clear();
      _isDataLoaded = false;
      _errorMessage = '';
      _totalRows = 0;
      _totalColumns = 0;
      _fileName = '';
    });
  }

  void _exportToJson() async {
    if (!_isDataLoaded || _csvData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      final jsonList = <Map<String, dynamic>>[];
      
      for (final row in _csvData) {
        final jsonObject = <String, dynamic>{};
        for (int i = 0; i < _headers.length && i < row.length; i++) {
          jsonObject[_headers[i]] = _parseValue(row[i]);
        }
        jsonList.add(jsonObject);
      }

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonList);
      
      await Clipboard.setData(ClipboardData(text: jsonString));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON data copied to clipboard!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: ${e.toString()}')),
      );
    }
  }

  dynamic _parseValue(String value) {
    if (value.isEmpty) return '';
    
    // Try to parse as number
    if (RegExp(r'^-?\d+$').hasMatch(value)) {
      return int.tryParse(value) ?? value;
    }
    if (RegExp(r'^-?\d+\.\d+$').hasMatch(value)) {
      return double.tryParse(value) ?? value;
    }
    
    // Try to parse as boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    
    return value;
  }

  Widget _buildDataTable() {
    if (!_isDataLoaded || _csvData.isEmpty) {
      return const Center(
        child: Text(
          'No data to display. Load a CSV file or paste CSV data above.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return TableView.builder(
      columns: _headers.map((header) => TableColumn(
        width: 150,
      )).toList(),
      rowCount: _csvData.length,
      rowHeight: 48.0,
      rowBuilder: (context, row, contentBuilder) {
        return contentBuilder(
          context,
          (context, column) {
            if (row < _csvData.length && column < _csvData[row].length) {
              final cellValue = _csvData[row][column];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  cellValue,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(''),
            );
          },
        );
      },
      headerBuilder: (context, contentBuilder) {
        return contentBuilder(
          context,
          (context, column) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _headers[column],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Controls Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // File info and controls
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CSV Explorer',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_fileName.isNotEmpty)
                            Text(
                              'File: $_fileName',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          if (_isDataLoaded)
                            Text(
                              '$_totalRows rows × $_totalColumns columns',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadCsvFile,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Load File'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.paste),
                          label: const Text('Paste'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isDataLoaded ? _exportToJson : null,
                          icon: const Icon(Icons.download),
                          label: const Text('Export JSON'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Settings Row
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
                          if (_inputController.text.isNotEmpty) {
                            _parseCsvData();
                          }
                        },
                        dense: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        value: _delimiter,
                        decoration: const InputDecoration(
                          labelText: 'Delimiter',
                          border: OutlineInputBorder(),
                          isDense: true,
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
                          if (_inputController.text.isNotEmpty) {
                            _parseCsvData();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _inputController.text.isNotEmpty ? _parseCsvData : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Parse'),
                    ),
                  ],
                ),
                
                // Input Section (Collapsible)
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('CSV Data Input'),
                  initiallyExpanded: !_isDataLoaded,
                  children: [
                    SizedBox(
                      height: 150,
                      child: TextField(
                        controller: _inputController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Paste your CSV data here or load a file...',
                        ),
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ],
                ),
                
                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
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
              ],
            ),
          ),
          
          // Data Table Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _buildDataTable(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
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
  List<double> _columnWidths = [];
  int? _resizingColumnIndex;
  double? _resizeStartX;
  double? _resizeStartWidth;

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
      _columnWidths = []; // Clear column widths
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
      
      // Find the maximum number of columns across all rows
      int maxColumns = 0;
      for (final row in allRows) {
        if (row.length > maxColumns) {
          maxColumns = row.length;
        }
      }
      
      if (_hasHeaders && allRows.isNotEmpty) {
        List<String> headerRow = allRows[0];
        _csvData = allRows.skip(1).toList();
        
        // If header has fewer columns than max, extend it
        if (headerRow.length < maxColumns) {
          _headers = List<String>.from(headerRow);
          for (int i = headerRow.length; i < maxColumns; i++) {
            _headers.add('Column ${i + 1}');
          }
        } else {
          _headers = headerRow;
        }
      } else {
        if (allRows.isNotEmpty) {
          _headers = List.generate(maxColumns, (index) => 'Column ${index + 1}');
          _csvData = allRows;
        }
      }

      // Normalize all data rows to have the same number of columns
      for (int i = 0; i < _csvData.length; i++) {
        while (_csvData[i].length < maxColumns) {
          _csvData[i].add(''); // Add empty strings for missing columns
        }
      }

      // Initialize column widths
      _columnWidths = List.filled(_headers.length, 150.0);

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
      columns: _headers.asMap().entries.map((entry) {
        final index = entry.key;
        return TableColumn(
          width: _columnWidths[index],
          minResizeWidth: 80.0,
          maxResizeWidth: 400.0,
        );
      }).toList(),
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
            return _buildResizableHeader(column);
          },
        );
      },
    );
  }

  Widget _buildResizableHeader(int column) {
    return Stack(
      children: [
        // Main header content
        Container(
          width: _columnWidths[column],
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1.0,
              ),
            ),
          ),
          child: Text(
            _headers[column],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Resize handle
        Positioned(
          right: -4,
          top: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onPanStart: (details) {
                _resizingColumnIndex = column;
                _resizeStartX = details.globalPosition.dx;
                _resizeStartWidth = _columnWidths[column];
              },
              onPanUpdate: (details) {
                if (_resizingColumnIndex == column && _resizeStartX != null && _resizeStartWidth != null) {
                  final deltaX = details.globalPosition.dx - _resizeStartX!;
                  final newWidth = (_resizeStartWidth! + deltaX).clamp(80.0, 400.0);
                  
                  setState(() {
                    _columnWidths[column] = newWidth;
                  });
                }
              },
              onPanEnd: (details) {
                _resizingColumnIndex = null;
                _resizeStartX = null;
                _resizeStartWidth = null;
              },
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  color: _resizingColumnIndex == column 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.transparent,
                ),
                child: Center(
                  child: Container(
                    width: 2,
                    height: double.infinity,
                    color: _resizingColumnIndex == column 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showColumnControls(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: const Text('Resize Columns'),
          onTap: () {
            _showResizeDialog(context);
          },
        ),
        PopupMenuItem(
          child: const Text('Auto-fit Columns'),
          onTap: () {
            _autoFitColumns();
          },
        ),
        PopupMenuItem(
          child: const Text('Reset Column Widths'),
          onTap: () {
            _resetColumnWidths();
          },
        ),
      ],
    );
  }

  void _showColumnControlsForColumn(BuildContext context, int columnIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resize Column: ${_headers[columnIndex]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current width: ${_columnWidths[columnIndex].toInt()}px'),
            const SizedBox(height: 16),
            Slider(
              value: _columnWidths[columnIndex],
              min: 80.0,
              max: 400.0,
              divisions: 32,
              label: '${_columnWidths[columnIndex].toInt()}px',
              onChanged: (value) {
                setState(() {
                  _columnWidths[columnIndex] = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resize All Columns'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set width for all columns:'),
            const SizedBox(height: 16),
            Slider(
              value: _columnWidths.isNotEmpty ? _columnWidths[0] : 150.0,
              min: 80.0,
              max: 400.0,
              divisions: 32,
              label: '${(_columnWidths.isNotEmpty ? _columnWidths[0] : 150.0).toInt()}px',
              onChanged: (value) {
                setState(() {
                  _columnWidths = List.filled(_columnWidths.length, value);
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _autoFitColumns() {
    if (!_isDataLoaded || _csvData.isEmpty) return;

    setState(() {
      for (int i = 0; i < _headers.length; i++) {
        double maxWidth = _headers[i].length * 8.0 + 32.0; // Header width
        
        // Check data rows for maximum content width
        for (final row in _csvData) {
          if (i < row.length) {
            double contentWidth = row[i].length * 8.0 + 32.0;
            maxWidth = maxWidth > contentWidth ? maxWidth : contentWidth;
          }
        }
        
        // Clamp between min and max resize widths
        _columnWidths[i] = maxWidth.clamp(80.0, 400.0);
      }
    });
  }

  void _resetColumnWidths() {
    setState(() {
      _columnWidths = List.filled(_columnWidths.length, 150.0);
    });
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
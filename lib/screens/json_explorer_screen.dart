import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class JsonExplorerScreen extends StatefulWidget {
  const JsonExplorerScreen({super.key});

  @override
  State<JsonExplorerScreen> createState() => _JsonExplorerScreenState();
}

class _JsonExplorerScreenState extends State<JsonExplorerScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  dynamic _jsonData;
  String _errorMessage = '';
  String _searchQuery = '';
  List<String> _currentPath = [];
  Map<String, bool> _expandedNodes = {};
  Map<String, dynamic> _statistics = {};

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _parseJson() {
    setState(() {
      _errorMessage = '';
      _jsonData = null;
      _statistics = {};
      _expandedNodes.clear();
      _currentPath.clear();
    });

    try {
      final jsonString = _inputController.text.trim();
      if (jsonString.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON data';
        });
        return;
      }

      final parsed = jsonDecode(jsonString);
      setState(() {
        _jsonData = parsed;
        _statistics = _calculateStatistics(parsed);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  Map<String, dynamic> _calculateStatistics(dynamic data) {
    int objects = 0;
    int arrays = 0;
    int strings = 0;
    int numbers = 0;
    int booleans = 0;
    int nulls = 0;
    int totalKeys = 0;
    int maxDepth = 0;

    void analyze(dynamic item, int depth) {
      maxDepth = depth > maxDepth ? depth : maxDepth;
      
      if (item is Map) {
        objects++;
        totalKeys += item.keys.length;
        item.values.forEach((value) => analyze(value, depth + 1));
      } else if (item is List) {
        arrays++;
        item.forEach((value) => analyze(value, depth + 1));
      } else if (item is String) {
        strings++;
      } else if (item is num) {
        numbers++;
      } else if (item is bool) {
        booleans++;
      } else if (item == null) {
        nulls++;
      }
    }

    analyze(data, 0);

    return {
      'objects': objects,
      'arrays': arrays,
      'strings': strings,
      'numbers': numbers,
      'booleans': booleans,
      'nulls': nulls,
      'totalKeys': totalKeys,
      'maxDepth': maxDepth,
    };
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _copyPath() {
    final path = _currentPath.join('.');
    _copyToClipboard(path.isEmpty ? 'root' : path);
  }

  void _copyValue() {
    dynamic value = _jsonData;
    for (String key in _currentPath) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else if (value is List) {
        final index = int.tryParse(key);
        if (index != null && index < value.length) {
          value = value[index];
        }
      }
    }
    _copyToClipboard(jsonEncode(value));
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    labelText: 'Paste JSON data here',
                    border: OutlineInputBorder(),
                    hintText: '{"key": "value", "array": [1, 2, 3]}',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _parseJson,
                        child: const Text('Explore JSON'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _inputController.clear();
                          _jsonData = null;
                          _errorMessage = '';
                          _statistics = {};
                          _expandedNodes.clear();
                          _currentPath.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          
          // Search and Path Section
          if (_jsonData != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search in JSON',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_currentPath.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Path: ${_currentPath.join('.')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: _copyPath,
                              tooltip: 'Copy path',
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_copy, size: 16),
                              onPressed: _copyValue,
                              tooltip: 'Copy value',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Statistics Section
          if (_statistics.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JSON Statistics',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _buildStatChip('Objects', _statistics['objects']),
                          _buildStatChip('Arrays', _statistics['arrays']),
                          _buildStatChip('Strings', _statistics['strings']),
                          _buildStatChip('Numbers', _statistics['numbers']),
                          _buildStatChip('Booleans', _statistics['booleans']),
                          _buildStatChip('Nulls', _statistics['nulls']),
                          _buildStatChip('Keys', _statistics['totalKeys']),
                          _buildStatChip('Max Depth', _statistics['maxDepth']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // JSON Tree View
          if (_jsonData != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: _buildJsonTree(_jsonData, []),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }

  void _expandAllNodes(dynamic data, List<String> path) {
    final pathKey = path.join('.');
    _expandedNodes[pathKey] = true;
    
    if (data is Map) {
      data.forEach((key, value) {
        final newPath = [...path, key.toString()];
        _expandAllNodes(value, newPath);
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        final newPath = [...path, i.toString()];
        _expandAllNodes(data[i], newPath);
      }
    }
  }

  Widget _buildJsonTree(dynamic data, List<String> path) {
    final pathKey = path.join('.');
    final isExpanded = _expandedNodes[pathKey] ?? false;
    
    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path.isNotEmpty)
            _buildNodeHeader(
              '{ } Object (${data.length} ${data.length == 1 ? 'key' : 'keys'})',
              path,
              isExpanded,
              Icons.data_object,
            ),
          if (isExpanded || path.isEmpty)
            Padding(
              padding: EdgeInsets.only(left: path.isEmpty ? 0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries
                    .where((entry) => _matchesSearch(entry.key.toString()) ||
                        _matchesSearch(entry.value.toString()))
                    .map((entry) {
                  final newPath = [...path, entry.key.toString()];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentPath = newPath;
                              });
                            },
                            child: Text(
                              '"${entry.key}":',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                decoration: _currentPath.join('.') == newPath.join('.')
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildJsonTree(entry.value, newPath),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    } else if (data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path.isNotEmpty)
            _buildNodeHeader(
              '[ ] Array (${data.length} ${data.length == 1 ? 'item' : 'items'})',
              path,
              isExpanded,
              Icons.data_array,
            ),
          if (isExpanded || path.isEmpty)
            Padding(
              padding: EdgeInsets.only(left: path.isEmpty ? 0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.asMap().entries
                    .where((entry) => _matchesSearch(entry.value.toString()))
                    .map((entry) {
                  final newPath = [...path, entry.key.toString()];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentPath = newPath;
                              });
                            },
                            child: Text(
                              '[${entry.key}]:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                                decoration: _currentPath.join('.') == newPath.join('.')
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildJsonTree(entry.value, newPath),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentPath = path;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: _currentPath.join('.') == path.join('.')
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              Icon(
                _getValueIcon(data),
                size: 16,
                color: _getValueColor(data),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatValue(data),
                  style: TextStyle(
                    color: _getValueColor(data),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(_formatValue(data)),
                tooltip: 'Copy value',
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNodeHeader(String title, List<String> path, bool isExpanded, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final pathKey = path.join('.');
          _expandedNodes[pathKey] = !isExpanded;
          _currentPath = path;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _currentPath.join('.') == path.join('.')
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 16,
            ),
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getValueIcon(dynamic value) {
    if (value is String) return Icons.text_fields;
    if (value is num) return Icons.numbers;
    if (value is bool) return Icons.check_box;
    if (value == null) return Icons.block;
    return Icons.help;
  }

  Color _getValueColor(dynamic value) {
    if (value is String) return Colors.green;
    if (value is num) return Colors.blue;
    if (value is bool) return Colors.orange;
    if (value == null) return Colors.grey;
    return Colors.black;
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value == null) return 'null';
    return value.toString();
  }
}
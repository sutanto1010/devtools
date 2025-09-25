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
  bool _isFullscreen = false;

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

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _expandAllNodes(dynamic data, List<String> path) {
    setState(() {
      _expandAllNodesRecursive(data, path);
    });
  }

  void _expandAllNodesRecursive(dynamic data, List<String> path) {
    final pathKey = path.join('.');
    _expandedNodes[pathKey] = true;
    
    if (data is Map) {
      data.forEach((key, value) {
        final newPath = [...path, key.toString()];
        _expandAllNodesRecursive(value, newPath);
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        final newPath = [...path, i.toString()];
        _expandAllNodesRecursive(data[i], newPath);
      }
    }
  }

  void _collapseAllNodes() {
    setState(() {
      _expandedNodes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen && _jsonData != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('JSON Tree'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 1,
          actions: [
            // Search field in fullscreen mode
            SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search in JSON...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Expand/Collapse buttons
            IconButton(
              icon: const Icon(Icons.unfold_more),
              onPressed: () => _expandAllNodes(_jsonData, []),
              tooltip: 'Expand All',
            ),
            IconButton(
              icon: const Icon(Icons.unfold_less),
              onPressed: _collapseAllNodes,
              tooltip: 'Collapse All',
            ),
            const SizedBox(width: 8),
            // Exit fullscreen button
            IconButton(
              icon: const Icon(Icons.fullscreen_exit),
              onPressed: _toggleFullscreen,
              tooltip: 'Exit Fullscreen',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Path indicator in fullscreen
            if (_currentPath.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Path: ${_currentPath.join('.')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
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
            // Fullscreen tree view
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                  child: Column(
                    children: [
                      // Tree view header with controls
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'JSON Tree',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.unfold_more, size: 18),
                              onPressed: () => _expandAllNodes(_jsonData, []),
                              tooltip: 'Expand All',
                            ),
                            IconButton(
                              icon: const Icon(Icons.unfold_less, size: 18),
                              onPressed: _collapseAllNodes,
                              tooltip: 'Collapse All',
                            ),
                            IconButton(
                              icon: const Icon(Icons.fullscreen, size: 18),
                              onPressed: _toggleFullscreen,
                              tooltip: 'Fullscreen View',
                            ),
                          ],
                        ),
                      ),
                      // Tree view content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: _buildJsonTree(_jsonData, []),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildJsonTree(dynamic data, List<String> path) {
    final pathKey = path.join('.');
    final isExpanded = _expandedNodes[pathKey] ?? false;
    final depth = path.length;
    
    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path.isNotEmpty)
            _buildNodeHeader(
              'Object',
              '${data.length} ${data.length == 1 ? 'property' : 'properties'}',
              path,
              isExpanded,
              Icons.data_object_outlined,
              Theme.of(context).colorScheme.primary,
            ),
          if (isExpanded || path.isEmpty)
            Container(
              decoration: depth > 0 ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
              ) : null,
              margin: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
              padding: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries
                    .where((entry) => _matchesSearch(entry.key.toString()) ||
                        _matchesSearch(entry.value.toString()))
                    .map((entry) {
                  final newPath = [...path, entry.key.toString()];
                  final isSelected = _currentPath.join('.') == newPath.join('.');
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 1.0),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                          : null,
                      borderRadius: BorderRadius.circular(6.0),
                      border: isSelected ? Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1.0,
                      ) : null,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6.0),
                      onTap: () {
                        setState(() {
                          _currentPath = newPath;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: const BoxConstraints(minWidth: 140),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.key,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '"${entry.key}"',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    ':',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildJsonTree(entry.value, newPath),
                            ),
                          ],
                        ),
                      ),
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
              'Array',
              '${data.length} ${data.length == 1 ? 'item' : 'items'}',
              path,
              isExpanded,
              Icons.data_array_outlined,
              Theme.of(context).colorScheme.secondary,
            ),
          if (isExpanded || path.isEmpty)
            Container(
              decoration: depth > 0 ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
              ) : null,
              margin: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
              padding: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.asMap().entries
                    .where((entry) => _matchesSearch(entry.value.toString()))
                    .map((entry) {
                  final newPath = [...path, entry.key.toString()];
                  final isSelected = _currentPath.join('.') == newPath.join('.');
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 1.0),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5)
                          : null,
                      borderRadius: BorderRadius.circular(6.0),
                      border: isSelected ? Border.all(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        width: 1.0,
                      ) : null,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6.0),
                      onTap: () {
                        setState(() {
                          _currentPath = newPath;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: const BoxConstraints(minWidth: 140),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.looks_one_outlined,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '[${entry.key}]',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    ':',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildJsonTree(entry.value, newPath),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    } else {
      final isSelected = _currentPath.join('.') == path.join('.');
      return Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5)
              : null,
          borderRadius: BorderRadius.circular(6.0),
          border: isSelected ? Border.all(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
            width: 1.0,
          ) : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6.0),
          onTap: () {
            setState(() {
              _currentPath = path;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: _getValueColor(data).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: _getValueColor(data).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getValueIcon(data),
                        size: 12,
                        color: _getValueColor(data),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getValueTypeLabel(data),
                        style: TextStyle(
                          color: _getValueColor(data),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatValue(data),
                    style: TextStyle(
                      color: _getValueColor(data),
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: () => _copyToClipboard(_formatValue(data)),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.copy_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNodeHeader(String type, String count, List<String> path, bool isExpanded, IconData icon, Color color) {
    final isSelected = _currentPath.join('.') == path.join('.');
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected 
            ? color.withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(8.0),
        border: isSelected ? Border.all(
          color: color.withOpacity(0.3),
          width: 1.0,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {
            setState(() {
              final pathKey = path.join('.');
              _expandedNodes[pathKey] = !isExpanded;
              _currentPath = path;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    if (value is String) return const Color(0xFF2E7D32); // Green
    if (value is num) return const Color(0xFF1565C0); // Blue
    if (value is bool) return const Color(0xFFEF6C00); // Orange
    if (value == null) return colorScheme.onSurface.withOpacity(0.6); // Grey
    return colorScheme.onSurface;
  }

  String _getValueTypeLabel(dynamic value) {
    if (value is String) return 'str';
    if (value is int) return 'int';
    if (value is double) return 'num';
    if (value is bool) return 'bool';
    if (value == null) return 'null';
    return 'val';
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value == null) return 'null';
    return value.toString();
  }
}
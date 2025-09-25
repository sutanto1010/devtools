import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlParserScreen extends StatefulWidget {
  const UrlParserScreen({super.key});

  @override
  State<UrlParserScreen> createState() => _UrlParserScreenState();
}

class _UrlParserScreenState extends State<UrlParserScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _parsedUrl;
  String _errorMessage = '';
  String _searchQuery = '';
  List<String> _currentPath = [];
  Map<String, bool> _expandedNodes = {};

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _parseUrl() {
    setState(() {
      _errorMessage = '';
      _parsedUrl = null;
      _expandedNodes.clear();
      _currentPath.clear();
    });

    try {
      final urlString = _inputController.text.trim();
      if (urlString.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a URL';
        });
        return;
      }

      final uri = Uri.parse(urlString);
      final parsed = _buildUrlTree(uri);
      setState(() {
        _parsedUrl = parsed;
        // Expand root nodes by default
        _expandedNodes[''] = true;
        _expandedNodes['components'] = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid URL: ${e.toString()}';
      });
    }
  }

  Map<String, dynamic> _buildUrlTree(Uri uri) {
    final Map<String, dynamic> tree = {
      'original': uri.toString(),
      'components': {
        'scheme': uri.scheme.isNotEmpty ? uri.scheme : null,
        'authority': _buildAuthorityTree(uri),
        'path': _buildPathTree(uri.path),
        'query': _buildQueryTree(uri.queryParameters),
        'fragment': uri.fragment.isNotEmpty ? uri.fragment : null,
      },
      'analysis': {
        'isAbsolute': uri.isAbsolute,
        'hasAuthority': uri.hasAuthority,
        'hasEmptyPath': uri.hasEmptyPath,
        'hasFragment': uri.hasFragment,
        'hasPort': uri.hasPort,
        'hasQuery': uri.hasQuery,
        'hasScheme': uri.hasScheme,
      }
    };

    // Remove null values
    _removeNullValues(tree);
    return tree;
  }

  Map<String, dynamic> _buildAuthorityTree(Uri uri) {
    if (!uri.hasAuthority) return {};
    
    final authority = <String, dynamic>{
      'userInfo': uri.userInfo.isNotEmpty ? uri.userInfo : null,
      'host': uri.host.isNotEmpty ? uri.host : null,
      'port': uri.hasPort ? uri.port : null,
    };
    
    // Add host analysis if host exists
    if (uri.host.isNotEmpty) {
      authority['hostAnalysis'] = {
        'isIPv4': _isIPv4(uri.host),
        'isIPv6': _isIPv6(uri.host),
        'isDomain': !_isIPv4(uri.host) && !_isIPv6(uri.host),
        'parts': uri.host.split('.'),
      };
    }
    
    _removeNullValues(authority);
    return authority;
  }

  Map<String, dynamic> _buildPathTree(String path) {
    if (path.isEmpty || path == '/') {
      return {'segments': [], 'isRoot': true};
    }
    
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return {
      'raw': path,
      'segments': segments,
      'segmentCount': segments.length,
      'isRoot': false,
      'hasTrailingSlash': path.endsWith('/'),
      'hasLeadingSlash': path.startsWith('/'),
    };
  }

  Map<String, dynamic> _buildQueryTree(Map<String, String> queryParams) {
    if (queryParams.isEmpty) return {};
    
    return {
      'parameters': queryParams,
      'parameterCount': queryParams.length,
      'keys': queryParams.keys.toList(),
      'hasEmptyValues': queryParams.values.any((v) => v.isEmpty),
    };
  }

  bool _isIPv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final num = int.tryParse(part);
      return num != null && num >= 0 && num <= 255;
    });
  }

  bool _isIPv6(String host) {
    return host.contains(':') && host.length > 2;
  }

  void _removeNullValues(Map<String, dynamic> map) {
    // First pass: remove null values
    map.removeWhere((key, value) => value == null);
    
    // Second pass: recursively clean nested maps and collect empty ones
    final keysToRemove = <String>[];
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        _removeNullValues(value);
        if (value.isEmpty) {
          keysToRemove.add(key);
        }
      }
    });
    
    // Third pass: remove empty maps
    for (final key in keysToRemove) {
      map.remove(key);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _expandAllNodes(dynamic data, List<String> path) {
    final pathKey = path.join('.');
    _expandedNodes[pathKey] = true;
    
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map || value is List) {
          _expandAllNodes(value, [...path, key.toString()]);
        }
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        if (value is Map || value is List) {
          _expandAllNodes(value, [...path, i.toString()]);
        }
      }
    }
  }

  void _collapseAllNodes() {
    _expandedNodes.clear();
    _expandedNodes[''] = true; // Keep root expanded
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter URL to Parse:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com:8080/path?param=value#fragment',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onSubmitted: (_) => _parseUrl(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _parseUrl,
                          child: const Text('Parse URL'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _inputController.clear();
                              _parsedUrl = null;
                              _errorMessage = '';
                              _expandedNodes.clear();
                              _currentPath.clear();
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Search section
            if (_parsedUrl != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search in parsed URL...',
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
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Results section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildResultsSection(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_parsedUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Enter a URL above to see its parsed structure',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: _buildTreeWidget(_parsedUrl!, []),
    );
  }

  Widget _buildTreeWidget(dynamic data, List<String> path) {
    final pathKey = path.join('.');
    final isExpanded = _expandedNodes[pathKey] ?? false;

    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path.isNotEmpty)
            _buildNodeHeader(
              '{ } Object (${data.length} ${data.length == 1 ? 'property' : 'properties'})',
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
                          child: _buildTreeWidget(entry.value, newPath),
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
                          child: _buildTreeWidget(entry.value, newPath),
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
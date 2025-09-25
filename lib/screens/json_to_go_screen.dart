import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class JsonToGoScreen extends StatefulWidget {
  const JsonToGoScreen({super.key});

  @override
  State<JsonToGoScreen> createState() => _JsonToGoScreenState();
}

class _JsonToGoScreenState extends State<JsonToGoScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _structNameController = TextEditingController(text: 'MyStruct');
  final TextEditingController _packageNameController = TextEditingController(text: 'main');
  String _errorMessage = '';
  bool _useJsonTags = true;
  bool _useOmitEmpty = true;
  bool _usePointers = false;
  bool _generatePackage = true;
  bool _generateImports = true;
  bool _useSnakeCase = false;
  bool _generateComments = true;
  bool _generateValidation = false;

  @override
  void initState() {
    super.initState();
  }

  String _convertJsonToGoStruct(dynamic json, String structName, {int depth = 0}) {
    if (json is! Map<String, dynamic>) {
      throw Exception('Root JSON must be an object');
    }

    final buffer = StringBuffer();
    final indent = '  ' * depth;
    
    if (_generateComments && depth == 0) {
      buffer.writeln('${indent}// $structName represents the JSON structure');
    }
    
    buffer.writeln('${indent}type $structName struct {');
    
    final Map<String, String> nestedStructs = {};
    
    json.forEach((key, value) {
      final fieldName = _convertToGoFieldName(key);
      final goType = _getGoType(value, fieldName, nestedStructs, depth + 1);
      
      buffer.write('$indent  $fieldName $goType');
      
      if (_useJsonTags) {
        String jsonTag = '`json:"$key';
        if (_useOmitEmpty && !_isRequiredField(value)) {
          jsonTag += ',omitempty';
        }
        jsonTag += '"`';
        buffer.write(' $jsonTag');
      }
      
      if (_generateValidation) {
        final validation = _getValidationTag(value);
        if (validation.isNotEmpty) {
          buffer.write(' $validation');
        }
      }
      
      if (_generateComments) {
        final comment = _generateFieldComment(key, value);
        if (comment.isNotEmpty) {
          buffer.write(' // $comment');
        }
      }
      
      buffer.writeln();
    });
    
    buffer.writeln('$indent}');
    
    // Add nested structs
    nestedStructs.forEach((structName, structDef) {
      buffer.writeln();
      buffer.write(structDef);
    });
    
    return buffer.toString();
  }

  String _convertToGoFieldName(String jsonKey) {
    if (_useSnakeCase) {
      return _snakeToCamelCase(jsonKey);
    }
    
    // Convert to PascalCase for Go public fields
    return jsonKey.split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join('');
  }

  String _snakeToCamelCase(String snake) {
    final parts = snake.split('_');
    if (parts.isEmpty) return snake;
    
    return parts[0].toLowerCase() + 
           parts.skip(1).map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1).toLowerCase()).join('');
  }

  String _getGoType(dynamic value, String fieldName, Map<String, String> nestedStructs, int depth) {
    String baseType;
    
    if (value == null) {
      baseType = 'interface{}';
    } else if (value is bool) {
      baseType = 'bool';
    } else if (value is int) {
      baseType = 'int';
    } else if (value is double) {
      baseType = 'float64';
    } else if (value is String) {
      // Try to detect special string types
      if (_isDateString(value)) {
        baseType = 'time.Time';
      } else if (_isUUIDString(value)) {
        baseType = 'string'; // Could be uuid.UUID if using uuid package
      } else {
        baseType = 'string';
      }
    } else if (value is List) {
      if (value.isEmpty) {
        baseType = '[]interface{}';
      } else {
        final elementType = _getGoType(value.first, fieldName, nestedStructs, depth);
        baseType = '[]$elementType';
      }
    } else if (value is Map<String, dynamic>) {
      final nestedStructName = '${fieldName}Struct';
      final nestedStruct = _convertJsonToGoStruct(value, nestedStructName, depth: depth);
      nestedStructs[nestedStructName] = nestedStruct;
      baseType = nestedStructName;
    } else {
      baseType = 'interface{}';
    }
    
    // Add pointer if requested and type is not already a pointer or slice
    if (_usePointers && !baseType.startsWith('[]') && !baseType.startsWith('*')) {
      baseType = '*$baseType';
    }
    
    return baseType;
  }

  bool _isRequiredField(dynamic value) {
    // Consider null values as optional
    return value != null;
  }

  bool _isDateString(String value) {
    // Simple date detection patterns
    final datePatterns = [
      RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'),  // ISO 8601
      RegExp(r'^\d{4}-\d{2}-\d{2}'),                      // Date only
      RegExp(r'^\d{2}/\d{2}/\d{4}'),                      // MM/DD/YYYY
    ];
    
    return datePatterns.any((pattern) => pattern.hasMatch(value));
  }

  bool _isUUIDString(String value) {
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidPattern.hasMatch(value);
  }

  String _getValidationTag(dynamic value) {
    if (!_generateValidation) return '';
    
    final validations = <String>[];
    
    if (value is String) {
      if (value.isNotEmpty) {
        validations.add('required');
      }
      if (value.length > 100) {
        validations.add('max=255');
      }
    } else if (value is int || value is double) {
      if (value > 0) {
        validations.add('min=0');
      }
    }
    
    if (validations.isNotEmpty) {
      return '`validate:"${validations.join(',')}"`';
    }
    
    return '';
  }

  String _generateFieldComment(String key, dynamic value) {
    if (!_generateComments) return '';
    
    if (value is String && _isDateString(value)) {
      return 'Date/time field';
    } else if (value is String && _isUUIDString(value)) {
      return 'UUID field';
    } else if (value is List) {
      return 'Array of ${value.isNotEmpty ? value.first.runtimeType.toString().toLowerCase() : 'items'}';
    } else if (value is Map) {
      return 'Nested object';
    }
    
    return '';
  }

  void _convertJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON to convert';
        });
        return;
      }

      final jsonObject = jsonDecode(input);
      final structName = _structNameController.text.trim().isEmpty 
          ? 'MyStruct' 
          : _structNameController.text.trim();
      
      final buffer = StringBuffer();
      
      // Add package declaration
      if (_generatePackage) {
        final packageName = _packageNameController.text.trim().isEmpty 
            ? 'main' 
            : _packageNameController.text.trim();
        buffer.writeln('package $packageName');
        buffer.writeln();
      }
      
      // Add imports
      if (_generateImports) {
        final imports = <String>[];
        
        // Check if we need time package
        if (_needsTimePackage(jsonObject)) {
          imports.add('"time"');
        }
        
        // Check if we need validation package
        if (_generateValidation) {
          imports.add('"github.com/go-playground/validator/v10"');
        }
        
        if (imports.isNotEmpty) {
          if (imports.length == 1) {
            buffer.writeln('import ${imports.first}');
          } else {
            buffer.writeln('import (');
            for (final import in imports) {
              buffer.writeln('  $import');
            }
            buffer.writeln(')');
          }
          buffer.writeln();
        }
      }
      
      final goStruct = _convertJsonToGoStruct(jsonObject, structName);
      buffer.write(goStruct);
      
      setState(() {
        _outputController.text = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  bool _needsTimePackage(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json.values.any((value) {
        if (value is String && _isDateString(value)) {
          return true;
        } else if (value is Map<String, dynamic>) {
          return _needsTimePackage(value);
        } else if (value is List) {
          return value.any((item) => _needsTimePackage(item));
        }
        return false;
      });
    } else if (json is List) {
      return json.any((item) => _needsTimePackage(item));
    }
    return false;
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
    });
  }

  void _copyToClipboard() async {
    final output = _outputController.text;
    if (output.isEmpty) {
      setState(() {
        _errorMessage = 'No Go struct to copy';
      });
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: output));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Go struct copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to copy to clipboard';
      });
    }
  }

  void _loadSampleJson() {
    const sampleJson = '''{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "email": "john.doe@example.com",
  "age": 30,
  "is_active": true,
  "created_at": "2023-12-01T10:30:00Z",
  "profile": {
    "bio": "Software developer",
    "location": "San Francisco",
    "website": "https://johndoe.dev"
  },
  "skills": ["Go", "Python", "JavaScript"],
  "projects": [
    {
      "name": "Project A",
      "status": "completed",
      "start_date": "2023-01-15"
    },
    {
      "name": "Project B", 
      "status": "in_progress",
      "start_date": "2023-06-01"
    }
  ],
  "metadata": {
    "version": 1,
    "last_updated": "2023-12-01T15:45:30Z"
  }
}''';
    
    setState(() {
      _inputController.text = sampleJson;
      _errorMessage = '';
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hintText,
        contentPadding: const EdgeInsets.all(12),
      ),
      style: const TextStyle(
        fontFamily: 'SF Mono, Monaco, Inconsolata, Roboto Mono, Consolas, Courier New, monospace',
        fontSize: 14,
      ),
    );
  }

  Widget _buildExpandedTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        readOnly: readOnly,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hintText,
          contentPadding: const EdgeInsets.all(12),
        ),
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          fontFamily: 'SF Mono, Monaco, Inconsolata, Roboto Mono, Consolas, Courier New, monospace',
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side - Input and Configuration
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Input JSON:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 3,
                    child: _buildExpandedTextField(
                      controller: _inputController,
                      hintText: 'Paste your JSON here...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _structNameController,
                                  hintText: 'Struct name',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  controller: _packageNameController,
                                  hintText: 'Package name',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildCheckbox('JSON tags', _useJsonTags, (value) {
                                setState(() => _useJsonTags = value!);
                              }),
                              _buildCheckbox('Omitempty', _useOmitEmpty, (value) {
                                setState(() => _useOmitEmpty = value!);
                              }),
                              _buildCheckbox('Use pointers', _usePointers, (value) {
                                setState(() => _usePointers = value!);
                              }),
                              _buildCheckbox('Generate package', _generatePackage, (value) {
                                setState(() => _generatePackage = value!);
                              }),
                              _buildCheckbox('Generate imports', _generateImports, (value) {
                                setState(() => _generateImports = value!);
                              }),
                              _buildCheckbox('Snake case fields', _useSnakeCase, (value) {
                                setState(() => _useSnakeCase = value!);
                              }),
                              _buildCheckbox('Generate comments', _generateComments, (value) {
                                setState(() => _generateComments = value!);
                              }),
                              _buildCheckbox('Validation tags', _generateValidation, (value) {
                                setState(() => _generateValidation = value!);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Center - Buttons and Error
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _convertJson,
                  icon: const Icon(Icons.transform),
                  label: const Text('Convert'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loadSampleJson,
                  icon: const Icon(Icons.code),
                  label: const Text('Sample'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            // Right side - Output
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Go Struct Output:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildExpandedTextField(
                    controller: _outputController,
                    hintText: 'Go struct will appear here...',
                    readOnly: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return SizedBox(
      width: 140,
      child: CheckboxListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _structNameController.dispose();
    _packageNameController.dispose();
    super.dispose();
  }
}
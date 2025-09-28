class TextTypeDetector {
  static String detectTextType(String text) {
    if (text.isEmpty) return 'empty';
    
    String trimmedText = text.trim();
    
    // JSON Detection
    if (_isJson(trimmedText)) return 'json';
    
    // XML Detection
    if (_isXml(trimmedText)) return 'xml';
    // CSV Detection
    if (_isCsv(trimmedText)) return 'csv';
    // YAML Detection
    if (_isYaml(trimmedText)) return 'yaml';
    
    // Base64 Detection
    if (_isBase64(trimmedText)) return 'base64';
    
    // JWT Detection
    if (_isJwt(trimmedText)) return 'jwt';
  
    
    // URL Detection
    if (_isUrl(trimmedText)) return 'url';
    
    // Hex Detection
    if (_isHex(trimmedText)) return 'hex';
    
    // UUID Detection
    if (_isUuid(trimmedText)) return 'uuid';
    
    // Unix Timestamp Detection
    if (_isUnixTimestamp(trimmedText)) return 'unix_timestamp';
    
    // Cron Expression Detection
    if (_isCronExpression(trimmedText)) return 'cron';
    
    // HTML Detection
    if (_isHtml(trimmedText)) return 'html';
    
    // Hash Detection (MD5, SHA1, SHA256, etc.)
    if (_isHash(trimmedText)) return 'hash';
    
    // Color Code Detection (Hex colors)
    if (_isColorCode(trimmedText)) return 'color';
    
    // Basic Auth Detection
    if (_isBasicAuth(trimmedText)) return 'basic_auth';
    
    // GPG/PGP Key Detection
    if (_isGpgKey(trimmedText)) return 'gpg';
    
    return 'unknown';
  }

  static bool _isJson(String text) {
    try {
      if ((text.startsWith('{') && text.endsWith('}')) ||
          (text.startsWith('[') && text.endsWith(']'))) {
        // Simple validation - could use dart:convert for more thorough checking
        int braceCount = 0;
        int bracketCount = 0;
        bool inString = false;
        bool escaped = false;
        
        for (int i = 0; i < text.length; i++) {
          String char = text[i];
          
          if (escaped) {
            escaped = false;
            continue;
          }
          
          if (char == '\\') {
            escaped = true;
            continue;
          }
          
          if (char == '"' && !escaped) {
            inString = !inString;
            continue;
          }
          
          if (!inString) {
            if (char == '{') braceCount++;
            if (char == '}') braceCount--;
            if (char == '[') bracketCount++;
            if (char == ']') bracketCount--;
          }
        }
        
        return braceCount == 0 && bracketCount == 0;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  static bool _isXml(String text) {
    return text.trim().startsWith('<') && 
           text.trim().endsWith('>') &&
           text.contains('</') &&
           !text.toLowerCase().contains('<!doctype html');
  }

  static bool _isYaml(String text) {
    // Basic YAML detection
    List<String> lines = text.split('\n');
    if (lines.length < 2) return false;
    
    // Check for YAML indicators
    bool hasYamlStructure = false;
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      // Check for key-value pairs with colon
      if (trimmed.contains(':') && !trimmed.startsWith('-')) {
        hasYamlStructure = true;
      }
      // Check for list items
      if (trimmed.startsWith('- ')) {
        hasYamlStructure = true;
      }
    }
    
    return hasYamlStructure && !_isJson(text);
  }

  static bool _isBase64(String text) {
    if (text.length < 4 || text.length % 4 != 0) return false;
    
    RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64Regex.hasMatch(text) && text.length > 20;
  }

  static bool _isJwt(String text) {
    List<String> parts = text.split('.');
    return parts.length == 3 && 
           parts.every((part) => RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part));
  }

  static bool _isCsv(String text) {
    List<String> lines = text.split('\n');
    if (lines.length < 2) return false;

    // Common CSV delimiters: comma, semicolon, tab, pipe
    List<String> delimiters = [',', ';', '\t', '|'];
    String? detectedDelimiter;
    int? expectedColumns;
    int validLines = 0;

    // Try each delimiter to find the most consistent one
    for (String delimiter in delimiters) {
      int currentValidLines = 0;
      int? currentExpectedColumns;

      for (String line in lines) {
        if (line.trim().isEmpty) continue;

        int columns = line.split(delimiter).length;
        if (currentExpectedColumns == null) {
          currentExpectedColumns = columns;
        } else if (columns == currentExpectedColumns) {
          currentValidLines++;
        }
      }

      // Prefer the delimiter with the most valid lines and more than 1 column
      if (currentValidLines >= validLines &&
          currentExpectedColumns != null &&
          currentExpectedColumns > 1) {
        validLines = currentValidLines;
        expectedColumns = currentExpectedColumns;
        detectedDelimiter = delimiter;
      }
    }

    return validLines >= 2 && expectedColumns != null && expectedColumns > 1;
  }

  static bool _isUrl(String text) {
    RegExp urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    return urlRegex.hasMatch(text.trim());
  }

  static bool _isHex(String text) {
    String cleaned = text.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
    return cleaned.length == text.replaceAll(' ', '').length && 
           cleaned.length > 6 && 
           cleaned.length % 2 == 0;
  }

  static bool _isUuid(String text) {
    RegExp uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(text.trim());
  }

  static bool _isUnixTimestamp(String text) {
    String trimmed = text.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return false;
    
    int? timestamp = int.tryParse(trimmed);
    if (timestamp == null) return false;
    
    // Check if it's a reasonable timestamp (between 1970 and 2050)
    return timestamp > 0 && timestamp < 2524608000; // Jan 1, 2050
  }

  static bool _isCronExpression(String text) {
    List<String> parts = text.trim().split(' ');
    return parts.length == 5 || parts.length == 6; // Standard or with seconds
  }

  static bool _isHtml(String text) {
    String lower = text.toLowerCase().trim();
    return (lower.startsWith('<!doctype html') || 
            lower.startsWith('<html')) && 
           lower.contains('</html>');
  }

  static bool _isHash(String text) {
    String trimmed = text.trim();
    RegExp hexOnly = RegExp(r'^[a-fA-F0-9]+$');
    
    if (!hexOnly.hasMatch(trimmed)) return false;
    
    // Common hash lengths
    List<int> hashLengths = [32, 40, 56, 64, 96, 128]; // MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    return hashLengths.contains(trimmed.length);
  }

  static bool _isColorCode(String text) {
    String trimmed = text.trim();
    RegExp colorRegex = RegExp(r'^#[a-fA-F0-9]{3}$|^#[a-fA-F0-9]{6}$|^#[a-fA-F0-9]{8}$');
    return colorRegex.hasMatch(trimmed);
  }

  static bool _isBasicAuth(String text) {
    return text.trim().toLowerCase().startsWith('basic ') && 
           text.length > 10;
  }

  static bool _isGpgKey(String text) {
    return text.contains('-----BEGIN PGP') || 
           text.contains('-----BEGIN GPG') ||
           text.contains('-----BEGIN RSA');
  }

  /// Maps detected text types to relevant tool IDs
  static String? getRelevantToolId(String detectedType) {
    Map<String, String> typeToTool = {
      'json': 'json_formatter',
      'xml': 'xml_formatter',
      'yaml': 'yaml_formatter',
      'base64': 'base64_encoder',
      'jwt': 'jwt_decoder',
      'csv': 'csv_to_json',
      'url': 'url_parser',
      'hex': 'hex_to_ascii',
      'uuid': 'uuid_generator',
      'unix_timestamp': 'unix_time_converter',
      'cron': 'cron_expression',
      'html': 'html_viewer',
      'hash': 'hash_generator',
      'color': 'color_picker',
      'basic_auth': 'basic_auth_generator',
      'gpg': 'gpg_tool',
    };

    return typeToTool[detectedType];
  }

  /// Gets a human-readable description of the detected type
  static String getTypeDescription(String detectedType) {
    Map<String, String> typeDescriptions = {
      'json': 'JSON data',
      'xml': 'XML document',
      'yaml': 'YAML configuration',
      'base64': 'Base64 encoded data',
      'jwt': 'JSON Web Token',
      'csv': 'CSV data',
      'url': 'Web URL',
      'hex': 'Hexadecimal data',
      'uuid': 'UUID identifier',
      'unix_timestamp': 'Unix timestamp',
      'cron': 'Cron expression',
      'html': 'HTML document',
      'hash': 'Hash value',
      'color': 'Color code',
      'basic_auth': 'Basic authentication',
      'gpg': 'GPG/PGP key',
      'empty': 'Empty content',
      'unknown': 'Unknown format',
    };

    return typeDescriptions[detectedType] ?? 'Unknown format';
  }
}
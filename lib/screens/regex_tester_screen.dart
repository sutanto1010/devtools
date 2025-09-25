import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegexTesterScreen extends StatefulWidget {
  const RegexTesterScreen({super.key});

  @override
  State<RegexTesterScreen> createState() => _RegexTesterScreenState();
}

class _RegexTesterScreenState extends State<RegexTesterScreen> {
  final TextEditingController _patternController = TextEditingController();
  final TextEditingController _testStringController = TextEditingController();
  final TextEditingController _replacementController = TextEditingController();
  
  List<RegExpMatch> _matches = [];
  String _replacementResult = '';
  String _errorMessage = '';
  bool _caseSensitive = true;
  bool _multiLine = false;
  bool _dotAll = false;
  bool _unicode = false;
  
  final List<Map<String, String>> _commonPatterns = [
    {'name': 'Email', 'pattern': r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'},
    {'name': 'Phone (US)', 'pattern': r'^\+?1?[-.\s]?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})$'},
    {'name': 'URL', 'pattern': r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'},
    {'name': 'IPv4 Address', 'pattern': r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'},
    {'name': 'Date (YYYY-MM-DD)', 'pattern': r'^\d{4}-\d{2}-\d{2}$'},
    {'name': 'Time (HH:MM)', 'pattern': r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$'},
    {'name': 'Credit Card', 'pattern': r'^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3[0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})$'},
    {'name': 'Hex Color', 'pattern': r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$'},
    {'name': 'Username', 'pattern': r'^[a-zA-Z0-9_]{3,16}$'},
    {'name': 'Password (Strong)', 'pattern': r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'},
  ];

  @override
  void dispose() {
    _patternController.dispose();
    _testStringController.dispose();
    _replacementController.dispose();
    super.dispose();
  }

  void _testRegex() {
    setState(() {
      _matches.clear();
      _errorMessage = '';
      _replacementResult = '';
    });

    if (_patternController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a regex pattern';
      });
      return;
    }

    try {
      final pattern = RegExp(
        _patternController.text,
        caseSensitive: _caseSensitive,
        multiLine: _multiLine,
        dotAll: _dotAll,
        unicode: _unicode,
      );

      final testString = _testStringController.text;
      _matches = pattern.allMatches(testString).toList();

      // Generate replacement result if replacement text is provided
      if (_replacementController.text.isNotEmpty) {
        _replacementResult = testString.replaceAll(pattern, _replacementController.text);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid regex pattern: ${e.toString()}';
      });
    }

    setState(() {});
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _useCommonPattern(String pattern) {
    _patternController.text = pattern;
    _testRegex();
  }

  Widget _buildHighlightedText() {
    if (_testStringController.text.isEmpty || _matches.isEmpty) {
      return Text(
        _testStringController.text.isEmpty ? 'Enter test string above' : _testStringController.text,
        style: const TextStyle(fontFamily: 'monospace'),
      );
    }

    final text = _testStringController.text;
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in _matches) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(fontFamily: 'monospace'),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontFamily: 'monospace'),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Regex Pattern Input
            TextField(
              controller: _patternController,
              decoration: InputDecoration(
                labelText: 'Regex Pattern',
                hintText: 'Enter your regular expression',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () => _copyToClipboard(_patternController.text),
                ),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => _testRegex(),
            ),
            const SizedBox(height: 8),
            
            // Regex Flags
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Case Sensitive'),
                  selected: _caseSensitive,
                  onSelected: (selected) {
                    setState(() {
                      _caseSensitive = selected;
                    });
                    _testRegex();
                  },
                ),
                FilterChip(
                  label: const Text('Multi-line'),
                  selected: _multiLine,
                  onSelected: (selected) {
                    setState(() {
                      _multiLine = selected;
                    });
                    _testRegex();
                  },
                ),
                FilterChip(
                  label: const Text('Dot All'),
                  selected: _dotAll,
                  onSelected: (selected) {
                    setState(() {
                      _dotAll = selected;
                    });
                    _testRegex();
                  },
                ),
                FilterChip(
                  label: const Text('Unicode'),
                  selected: _unicode,
                  onSelected: (selected) {
                    setState(() {
                      _unicode = selected;
                    });
                    _testRegex();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test String Input
            TextField(
              controller: _testStringController,
              decoration: const InputDecoration(
                labelText: 'Test String',
                hintText: 'Enter text to test against the regex',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => _testRegex(),
            ),
            const SizedBox(height: 16),
            
            // Replacement Input
            TextField(
              controller: _replacementController,
              decoration: const InputDecoration(
                labelText: 'Replacement Text (Optional)',
                hintText: 'Text to replace matches with',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => _testRegex(),
            ),
            const SizedBox(height: 16),
            
            // Common Patterns
            ExpansionTile(
              title: const Text('Common Patterns'),
              children: [
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: _commonPatterns.length,
                    itemBuilder: (context, index) {
                      final pattern = _commonPatterns[index];
                      return ListTile(
                        title: Text(pattern['name']!),
                        subtitle: Text(
                          pattern['pattern']!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _useCommonPattern(pattern['pattern']!),
                        trailing: IconButton(
                          icon: const Icon(Icons.content_copy),
                          onPressed: () => _copyToClipboard(pattern['pattern']!),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Results Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error Message
                    if (_errorMessage.isNotEmpty)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Match Results
                    if (_errorMessage.isEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _matches.isNotEmpty ? Icons.check_circle : Icons.cancel,
                                    color: _matches.isNotEmpty ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_matches.length} match${_matches.length != 1 ? 'es' : ''} found',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Highlighted Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.shade50,
                                ),
                                child: _buildHighlightedText(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Match Details
                      if (_matches.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Match Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...List.generate(_matches.length, (index) {
                                  final match = _matches[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('Match ${index + 1}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              const Spacer(),
                                              IconButton(
                                                icon: const Icon(Icons.content_copy),
                                                onPressed: () => _copyToClipboard(match.group(0) ?? ''),
                                              ),
                                            ],
                                          ),
                                          Text('Text: "${match.group(0)}"', style: const TextStyle(fontFamily: 'monospace')),
                                          Text('Position: ${match.start}-${match.end}'),
                                          if (match.groupCount > 0) ...[
                                            const SizedBox(height: 4),
                                            const Text('Groups:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ...List.generate(match.groupCount, (groupIndex) {
                                              final groupNum = groupIndex + 1;
                                              final groupValue = match.group(groupNum);
                                              return Text(
                                                'Group $groupNum: "${groupValue ?? 'null'}"',
                                                style: const TextStyle(fontFamily: 'monospace'),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      
                      // Replacement Result
                      if (_replacementResult.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Replacement Result:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.content_copy),
                                      onPressed: () => _copyToClipboard(_replacementResult),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Text(
                                    _replacementResult,
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
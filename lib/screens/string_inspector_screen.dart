import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StringInspectorScreen extends StatefulWidget {
  const StringInspectorScreen({super.key});

  @override
  State<StringInspectorScreen> createState() => _StringInspectorScreenState();
}

class _StringInspectorScreenState extends State<StringInspectorScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _inputText = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        _inputController.text = clipboardData.text!;
        setState(() {
          _inputText = clipboardData.text!;
        });
      }
    } catch (e) {
      // Handle clipboard access errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access clipboard')),
        );
      }
    }
  }

  Map<String, dynamic> _analyzeString(String text) {
    if (text.isEmpty) {
      return {
        'length': 0,
        'characters': 0,
        'words': 0,
        'lines': 0,
        'paragraphs': 0,
        'bytes': 0,
        'whitespace': 0,
        'alphanumeric': 0,
        'uppercase': 0,
        'lowercase': 0,
        'digits': 0,
        'special': 0,
        'encoding': 'UTF-8',
        'hasEmoji': false,
        'uniqueChars': 0,
      };
    }

    final bytes = text.codeUnits.length;
    final lines = text.split('\n').length;
    final paragraphs = text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    int whitespace = 0;
    int alphanumeric = 0;
    int uppercase = 0;
    int lowercase = 0;
    int digits = 0;
    int special = 0;
    
    final uniqueChars = <String>{};
    bool hasEmoji = false;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      uniqueChars.add(char);
      
      if (char.codeUnitAt(0) > 127) {
        // Check for emoji (simplified check)
        final code = char.codeUnitAt(0);
        if (code >= 0x1F600 && code <= 0x1F64F || // Emoticons
            code >= 0x1F300 && code <= 0x1F5FF || // Misc Symbols
            code >= 0x1F680 && code <= 0x1F6FF || // Transport
            code >= 0x2600 && code <= 0x26FF ||   // Misc symbols
            code >= 0x2700 && code <= 0x27BF) {   // Dingbats
          hasEmoji = true;
        }
      }
      
      if (RegExp(r'\s').hasMatch(char)) {
        whitespace++;
      } else if (RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
        alphanumeric++;
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          uppercase++;
        } else if (RegExp(r'[a-z]').hasMatch(char)) {
          lowercase++;
        } else if (RegExp(r'[0-9]').hasMatch(char)) {
          digits++;
        }
      } else {
        special++;
      }
    }

    return {
      'length': text.length,
      'characters': text.length,
      'words': words,
      'lines': lines,
      'paragraphs': paragraphs,
      'bytes': bytes,
      'whitespace': whitespace,
      'alphanumeric': alphanumeric,
      'uppercase': uppercase,
      'lowercase': lowercase,
      'digits': digits,
      'special': special,
      'encoding': 'UTF-8',
      'hasEmoji': hasEmoji,
      'uniqueChars': uniqueChars.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analyzeString(_inputText);
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Text',
              style: Theme.of(context).textTheme.titleLarge,
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
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Enter or paste text to analyze...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _inputText = value;
                      });
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.content_paste, size: 18),
                            onPressed: _pasteFromClipboard,
                            tooltip: 'Paste from clipboard',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: _inputText.isNotEmpty ? () => _copyToClipboard(_inputText) : null,
                            tooltip: 'Copy text',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
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
            Row(
              children: [
                Text(
                  'Analysis Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    _inputController.clear();
                    setState(() {
                      _inputText = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildAnalysisSection('Basic Statistics', [
                          _buildAnalysisRow('Length (characters)', analysis['length'].toString()),
                          _buildAnalysisRow('Words', analysis['words'].toString()),
                          _buildAnalysisRow('Lines', analysis['lines'].toString()),
                          _buildAnalysisRow('Paragraphs', analysis['paragraphs'].toString()),
                          _buildAnalysisRow('Bytes (UTF-8)', analysis['bytes'].toString()),
                        ]),
                        const Divider(),
                        _buildAnalysisSection('Character Analysis', [
                          _buildAnalysisRow('Unique characters', analysis['uniqueChars'].toString()),
                          _buildAnalysisRow('Whitespace characters', analysis['whitespace'].toString()),
                          _buildAnalysisRow('Alphanumeric characters', analysis['alphanumeric'].toString()),
                          _buildAnalysisRow('Uppercase letters', analysis['uppercase'].toString()),
                          _buildAnalysisRow('Lowercase letters', analysis['lowercase'].toString()),
                          _buildAnalysisRow('Digits', analysis['digits'].toString()),
                          _buildAnalysisRow('Special characters', analysis['special'].toString()),
                        ]),
                        const Divider(),
                        _buildAnalysisSection('Encoding & Format', [
                          _buildAnalysisRow('Text encoding', analysis['encoding']),
                          _buildAnalysisRow('Contains emoji', analysis['hasEmoji'] ? 'Yes' : 'No'),
                        ]),
                        if (_inputText.isNotEmpty) ...[
                          const Divider(),
                          _buildAnalysisSection('Text Transformations', [
                            _buildTransformationRow('Uppercase', _inputText.toUpperCase()),
                            _buildTransformationRow('Lowercase', _inputText.toLowerCase()),
                            _buildTransformationRow('Title Case', _toTitleCase(_inputText)),
                            _buildTransformationRow('Reversed', _inputText.split('').reversed.join()),
                            _buildTransformationRow('Trimmed', _inputText.trim()),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Flexible(
                child: SelectableText(
                  value.length > 30 ? '${value.substring(0, 30)}...' : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(value),
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
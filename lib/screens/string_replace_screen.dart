import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StringReplaceScreen extends StatefulWidget {
  const StringReplaceScreen({super.key});

  @override
  State<StringReplaceScreen> createState() => _StringReplaceScreenState();
}

class _StringReplaceScreenState extends State<StringReplaceScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  
  String _inputText = '';
  String _outputText = '';
  bool _caseSensitive = false;
  bool _useRegex = false;
  bool _wholeWords = false;
  bool _multiline = false;
  int _matchCount = 0;
  List<String> _replaceHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      setState(() {
        _inputText = _inputController.text;
        _performReplace();
      });
    });
    _findController.addListener(() {
      _performReplace();
    });
    _replaceController.addListener(() {
      _performReplace();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _performReplace() {
    setState(() {
      _errorMessage = null;
      
      if (_inputText.isEmpty || _findController.text.isEmpty) {
        _outputText = _inputText;
        _matchCount = 0;
        _outputController.text = _outputText;
        return;
      }

      try {
        String findPattern = _findController.text;
        String replaceWith = _replaceController.text;
        
        if (_useRegex) {
          RegExp regex;
          if (_caseSensitive) {
            regex = RegExp(findPattern, multiLine: _multiline);
          } else {
            regex = RegExp(findPattern, caseSensitive: false, multiLine: _multiline);
          }
          
          _matchCount = regex.allMatches(_inputText).length;
          _outputText = _inputText.replaceAll(regex, replaceWith);
        } else {
          if (_wholeWords) {
            String pattern = r'\b' + RegExp.escape(findPattern) + r'\b';
            RegExp regex = RegExp(pattern, 
              caseSensitive: _caseSensitive, 
              multiLine: _multiline
            );
            _matchCount = regex.allMatches(_inputText).length;
            _outputText = _inputText.replaceAll(regex, replaceWith);
          } else {
            if (_caseSensitive) {
              _matchCount = findPattern.allMatches(_inputText).length;
              _outputText = _inputText.replaceAll(findPattern, replaceWith);
            } else {
              RegExp regex = RegExp(RegExp.escape(findPattern), caseSensitive: false);
              _matchCount = regex.allMatches(_inputText).length;
              _outputText = _inputText.replaceAll(regex, replaceWith);
            }
          }
        }
        
        _outputController.text = _outputText;
      } catch (e) {
        _errorMessage = 'Invalid regex pattern: ${e.toString()}';
        _outputText = _inputText;
        _matchCount = 0;
        _outputController.text = _outputText;
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      _inputController.text = clipboardData!.text!;
    }
  }

  void _clearAll() {
    _inputController.clear();
    _findController.clear();
    _replaceController.clear();
    _outputController.clear();
    setState(() {
      _inputText = '';
      _outputText = '';
      _matchCount = 0;
      _errorMessage = null;
    });
  }

  void _swapInputOutput() {
    final temp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = temp;
  }

  void _addToHistory() {
    if (_findController.text.isNotEmpty && _replaceController.text.isNotEmpty) {
      final entry = '${_findController.text} → ${_replaceController.text}';
      setState(() {
        _replaceHistory.remove(entry);
        _replaceHistory.insert(0, entry);
        if (_replaceHistory.length > 10) {
          _replaceHistory = _replaceHistory.take(10).toList();
        }
      });
    }
  }

  void _loadFromHistory(String historyEntry) {
    final parts = historyEntry.split(' → ');
    if (parts.length == 2) {
      _findController.text = parts[0];
      _replaceController.text = parts[1];
    }
  }

  Widget _buildOptionsPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replace Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _caseSensitive,
                      onChanged: (value) {
                        setState(() {
                          _caseSensitive = value ?? false;
                          _performReplace();
                        });
                      },
                    ),
                    const Text('Case Sensitive'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _useRegex,
                      onChanged: (value) {
                        setState(() {
                          _useRegex = value ?? false;
                          _performReplace();
                        });
                      },
                    ),
                    const Text('Use Regex'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _wholeWords,
                      onChanged: (value) {
                        setState(() {
                          _wholeWords = value ?? false;
                          _performReplace();
                        });
                      },
                    ),
                    const Text('Whole Words'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _multiline,
                      onChanged: (value) {
                        setState(() {
                          _multiline = value ?? false;
                          _performReplace();
                        });
                      },
                    ),
                    const Text('Multiline'),
                  ],
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Matches found: $_matchCount',
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    if (_replaceHistory.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Replacements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _replaceHistory.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._replaceHistory.map((entry) => ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 16),
              title: Text(entry, style: const TextStyle(fontSize: 12)),
              onTap: () => _loadFromHistory(entry),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('String Replace Tool'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: _pasteFromClipboard,
            tooltip: 'Paste from clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: _swapInputOutput,
            tooltip: 'Swap input/output',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOptionsPanel(),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Find/Replace Controls
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _findController,
                                  decoration: InputDecoration(
                                    labelText: 'Find',
                                    hintText: _useRegex ? 'Enter regex pattern...' : 'Enter text to find...',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _findController.clear(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _replaceController,
                                  decoration: InputDecoration(
                                    labelText: 'Replace with',
                                    hintText: 'Enter replacement text...',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: _addToHistory,
                                          tooltip: 'Add to history',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => _replaceController.clear(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Input Text
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Input Text',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.content_copy),
                                        onPressed: () => _copyToClipboard(_inputText),
                                        tooltip: 'Copy input',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _inputController,
                                      maxLines: null,
                                      expands: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter or paste your text here...',
                                        border: OutlineInputBorder(),
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildHistoryPanel(),
                        if (_replaceHistory.isNotEmpty) const SizedBox(height: 16),
                        // Output Text
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Output Text',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.content_copy),
                                        onPressed: () => _copyToClipboard(_outputText),
                                        tooltip: 'Copy output',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _outputController,
                                      maxLines: null,
                                      expands: true,
                                      readOnly: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Replaced text will appear here...',
                                        border: OutlineInputBorder(),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
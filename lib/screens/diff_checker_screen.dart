import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiffCheckerScreen extends StatefulWidget {
  const DiffCheckerScreen({super.key});

  @override
  State<DiffCheckerScreen> createState() => _DiffCheckerScreenState();
}

class _DiffCheckerScreenState extends State<DiffCheckerScreen> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  
  List<DiffLine> _diffLines = [];
  bool _ignoreWhitespace = false;
  bool _ignoreCase = false;

  @override
  void initState() {
    super.initState();
    _leftScrollController.addListener(_syncScroll);
    _rightScrollController.addListener(_syncScroll);
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_leftScrollController.hasClients && _rightScrollController.hasClients) {
      if (_leftScrollController.offset != _rightScrollController.offset) {
        _rightScrollController.jumpTo(_leftScrollController.offset);
      }
    }
  }

  void _performDiff() {
    setState(() {
      final leftText = _leftController.text;
      final rightText = _rightController.text;
      
      _diffLines = _calculateDiff(leftText, rightText);
    });
  }

  List<DiffLine> _calculateDiff(String leftText, String rightText) {
    List<String> leftLines = leftText.split('\n');
    List<String> rightLines = rightText.split('\n');
    
    if (_ignoreWhitespace) {
      leftLines = leftLines.map((line) => line.trim()).toList();
      rightLines = rightLines.map((line) => line.trim()).toList();
    }
    
    if (_ignoreCase) {
      leftLines = leftLines.map((line) => line.toLowerCase()).toList();
      rightLines = rightLines.map((line) => line.toLowerCase()).toList();
    }

    List<DiffLine> result = [];
    int leftIndex = 0;
    int rightIndex = 0;

    while (leftIndex < leftLines.length || rightIndex < rightLines.length) {
      if (leftIndex >= leftLines.length) {
        // Only right lines remaining (additions)
        result.add(DiffLine(
          leftLine: '',
          rightLine: rightLines[rightIndex],
          type: DiffType.addition,
          leftLineNumber: null,
          rightLineNumber: rightIndex + 1,
        ));
        rightIndex++;
      } else if (rightIndex >= rightLines.length) {
        // Only left lines remaining (deletions)
        result.add(DiffLine(
          leftLine: leftLines[leftIndex],
          rightLine: '',
          type: DiffType.deletion,
          leftLineNumber: leftIndex + 1,
          rightLineNumber: null,
        ));
        leftIndex++;
      } else if (leftLines[leftIndex] == rightLines[rightIndex]) {
        // Lines are the same
        result.add(DiffLine(
          leftLine: leftLines[leftIndex],
          rightLine: rightLines[rightIndex],
          type: DiffType.unchanged,
          leftLineNumber: leftIndex + 1,
          rightLineNumber: rightIndex + 1,
        ));
        leftIndex++;
        rightIndex++;
      } else {
        // Lines are different - look ahead to see if we can find a match
        int leftLookAhead = _findNextMatch(leftLines, leftIndex, rightLines[rightIndex]);
        int rightLookAhead = _findNextMatch(rightLines, rightIndex, leftLines[leftIndex]);
        
        if (leftLookAhead != -1 && (rightLookAhead == -1 || leftLookAhead <= rightLookAhead)) {
          // Found match in left side - treat as deletions until match
          for (int i = leftIndex; i < leftLookAhead; i++) {
            result.add(DiffLine(
              leftLine: leftLines[i],
              rightLine: '',
              type: DiffType.deletion,
              leftLineNumber: i + 1,
              rightLineNumber: null,
            ));
          }
          leftIndex = leftLookAhead;
        } else if (rightLookAhead != -1) {
          // Found match in right side - treat as additions until match
          for (int i = rightIndex; i < rightLookAhead; i++) {
            result.add(DiffLine(
              leftLine: '',
              rightLine: rightLines[i],
              type: DiffType.addition,
              leftLineNumber: null,
              rightLineNumber: i + 1,
            ));
          }
          rightIndex = rightLookAhead;
        } else {
          // No match found - treat as modification
          result.add(DiffLine(
            leftLine: leftLines[leftIndex],
            rightLine: rightLines[rightIndex],
            type: DiffType.modification,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: rightIndex + 1,
          ));
          leftIndex++;
          rightIndex++;
        }
      }
    }

    return result;
  }

  int _findNextMatch(List<String> lines, int startIndex, String target) {
    for (int i = startIndex; i < lines.length && i < startIndex + 10; i++) {
      if (lines[i] == target) {
        return i;
      }
    }
    return -1;
  }

  void _clearAll() {
    setState(() {
      _leftController.clear();
      _rightController.clear();
      _diffLines.clear();
    });
  }

  void _copyDiff() {
    final diffText = _diffLines.map((line) {
      switch (line.type) {
        case DiffType.addition:
          return '+ ${line.rightLine}';
        case DiffType.deletion:
          return '- ${line.leftLine}';
        case DiffType.modification:
          return '- ${line.leftLine}\n+ ${line.rightLine}';
        case DiffType.unchanged:
          return '  ${line.leftLine}';
      }
    }).join('\n');

    Clipboard.setData(ClipboardData(text: diffText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diff copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Options panel
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
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _ignoreWhitespace,
                        onChanged: (value) {
                          setState(() {
                            _ignoreWhitespace = value ?? false;
                          });
                          if (_leftController.text.isNotEmpty || _rightController.text.isNotEmpty) {
                            _performDiff();
                          }
                        },
                      ),
                      const Text('Ignore Whitespace'),
                      const SizedBox(width: 20),
                      Checkbox(
                        value: _ignoreCase,
                        onChanged: (value) {
                          setState(() {
                            _ignoreCase = value ?? false;
                          });
                          if (_leftController.text.isNotEmpty || _rightController.text.isNotEmpty) {
                            _performDiff();
                          }
                        },
                      ),
                      const Text('Ignore Case'),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _performDiff,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare'),
                ),
              ],
            ),
          ),
          // Input panels
          Expanded(
            flex: 1,
            child: Row(
              children: [
                // Left panel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Text(
                          'Original Text',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _leftController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: 'Paste your original text here...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16.0),
                          ),
                          style: const TextStyle(fontFamily: 'monospace'),
                          onChanged: (_) => _performDiff(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                // Right panel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Text(
                          'Modified Text',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _rightController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: 'Paste your modified text here...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16.0),
                          ),
                          style: const TextStyle(fontFamily: 'monospace'),
                          onChanged: (_) => _performDiff(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Diff results
          if (_diffLines.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Diff Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_diffLines.where((line) => line.type == DiffType.addition).length} additions, '
                    '${_diffLines.where((line) => line.type == DiffType.deletion).length} deletions, '
                    '${_diffLines.where((line) => line.type == DiffType.modification).length} modifications',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                controller: _leftScrollController,
                itemCount: _diffLines.length,
                itemBuilder: (context, index) {
                  final line = _diffLines[index];
                  return _buildDiffLine(line);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffLine(DiffLine line) {
    Color? backgroundColor;
    Color? textColor;
    String prefix = '';

    switch (line.type) {
      case DiffType.addition:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade800;
        prefix = '+';
        break;
      case DiffType.deletion:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade800;
        prefix = '-';
        break;
      case DiffType.modification:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade800;
        prefix = '~';
        break;
      case DiffType.unchanged:
        backgroundColor = null;
        textColor = Theme.of(context).textTheme.bodyMedium?.color;
        prefix = ' ';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(
            color: textColor ?? Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${line.leftLineNumber ?? ''}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(
              width: 30,
              child: Text(
                '${line.rightLineNumber ?? ''}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Text(
              prefix,
              style: TextStyle(
                fontFamily: 'monospace',
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line.type == DiffType.modification 
                    ? '${line.leftLine} → ${line.rightLine}'
                    : line.leftLine.isNotEmpty ? line.leftLine : line.rightLine,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiffLine {
  final String leftLine;
  final String rightLine;
  final DiffType type;
  final int? leftLineNumber;
  final int? rightLineNumber;

  DiffLine({
    required this.leftLine,
    required this.rightLine,
    required this.type,
    required this.leftLineNumber,
    required this.rightLineNumber,
  });
}

enum DiffType {
  addition,
  deletion,
  modification,
  unchanged,
}
import 'package:flutter/material.dart';
import 'dart:convert';

class JsonFormatterScreen extends StatefulWidget {
  const JsonFormatterScreen({super.key});

  @override
  State<JsonFormatterScreen> createState() => _JsonFormatterScreenState();
}

class _JsonFormatterScreenState extends State<JsonFormatterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';

  void _formatJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON to format';
        });
        return;
      }

      final jsonObject = jsonDecode(input);
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(jsonObject);
      
      setState(() {
        _outputController.text = formattedJson;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  void _minifyJson() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter JSON to minify';
        });
        return;
      }

      final jsonObject = jsonDecode(input);
      final minifiedJson = jsonEncode(jsonObject);
      
      setState(() {
        _outputController.text = minifiedJson;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Formatter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Input JSON:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _inputController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste your JSON here...',
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatJson,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                ElevatedButton.icon(
                  onPressed: _minifyJson,
                  icon: const Icon(Icons.compress),
                  label: const Text('Minify'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Container(
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
            if (_errorMessage.isNotEmpty) const SizedBox(height: 8),
            const Text(
              'Formatted Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _outputController,
                maxLines: null,
                expands: true,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Formatted JSON will appear here...',
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
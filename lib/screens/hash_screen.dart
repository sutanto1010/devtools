import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashScreen extends StatefulWidget {
  const HashScreen({super.key});

  @override
  State<HashScreen> createState() => _HashScreenState();
}

class _HashScreenState extends State<HashScreen> {
  final TextEditingController _inputController = TextEditingController();
  final Map<String, String> _hashResults = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _hashTypes = [
    {'name': 'MD5', 'key': 'md5'},
    {'name': 'SHA-1', 'key': 'sha1'},
    {'name': 'SHA-224', 'key': 'sha224'},
    {'name': 'SHA-256', 'key': 'sha256'},
    {'name': 'SHA-384', 'key': 'sha384'},
    {'name': 'SHA-512', 'key': 'sha512'},
    {'name': 'SHA-512/224', 'key': 'sha512224'},
    {'name': 'SHA-512/256', 'key': 'sha512256'},
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateHashes() {
    if (_inputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to hash')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hashResults.clear();
    });

    final input = _inputController.text;
    final bytes = utf8.encode(input);

    try {
      // Generate all hash types
      _hashResults['md5'] = md5.convert(bytes).toString();
      _hashResults['sha1'] = sha1.convert(bytes).toString();
      _hashResults['sha224'] = sha224.convert(bytes).toString();
      _hashResults['sha256'] = sha256.convert(bytes).toString();
      _hashResults['sha384'] = sha384.convert(bytes).toString();
      _hashResults['sha512'] = sha512.convert(bytes).toString();
      _hashResults['sha512224'] = sha512224.convert(bytes).toString();
      _hashResults['sha512256'] = sha512256.convert(bytes).toString();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating hashes: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String value, String hashType) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$hashType hash copied to clipboard')),
    );
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _hashResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Text',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter text to generate hashes...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && _hashResults.isEmpty) {
                          // Auto-generate on first input
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_inputController.text == value && value.isNotEmpty) {
                              _generateHashes();
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _generateHashes,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.tag),
                            label: Text(_isLoading ? 'Generating...' : 'Generate Hashes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_hashResults.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hash Results',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _hashTypes.length,
                            itemBuilder: (context, index) {
                              final hashType = _hashTypes[index];
                              final hashValue = _hashResults[hashType['key']] ?? '';
                              
                              if (hashValue.isEmpty) return const SizedBox.shrink();
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            hashType['name'],
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${hashValue.length} chars',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () => _copyToClipboard(hashValue, hashType['name']),
                                                icon: const Icon(Icons.copy, size: 18),
                                                tooltip: 'Copy ${hashType['name']} hash',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4.0),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: SelectableText(
                                          hashValue,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_hashResults.isEmpty && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tag,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter text above to generate hashes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supports MD5, SHA-1, SHA-224, SHA-256, SHA-384, SHA-512, and more',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
import 'package:flutter/material.dart';
import 'dart:convert';

class JwtDecoderScreen extends StatefulWidget {
  const JwtDecoderScreen({super.key});

  @override
  State<JwtDecoderScreen> createState() => _JwtDecoderScreenState();
}

class _JwtDecoderScreenState extends State<JwtDecoderScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  String _errorMessage = '';
  bool _isValid = false;

  void _decodeJwt() {
    setState(() {
      _errorMessage = '';
      _headerController.clear();
      _payloadController.clear();
      _signatureController.clear();
      _isValid = false;
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a JWT token to decode';
        });
        return;
      }

      // Split JWT into parts
      final parts = input.split('.');
      if (parts.length != 3) {
        setState(() {
          _errorMessage = 'Invalid JWT format. JWT should have 3 parts separated by dots.';
        });
        return;
      }

      // Decode header
      final headerDecoded = _decodeBase64Url(parts[0]);
      final headerJson = json.decode(headerDecoded);
      final headerFormatted = const JsonEncoder.withIndent('  ').convert(headerJson);

      // Decode payload
      final payloadDecoded = _decodeBase64Url(parts[1]);
      final payloadJson = json.decode(payloadDecoded);
      final payloadFormatted = const JsonEncoder.withIndent('  ').convert(payloadJson);

      // Signature (keep as base64url)
      final signature = parts[2];

      setState(() {
        _headerController.text = headerFormatted;
        _payloadController.text = payloadFormatted;
        _signatureController.text = signature;
        _isValid = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error decoding JWT: ${e.toString()}';
      });
    }
  }

  String _decodeBase64Url(String base64Url) {
    // Convert base64url to base64
    String base64 = base64Url.replaceAll('-', '+').replaceAll('_', '/');
    
    // Add padding if necessary
    switch (base64.length % 4) {
      case 2:
        base64 += '==';
        break;
      case 3:
        base64 += '=';
        break;
    }
    
    final bytes = base64Decode(base64);
    return utf8.decode(bytes);
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _headerController.clear();
      _payloadController.clear();
      _signatureController.clear();
      _errorMessage = '';
      _isValid = false;
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return date.toLocal().toString();
    } catch (e) {
      return timestamp.toString();
    }
  }

  Widget _buildTokenInfo() {
    if (!_isValid || _payloadController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final payload = json.decode(_payloadController.text);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Token Information:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (payload['iss'] != null)
                Text('Issuer: ${payload['iss']}'),
              if (payload['sub'] != null)
                Text('Subject: ${payload['sub']}'),
              if (payload['aud'] != null)
                Text('Audience: ${payload['aud']}'),
              if (payload['exp'] != null)
                Text('Expires: ${_formatTimestamp(payload['exp'])}'),
              if (payload['iat'] != null)
                Text('Issued At: ${_formatTimestamp(payload['iat'])}'),
              if (payload['nbf'] != null)
                Text('Not Before: ${_formatTimestamp(payload['nbf'])}'),
              if (payload['jti'] != null)
                Text('JWT ID: ${payload['jti']}'),
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JWT Decoder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'JWT Token:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste your JWT token here...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _decodeJwt,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Decode JWT'),
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
            if (_isValid) _buildTokenInfo(),
            if (_isValid) const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Header'),
                        Tab(text: 'Payload'),
                        Tab(text: 'Signature'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Header tab
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _headerController,
                              maxLines: null,
                              expands: true,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'JWT header will appear here...',
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ),
                          // Payload tab
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _payloadController,
                              maxLines: null,
                              expands: true,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'JWT payload will appear here...',
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ),
                          // Signature tab
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _signatureController,
                              maxLines: null,
                              expands: true,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'JWT signature will appear here...',
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ),
                        ],
                      ),
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

  @override
  void dispose() {
    _inputController.dispose();
    _headerController.dispose();
    _payloadController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
}
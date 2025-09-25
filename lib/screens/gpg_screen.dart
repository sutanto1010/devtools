import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openpgp/openpgp.dart';

class GpgScreen extends StatefulWidget {
  const GpgScreen({super.key});

  @override
  State<GpgScreen> createState() => _GpgScreenState();
}

class _GpgScreenState extends State<GpgScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String _errorMessage = '';
  bool _isEncrypting = true;
  bool _isGeneratingKeys = false;
  bool _obscurePrivateKey = true;
  bool _obscurePassphrase = true;
  
  KeyPair? _currentKeyPair;

  Future<void> _generateKeys() async {
    setState(() {
      _isGeneratingKeys = true;
      _errorMessage = '';
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final passphrase = _passphraseController.text;

      if (name.isEmpty || email.isEmpty || passphrase.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in name, email, and passphrase';
          _isGeneratingKeys = false;
        });
        return;
      }

      // Generate key pair with OpenPGP
      final keyOptions = KeyOptions()..rsaBits = 2048;
      final keyPair = await OpenPGP.generate(
        options: Options()
          ..name = name
          ..email = email
          ..passphrase = passphrase
          ..keyOptions = keyOptions,
      );

      setState(() {
        _currentKeyPair = keyPair;
        _publicKeyController.text = keyPair.publicKey;
        _privateKeyController.text = keyPair.privateKey;
        _isGeneratingKeys = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating keys: ${e.toString()}';
        _isGeneratingKeys = false;
      });
    }
  }

  Future<void> _processGpg() async {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      final passphrase = _passphraseController.text;

      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter text to ${_isEncrypting ? 'encrypt' : 'decrypt'}';
        });
        return;
      }

      String result;
      if (_isEncrypting) {
        final publicKey = _publicKeyController.text.trim();
        if (publicKey.isEmpty) {
          setState(() {
            _errorMessage = 'Please provide a public key for encryption';
          });
          return;
        }
        result = await OpenPGP.encrypt(input, publicKey);
      } else {
        final privateKey = _privateKeyController.text.trim();
        if (privateKey.isEmpty || passphrase.isEmpty) {
          setState(() {
            _errorMessage = 'Please provide private key and passphrase for decryption';
          });
          return;
        }
        result = await OpenPGP.decrypt(input, privateKey, passphrase);
      }

      setState(() {
        _outputController.text = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error ${_isEncrypting ? 'encrypting' : 'decrypting'}: ${e.toString()}';
      });
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _publicKeyController.clear();
      _privateKeyController.clear();
      _passphraseController.clear();
      _nameController.clear();
      _emailController.clear();
      _errorMessage = '';
      _currentKeyPair = null;
    });
  }

  void _switchMode() {
    setState(() {
      _isEncrypting = !_isEncrypting;
      _errorMessage = '';
      // Optionally swap input and output
      final temp = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = temp;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _importKeys() {
    // This would typically involve file picker or paste functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Keys'),
        content: const Text(
          'In a real application, you would implement key import from files or clipboard. '
          'For now, you can paste keys directly into the key fields.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
            // Mode Switch
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mode: ${_isEncrypting ? 'Encrypt (Public Key)' : 'Decrypt (Private Key)'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: _isEncrypting,
                  onChanged: (value) {
                    setState(() {
                      _isEncrypting = value;
                      _errorMessage = '';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Generation Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Generation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Name',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Email',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passphraseController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Passphrase',
                        isDense: true,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassphrase = !_obscurePassphrase;
                            });
                          },
                          icon: Icon(
                            _obscurePassphrase ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassphrase,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingKeys ? null : _generateKeys,
                        icon: _isGeneratingKeys
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.vpn_key),
                        label: Text(_isGeneratingKeys ? 'Generating...' : 'Generate Key Pair'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Public Key Display
            TextField(
              controller: _publicKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Public Key (for encryption)',
                isDense: true,
                suffixIcon: _publicKeyController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () => _copyToClipboard(_publicKeyController.text),
                        icon: const Icon(Icons.copy),
                      )
                    : null,
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),

            // Private Key Display
            TextField(
              controller: _privateKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Private Key (for decryption)',
                isDense: true,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePrivateKey = !_obscurePrivateKey;
                        });
                      },
                      icon: Icon(
                        _obscurePrivateKey ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    if (_privateKeyController.text.isNotEmpty)
                      IconButton(
                        onPressed: () => _copyToClipboard(_privateKeyController.text),
                        icon: const Icon(Icons.copy),
                      ),
                  ],
                ),
              ),
              obscureText: _obscurePrivateKey,
              maxLines: 1,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Input Text
            Text(
              'Input ${_isEncrypting ? '(Plain Text)' : '(Encrypted Message)'}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _inputController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isEncrypting
                      ? 'Enter plain text to encrypt...'
                      : 'Enter PGP encrypted message to decrypt...',
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _processGpg,
                  icon: Icon(_isEncrypting ? Icons.lock : Icons.lock_open),
                  label: Text(_isEncrypting ? 'Encrypt' : 'Decrypt'),
                ),
                ElevatedButton.icon(
                  onPressed: _switchMode,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Switch'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error Message
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

            // Output Text
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Output ${_isEncrypting ? '(Encrypted Message)' : '(Plain Text)'}:',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_outputController.text.isNotEmpty)
                  IconButton(
                    onPressed: () => _copyToClipboard(_outputController.text),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _outputController,
                maxLines: null,
                expands: true,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isEncrypting
                      ? 'Encrypted PGP message will appear here...'
                      : 'Decrypted plain text will appear here...',
                ),
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    _passphraseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
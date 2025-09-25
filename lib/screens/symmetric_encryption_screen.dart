import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SymmetricEncryptionScreen extends StatefulWidget {
  const SymmetricEncryptionScreen({super.key});

  @override
  State<SymmetricEncryptionScreen> createState() => _SymmetricEncryptionScreenState();
}

class _SymmetricEncryptionScreenState extends State<SymmetricEncryptionScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _errorMessage = '';
  bool _isEncrypting = true;
  bool _obscurePassword = true;
  String _selectedAlgorithm = 'AES-256-CBC';
  
  final List<String> _algorithms = [
    'AES-256-CBC',
    'AES-128-CBC',
    'AES-256-GCM',
  ];

  // Generate a random salt for key derivation
  Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(16);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  // Derive key from password using PBKDF2
  encrypt.Key _deriveKey(String password, Uint8List salt, int keyLength) {
    final bytes = utf8.encode(password);
    final hmac = Hmac(sha256, salt);
    var digest = hmac.convert(bytes);
    
    // Simple PBKDF2 implementation - in production, use a proper crypto library
    for (int i = 1; i < 10000; i++) {
      digest = Hmac(sha256, salt).convert(digest.bytes);
    }
    
    final keyBytes = Uint8List(keyLength);
    final digestBytes = digest.bytes;
    for (int i = 0; i < keyLength; i++) {
      keyBytes[i] = digestBytes[i % digestBytes.length];
    }
    
    return encrypt.Key(keyBytes);
  }

  Future<void> _processEncryption() async {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      final password = _passwordController.text;

      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter text to ${_isEncrypting ? 'encrypt' : 'decrypt'}';
        });
        return;
      }

      if (password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a password';
        });
        return;
      }

      String result;
      if (_isEncrypting) {
        result = await _encrypt(input, password);
      } else {
        result = await _decrypt(input, password);
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

  Future<String> _encrypt(String plaintext, String password) async {
    try {
      final salt = _generateSalt();
      final iv = encrypt.IV.fromSecureRandom(16);
      
      encrypt.Key key;
      encrypt.Encrypter encrypter;
      
      switch (_selectedAlgorithm) {
        case 'AES-256-CBC':
          key = _deriveKey(password, salt, 32);
          encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
          break;
        case 'AES-128-CBC':
          key = _deriveKey(password, salt, 16);
          encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
          break;
        case 'AES-256-GCM':
          key = _deriveKey(password, salt, 32);
          encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
          break;
        default:
          throw Exception('Unsupported algorithm: $_selectedAlgorithm');
      }

      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      
      // Combine salt + iv + encrypted data
      final combined = <int>[];
      combined.addAll(salt);
      combined.addAll(iv.bytes);
      combined.addAll(encrypted.bytes);
      
      return base64.encode(combined);
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }

  Future<String> _decrypt(String encryptedData, String password) async {
    try {
      final combined = base64.decode(encryptedData);
      
      if (combined.length < 32) {
        throw Exception('Invalid encrypted data format');
      }
      
      // Extract salt (16 bytes) + iv (16 bytes) + encrypted data
      final salt = Uint8List.fromList(combined.sublist(0, 16));
      final iv = encrypt.IV(Uint8List.fromList(combined.sublist(16, 32)));
      final encryptedBytes = Uint8List.fromList(combined.sublist(32));
      
      encrypt.Key key;
      encrypt.Encrypter encrypter;
      
      switch (_selectedAlgorithm) {
        case 'AES-256-CBC':
          key = _deriveKey(password, salt, 32);
          encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
          break;
        case 'AES-128-CBC':
          key = _deriveKey(password, salt, 16);
          encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
          break;
        case 'AES-256-GCM':
          key = _deriveKey(password, salt, 32);
          encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
          break;
        default:
          throw Exception('Unsupported algorithm: $_selectedAlgorithm');
      }

      final encrypted = encrypt.Encrypted(encryptedBytes);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _passwordController.clear();
      _errorMessage = '';
    });
  }

  void _switchMode() {
    setState(() {
      _isEncrypting = !_isEncrypting;
      _errorMessage = '';
      // Swap input and output
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

  void _generateRandomPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random.secure();
    final password = String.fromCharCodes(Iterable.generate(
        16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    
    setState(() {
      _passwordController.text = password;
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
            // Mode and Algorithm Selection
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mode: ${_isEncrypting ? 'Encrypt' : 'Decrypt'}',
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
            const SizedBox(height: 8),
            
            // Algorithm Selection
            Row(
              children: [
                const Text('Algorithm: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedAlgorithm,
                    isExpanded: true,
                    items: _algorithms.map((String algorithm) {
                      return DropdownMenuItem<String>(
                        value: algorithm,
                        child: Text(algorithm),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAlgorithm = newValue;
                          _errorMessage = '';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Password Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Password',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                          IconButton(
                            onPressed: _generateRandomPassword,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Generate random password',
                          ),
                        ],
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input Text
            Text(
              'Input ${_isEncrypting ? '(Plain Text)' : '(Encrypted Data)'}:',
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
                      : 'Enter encrypted data to decrypt...',
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
                  onPressed: _processEncryption,
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
                    'Output ${_isEncrypting ? '(Encrypted Data)' : '(Plain Text)'}:',
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
                      ? 'Encrypted data will appear here...'
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
    _passwordController.dispose();
    super.dispose();
  }
}
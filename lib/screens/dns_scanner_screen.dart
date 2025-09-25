import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DnsScannerScreen extends StatefulWidget {
  const DnsScannerScreen({super.key});

  @override
  State<DnsScannerScreen> createState() => _DnsScannerScreenState();
}

class _DnsScannerScreenState extends State<DnsScannerScreen> {
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _errorMessage = '';
  bool _isScanning = false;
  String _selectedRecordType = 'A';
  
  final List<String> _recordTypes = ['A', 'AAAA', 'MX', 'NS', 'TXT', 'CNAME', 'SOA', 'PTR'];
  final List<Map<String, String>> _scanResults = [];

  Future<void> _performDnsLookup() async {
    setState(() {
      _isScanning = true;
      _errorMessage = '';
      _scanResults.clear();
      _outputController.clear();
    });

    try {
      final domain = _domainController.text.trim();
      if (domain.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a domain name';
          _isScanning = false;
        });
        return;
      }

      // Validate domain format
      if (!_isValidDomain(domain)) {
        setState(() {
          _errorMessage = 'Please enter a valid domain name';
          _isScanning = false;
        });
        return;
      }

      List<InternetAddress> results = [];
      String resultText = '';
      
      try {
        switch (_selectedRecordType) {
          case 'A':
            results = await InternetAddress.lookup(domain, type: InternetAddressType.IPv4);
            resultText = 'A Records for $domain:\n';
            for (var addr in results) {
              resultText += '${addr.address}\n';
              _scanResults.add({'type': 'A', 'value': addr.address});
            }
            break;
          case 'AAAA':
            results = await InternetAddress.lookup(domain, type: InternetAddressType.IPv6);
            resultText = 'AAAA Records for $domain:\n';
            for (var addr in results) {
              resultText += '${addr.address}\n';
              _scanResults.add({'type': 'AAAA', 'value': addr.address});
            }
            break;
          default:
            // For other record types, we'll use a basic lookup and show a message
            results = await InternetAddress.lookup(domain);
            resultText = '$_selectedRecordType Records for $domain:\n';
            resultText += 'Note: Advanced DNS record types require additional dependencies.\n';
            resultText += 'Basic IP resolution:\n';
            for (var addr in results) {
              resultText += '${addr.address}\n';
              _scanResults.add({'type': 'IP', 'value': addr.address});
            }
        }
      } catch (e) {
        resultText = 'No $_selectedRecordType records found for $domain\n';
        resultText += 'Error: ${e.toString()}';
      }

      setState(() {
        _outputController.text = resultText;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'DNS lookup failed: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  bool _isValidDomain(String domain) {
    // Basic domain validation
    final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$');
    return domainRegex.hasMatch(domain) || domain == 'localhost';
  }

  void _performBulkScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = '';
      _scanResults.clear();
    });

    try {
      final domain = _domainController.text.trim();
      if (domain.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a domain name';
          _isScanning = false;
        });
        return;
      }

      String bulkResults = 'DNS Scan Results for $domain:\n\n';
      
      // Scan A records
      try {
        final aRecords = await InternetAddress.lookup(domain, type: InternetAddressType.IPv4);
        bulkResults += 'A Records:\n';
        for (var addr in aRecords) {
          bulkResults += '  ${addr.address}\n';
          _scanResults.add({'type': 'A', 'value': addr.address});
        }
        bulkResults += '\n';
      } catch (e) {
        bulkResults += 'A Records: None found\n\n';
      }

      // Scan AAAA records
      try {
        final aaaaRecords = await InternetAddress.lookup(domain, type: InternetAddressType.IPv6);
        bulkResults += 'AAAA Records:\n';
        for (var addr in aaaaRecords) {
          bulkResults += '  ${addr.address}\n';
          _scanResults.add({'type': 'AAAA', 'value': addr.address});
        }
        bulkResults += '\n';
      } catch (e) {
        bulkResults += 'AAAA Records: None found\n\n';
      }

      // Add note about additional record types
      bulkResults += 'Note: For MX, NS, TXT, CNAME, SOA, and PTR records,\n';
      bulkResults += 'additional DNS libraries would be required.\n';
      bulkResults += 'This implementation shows A and AAAA records using\n';
      bulkResults += 'Flutter\'s built-in InternetAddress.lookup().';

      setState(() {
        _outputController.text = bulkResults;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bulk DNS scan failed: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _domainController.clear();
      _outputController.clear();
      _errorMessage = '';
      _scanResults.clear();
    });
  }

  void _copyToClipboard() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Domain input
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'Domain Name',
                hintText: 'e.g., google.com, github.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 16),
            
            // Record type selection
            Row(
              children: [
                const Text('Record Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRecordType,
                  items: _recordTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRecordType = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _performDnsLookup,
                    icon: _isScanning 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isScanning ? 'Scanning...' : 'Lookup $_selectedRecordType'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _performBulkScan,
                    icon: const Icon(Icons.scanner),
                    label: const Text('Bulk Scan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Results'),
                  ),
                ),
              ],
            ),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Results
            const Text(
              'Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _outputController,
                maxLines: null,
                expands: true,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'DNS scan results will appear here...',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _domainController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
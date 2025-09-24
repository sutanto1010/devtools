import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChmodCalculatorScreen extends StatefulWidget {
  const ChmodCalculatorScreen({super.key});

  @override
  State<ChmodCalculatorScreen> createState() => _ChmodCalculatorScreenState();
}

class _ChmodCalculatorScreenState extends State<ChmodCalculatorScreen> {
  final TextEditingController _numericController = TextEditingController();
  final TextEditingController _symbolicController = TextEditingController();
  
  // Permission checkboxes for Owner, Group, Others
  bool _ownerRead = false;
  bool _ownerWrite = false;
  bool _ownerExecute = false;
  
  bool _groupRead = false;
  bool _groupWrite = false;
  bool _groupExecute = false;
  
  bool _othersRead = false;
  bool _othersWrite = false;
  bool _othersExecute = false;
  
  String _errorMessage = '';
  String _explanation = '';

  @override
  void initState() {
    super.initState();
    _updateFromCheckboxes();
  }

  void _updateFromCheckboxes() {
    int owner = (_ownerRead ? 4 : 0) + (_ownerWrite ? 2 : 0) + (_ownerExecute ? 1 : 0);
    int group = (_groupRead ? 4 : 0) + (_groupWrite ? 2 : 0) + (_groupExecute ? 1 : 0);
    int others = (_othersRead ? 4 : 0) + (_othersWrite ? 2 : 0) + (_othersExecute ? 1 : 0);
    
    String numeric = '$owner$group$others';
    String symbolic = _generateSymbolic();
    
    _numericController.text = numeric;
    _symbolicController.text = symbolic;
    
    _generateExplanation(numeric);
  }

  String _generateSymbolic() {
    String result = '';
    
    // Owner permissions
    result += _ownerRead ? 'r' : '-';
    result += _ownerWrite ? 'w' : '-';
    result += _ownerExecute ? 'x' : '-';
    
    // Group permissions
    result += _groupRead ? 'r' : '-';
    result += _groupWrite ? 'w' : '-';
    result += _groupExecute ? 'x' : '-';
    
    // Others permissions
    result += _othersRead ? 'r' : '-';
    result += _othersWrite ? 'w' : '-';
    result += _othersExecute ? 'x' : '-';
    
    return result;
  }

  void _generateExplanation(String numeric) {
    if (numeric.length != 3) {
      setState(() {
        _explanation = '';
      });
      return;
    }
    
    List<String> explanations = [];
    List<String> users = ['Owner', 'Group', 'Others'];
    
    for (int i = 0; i < 3; i++) {
      int digit = int.tryParse(numeric[i]) ?? 0;
      List<String> perms = [];
      
      if (digit & 4 != 0) perms.add('read');
      if (digit & 2 != 0) perms.add('write');
      if (digit & 1 != 0) perms.add('execute');
      
      if (perms.isEmpty) {
        explanations.add('${users[i]}: no permissions');
      } else {
        explanations.add('${users[i]}: ${perms.join(', ')}');
      }
    }
    
    setState(() {
      _explanation = explanations.join('\n');
    });
  }

  void _parseNumeric(String value) {
    setState(() {
      _errorMessage = '';
    });
    
    if (value.length != 3) {
      setState(() {
        _errorMessage = 'Numeric chmod must be exactly 3 digits';
      });
      return;
    }
    
    try {
      for (int i = 0; i < 3; i++) {
        int digit = int.parse(value[i]);
        if (digit < 0 || digit > 7) {
          setState(() {
            _errorMessage = 'Each digit must be between 0 and 7';
          });
          return;
        }
      }
      
      // Update checkboxes based on numeric input
      int owner = int.parse(value[0]);
      int group = int.parse(value[1]);
      int others = int.parse(value[2]);
      
      setState(() {
        _ownerRead = (owner & 4) != 0;
        _ownerWrite = (owner & 2) != 0;
        _ownerExecute = (owner & 1) != 0;
        
        _groupRead = (group & 4) != 0;
        _groupWrite = (group & 2) != 0;
        _groupExecute = (group & 1) != 0;
        
        _othersRead = (others & 4) != 0;
        _othersWrite = (others & 2) != 0;
        _othersExecute = (others & 1) != 0;
      });
      
      _symbolicController.text = _generateSymbolic();
      _generateExplanation(value);
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid numeric format';
      });
    }
  }

  void _parseSymbolic(String value) {
    setState(() {
      _errorMessage = '';
    });
    
    if (value.length != 9) {
      setState(() {
        _errorMessage = 'Symbolic chmod must be exactly 9 characters (e.g., rwxr-xr--)';
      });
      return;
    }
    
    try {
      // Validate characters
      for (int i = 0; i < 9; i++) {
        String char = value[i];
        if (i % 3 == 0 && char != 'r' && char != '-') {
          throw Exception('Invalid read permission character at position ${i + 1}');
        }
        if (i % 3 == 1 && char != 'w' && char != '-') {
          throw Exception('Invalid write permission character at position ${i + 1}');
        }
        if (i % 3 == 2 && char != 'x' && char != '-') {
          throw Exception('Invalid execute permission character at position ${i + 1}');
        }
      }
      
      setState(() {
        // Owner permissions
        _ownerRead = value[0] == 'r';
        _ownerWrite = value[1] == 'w';
        _ownerExecute = value[2] == 'x';
        
        // Group permissions
        _groupRead = value[3] == 'r';
        _groupWrite = value[4] == 'w';
        _groupExecute = value[5] == 'x';
        
        // Others permissions
        _othersRead = value[6] == 'r';
        _othersWrite = value[7] == 'w';
        _othersExecute = value[8] == 'x';
      });
      
      _updateFromCheckboxes();
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPermissionSection(String title, bool read, bool write, bool execute,
      Function(bool?) onReadChanged, Function(bool?) onWriteChanged, Function(bool?) onExecuteChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Read (r)'),
              subtitle: const Text('Permission to read the file'),
              value: read,
              onChanged: onReadChanged,
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Write (w)'),
              subtitle: const Text('Permission to modify the file'),
              value: write,
              onChanged: onWriteChanged,
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Execute (x)'),
              subtitle: const Text('Permission to execute the file'),
              value: execute,
              onChanged: onExecuteChanged,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chmod Calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
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
                    const Text(
                      'Chmod Calculator',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Calculate Unix file permissions in numeric (755) and symbolic (rwxr-xr-x) formats.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Input/Output Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permission Values',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Numeric Input
                    TextField(
                      controller: _numericController,
                      decoration: InputDecoration(
                        labelText: 'Numeric Format (e.g., 755)',
                        hintText: 'Enter 3-digit chmod value',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(_numericController.text, 'Numeric chmod'),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: _parseNumeric,
                    ),
                    const SizedBox(height: 16),
                    
                    // Symbolic Input
                    TextField(
                      controller: _symbolicController,
                      decoration: InputDecoration(
                        labelText: 'Symbolic Format (e.g., rwxr-xr-x)',
                        hintText: 'Enter 9-character symbolic format',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(_symbolicController.text, 'Symbolic chmod'),
                        ),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(9),
                        FilteringTextInputFormatter.allow(RegExp(r'[rwx-]')),
                      ],
                      onChanged: _parseSymbolic,
                    ),
                    
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Permission Checkboxes
            _buildPermissionSection(
              'Owner Permissions',
              _ownerRead, _ownerWrite, _ownerExecute,
              (value) => setState(() { _ownerRead = value ?? false; _updateFromCheckboxes(); }),
              (value) => setState(() { _ownerWrite = value ?? false; _updateFromCheckboxes(); }),
              (value) => setState(() { _ownerExecute = value ?? false; _updateFromCheckboxes(); }),
            ),
            const SizedBox(height: 8),
            
            _buildPermissionSection(
              'Group Permissions',
              _groupRead, _groupWrite, _groupExecute,
              (value) => setState(() { _groupRead = value ?? false; _updateFromCheckboxes(); }),
              (value) => setState(() { _groupWrite = value ?? false; _updateFromCheckboxes(); }),
              (value) => setState(() { _groupExecute = value ?? false; _updateFromCheckboxes(); }),
            ),
            const SizedBox(height: 8),
            
            _buildPermissionSection(
              'Others Permissions',
              _othersRead, _othersWrite, _othersExecute,
              (value) => setState(() { _othersRead = value ?? false; _updateFromCheckboxes(); }),
              (value) => setState(() { _othersWrite = value ?? false; _updateFromCheckboxes(); }),
              (value) => setState(() { _othersExecute = value ?? false; _updateFromCheckboxes(); }),
            ),
            
            if (_explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permission Explanation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _explanation,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Common Permissions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('755 (rwxr-xr-x): Owner can read/write/execute, others can read/execute'),
                    const Text('644 (rw-r--r--): Owner can read/write, others can read only'),
                    const Text('600 (rw-------): Owner can read/write, no access for others'),
                    const Text('777 (rwxrwxrwx): Full permissions for everyone'),
                    const Text('000 (---------): No permissions for anyone'),
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
    _numericController.dispose();
    _symbolicController.dispose();
    super.dispose();
  }
}
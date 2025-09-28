import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redis/redis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/brader_redis_connection.dart';

class RedisClientScreen extends StatefulWidget {
  const RedisClientScreen({super.key});

  @override
  State<RedisClientScreen> createState() => _RedisClientScreenState();
}

class _RedisClientScreenState extends State<RedisClientScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<BraderRedisConnection> _connections = [];
  BraderRedisConnection? _selectedConnection;
  BraderRedisConnection? _activeConnection;
  Command? _redisCommand;
  
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<RedisKeyInfo> _keys = [];
  List<RedisKeyInfo> _filteredKeys = [];
  List<RedisCommandResult> _commandHistory = [];
  
  String _selectedKey = '';
  dynamic _selectedValue;
  String _selectedKeyType = '';
  int? _selectedKeyTTL;
  
  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = 'Not connected';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConnections();
    _searchController.addListener(_filterKeys);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commandController.dispose();
    _keyController.dispose();
    _valueController.dispose();
    _searchController.dispose();
    _redisCommand?.get_connection()?.close();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = prefs.getStringList('redis_connections') ?? [];
    
    setState(() {
      _connections = connectionsJson
          .map((json) => BraderRedisConnection.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = _connections
        .map((conn) => jsonEncode(conn.toJson()))
        .toList();
    
    await prefs.setStringList('redis_connections', connectionsJson);
  }

  Future<void> _connectToRedis(BraderRedisConnection connection) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting...';
    });

    try {
      final conn = RedisConnection();
      _redisCommand = await conn.connect(connection.host, connection.port);
      
      if (connection.password != null && connection.password!.isNotEmpty) {
        await _redisCommand!.send_object(['AUTH', connection.password]);
      }
      
      if (connection.database != 0) {
        await _redisCommand!.send_object(['SELECT', connection.database]);
      }
      
      // Test connection
      final pong = await _redisCommand!.send_object(['PING']);
      if (pong == 'PONG') {
        setState(() {
          _isConnected = true;
          _activeConnection = connection.copyWith(lastUsed: DateTime.now());
          _statusMessage = 'Connected to ${connection.name}';
        });
        
        // Update last used time
        final index = _connections.indexWhere((c) => c.id == connection.id);
        if (index != -1) {
          _connections[index] = _activeConnection!;
          await _saveConnections();
        }
        
        await _loadKeys();
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Connection failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnect() async {
    if (_redisCommand != null) {
      _redisCommand!.get_connection().close();
      _redisCommand = null;
    }
    
    setState(() {
      _isConnected = false;
      _activeConnection = null;
      _statusMessage = 'Disconnected';
      _keys.clear();
      _filteredKeys.clear();
      _selectedKey = '';
      _selectedValue = null;
    });
  }

    Future<void> _loadKeys() async {
    if (!_isConnected || _redisCommand == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final keys = await _redisCommand!.send_object(['KEYS', '*']);
      final keyInfos = <RedisKeyInfo>[];
      
      for (final key in keys) {
        try {
          // Handle potential encoding issues with key names
          String keyString;
          if (key is List<int>) {
            // If key is binary data, try to decode it safely
            try {
              keyString = utf8.decode(key, allowMalformed: true);
            } catch (e) {
              // If UTF-8 decoding fails, use base64 encoding as fallback
              keyString = 'binary_key_${base64.encode(key)}';
            }
          } else {
            keyString = key.toString();
          }
          
          final type = await _redisCommand!.send_object(['TYPE', keyString]);
          final ttl = await _redisCommand!.send_object(['TTL', keyString]);
          final valueType = type.toString();
          if (valueType == 'hash') continue;
          keyInfos.add(RedisKeyInfo(
            key: keyString,
            type: type.toString(),
            ttl: ttl == -1 ? null : ttl as int?,
          ));
        } catch (e) {
          // Skip keys that cause encoding errors and log them
          print('Skipping key due to encoding error: $e');
          continue;
        }
      }
      
      setState(() {
        _keys = keyInfos;
        _filteredKeys = keyInfos;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load keys: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterKeys() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredKeys = _keys.where((key) => 
          key.key.toLowerCase().contains(query)).toList();
    });
  }

    Future<void> _loadKeyValue(String key) async {
    if (!_isConnected || _redisCommand == null) return;
    
    setState(() {
      _isLoading = true;
      _selectedKey = key;
    });
    
    try {
      final type = await _redisCommand!.send_object(['TYPE', key]);
      final ttl = await _redisCommand!.send_object(['TTL', key]);
      
      dynamic value;
      switch (type) {
        case 'string':
          try {
            final rawValue = await _redisCommand!.send_object(['GET', key]);
            value = _safeDecodeValue(rawValue);
          } catch (e) {
            // If the GET command itself fails due to encoding issues,
            // try to get the raw bytes using a different approach
            try {
              final rawBytes = await _redisCommand!.send_object(['DUMP', key]);
              if (rawBytes != null) {
                value = 'Binary data (DUMP format): ${rawBytes.toString()}';
              } else {
                value = 'Unable to retrieve value due to encoding issues';
              }
            } catch (dumpError) {
              value = 'Error retrieving value: ${e.toString()}';
            }
          }
          break;
        case 'list':
          try {
            final rawList = await _redisCommand!.send_object(['LRANGE', key, 0, -1]);
            value = _processList(rawList);
          } catch (e) {
            value = 'Error retrieving list: ${e.toString()}';
          }
          break;
        case 'set':
          try {
            final rawSet = await _redisCommand!.send_object(['SMEMBERS', key]);
            value = _processList(rawSet);
          } catch (e) {
            value = 'Error retrieving set: ${e.toString()}';
          }
          break;
        case 'zset':
          try {
            final rawZset = await _redisCommand!.send_object(['ZRANGE', key, 0, -1, 'WITHSCORES']);
            value = _processList(rawZset);
          } catch (e) {
            value = 'Error retrieving sorted set: ${e.toString()}';
          }
          break;
        case 'hash':
          try {
            final rawHash = await _redisCommand!.send_object(['HGETALL', key]);
            value = _processHash(rawHash);
          } catch (e) {
            value = 'Error retrieving hash: ${e.toString()}';
          }
          break;
        default:
          value = 'Unsupported type: $type';
      }
      
      setState(() {
        _selectedValue = value;
        _selectedKeyType = type;
        _selectedKeyTTL = ttl == -1 ? null : ttl;
      });
    } catch (e) {
        final conn = RedisConnection();
      _redisCommand = await conn.connect(_activeConnection!.host, _activeConnection!.port);
      _showErrorSnackBar('Failed to load key value: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to safely decode any value
  dynamic _safeDecodeValue(dynamic rawValue) {
    if (rawValue == null) return null;
    
    if (rawValue is String) {
      return rawValue;
    }
    
    if (rawValue is List<int>) {
      return _safeBytesToString(rawValue);
    }
    
    if (rawValue is List) {
      try {
        // Try to convert to List<int> if it's a list of numbers
        final bytes = rawValue.cast<int>();
        return _safeBytesToString(bytes);
      } catch (e) {
        // If casting fails, return as is
        return rawValue.toString();
      }
    }
    
    return rawValue.toString();
  }

  // Helper method to safely convert bytes to string
  String _safeBytesToString(List<int> bytes) {
    try {
      // First try with allowMalformed
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      try {
        // If that fails, try latin1 decoding
        return latin1.decode(bytes);
      } catch (e2) {
        // If all else fails, return as base64
        return 'Binary data (base64): ${base64.encode(bytes)}';
      }
    }
  }

  // Helper method to safely process list data
  dynamic _processList(dynamic rawList) {
    if (rawList is List) {
      return rawList.map((item) => _safeDecodeValue(item)).toList();
    }
    return rawList;
  }

  // Helper method to safely process hash data
  dynamic _processHash(dynamic rawHash) {
    if (rawHash is List) {
      final Map<String, dynamic> result = {};
      for (int i = 0; i < rawHash.length; i += 2) {
        if (i + 1 < rawHash.length) {
          final key = _safeDecodeValue(rawHash[i]);
          final value = _safeDecodeValue(rawHash[i + 1]);
          result[key.toString()] = value;
        }
      }
      return result;
    }
    return rawHash;
  }
  
  Future<void> _executeCommand() async {
    if (!_isConnected || _redisCommand == null) return;
    
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final parts = command.split(' ');
      final result = await _redisCommand!.send_object(parts);
      
      final commandResult = RedisCommandResult(
        command: command,
        result: result,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _commandHistory.insert(0, commandResult);
        if (_commandHistory.length > 100) {
          _commandHistory.removeLast();
        }
      });
      
      _commandController.clear();
      
      // Refresh keys if it was a modifying command
      if (_isModifyingCommand(parts[0].toUpperCase())) {
        await _loadKeys();
      }
    } catch (e) {
      final commandResult = RedisCommandResult(
        command: command,
        isError: true,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _commandHistory.insert(0, commandResult);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isModifyingCommand(String command) {
    const modifyingCommands = {
      'SET', 'DEL', 'EXPIRE', 'PERSIST', 'RENAME', 'LPUSH', 'RPUSH',
      'LPOP', 'RPOP', 'SADD', 'SREM', 'ZADD', 'ZREM', 'HSET', 'HDEL',
      'FLUSHDB', 'FLUSHALL'
    };
    return modifyingCommands.contains(command);
  }

  Future<void> _deleteKey(String key) async {
    if (!_isConnected || _redisCommand == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Key'),
        content: Text('Are you sure you want to delete the key "$key"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _redisCommand!.send_object(['DEL', key]);
        await _loadKeys();
        if (_selectedKey == key) {
          setState(() {
            _selectedKey = '';
            _selectedValue = null;
          });
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete key: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showConnectionDialog([BraderRedisConnection? connection]) {
    final isEditing = connection != null;
    final nameController = TextEditingController(text: connection?.name ?? '');
    final hostController = TextEditingController(text: connection?.host ?? 'localhost');
    final portController = TextEditingController(text: (connection?.port ?? 6379).toString());
    final passwordController = TextEditingController(text: connection?.password ?? '');
    final databaseController = TextEditingController(text: (connection?.database ?? 0).toString());
    bool useSSL = connection?.useSSL ?? false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Connection' : 'New Connection'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Connection Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password (optional)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: databaseController,
                  decoration: const InputDecoration(
                    labelText: 'Database',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Use SSL'),
                  value: useSSL,
                  onChanged: (value) {
                    setDialogState(() {
                      useSSL = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final host = hostController.text.trim();
                final port = int.tryParse(portController.text) ?? 6379;
                final password = passwordController.text.trim();
                final database = int.tryParse(databaseController.text) ?? 0;
                
                if (name.isEmpty || host.isEmpty) {
                  return;
                }
                
                final newConnection = BraderRedisConnection(
                  id: connection?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  host: host,
                  port: port,
                  password: password.isEmpty ? null : password,
                  database: database,
                  useSSL: useSSL,
                  createdAt: connection?.createdAt ?? DateTime.now(),
                  lastUsed: connection?.lastUsed ?? DateTime.now(),
                );
                
                if (isEditing) {
                  final index = _connections.indexWhere((c) => c.id == connection!.id);
                  if (index != -1) {
                    _connections[index] = newConnection;
                  }
                } else {
                  _connections.add(newConnection);
                }
                
                await _saveConnections();
                setState(() {});
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Create'),
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
        title: const Text('Redis Client'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Connections', icon: Icon(Icons.storage)),
            Tab(text: 'Keys', icon: Icon(Icons.key)),
            Tab(text: 'Console', icon: Icon(Icons.terminal)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(8),
            color: _isConnected ? Colors.green.shade100 : Colors.grey.shade100,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusMessage)),
                if (_isConnected)
                  TextButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConnectionsTab(),
                _buildKeysTab(),
                _buildConsoleTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Connections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showConnectionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('New Connection'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _connections.isEmpty
              ? const Center(
                  child: Text('No connections configured.\nClick "New Connection" to add one.'),
                )
              : ListView.builder(
                  itemCount: _connections.length,
                  itemBuilder: (context, index) {
                    final connection = _connections[index];
                    final isActive = _activeConnection?.id == connection.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: isActive ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.storage,
                          color: isActive ? Colors.blue : null,
                        ),
                        title: Text(connection.name),
                        subtitle: Text('${connection.host}:${connection.port}/${connection.database}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              const Icon(Icons.check_circle, color: Colors.green),
                            IconButton(
                              onPressed: () => _showConnectionDialog(connection),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Connection'),
                                    content: Text('Delete connection "${connection.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  if (isActive) {
                                    await _disconnect();
                                  }
                                  _connections.removeAt(index);
                                  await _saveConnections();
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                        onTap: isActive ? null : () => _connectToRedis(connection),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKeysTab() {
    if (!_isConnected) {
      return const Center(
        child: Text('Connect to a Redis server to browse keys'),
      );
    }
    
    return Row(
      children: [
        // Keys list
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search keys',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loadKeys,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _filteredKeys.length,
                        itemBuilder: (context, index) {
                          final keyInfo = _filteredKeys[index];
                          final isSelected = keyInfo.key == _selectedKey;
                          
                          return ListTile(
                            selected: isSelected,
                            leading: Icon(_getTypeIcon(keyInfo.type)),
                            title: Text(keyInfo.key),
                            subtitle: Text('${keyInfo.type}${keyInfo.ttl != null ? ' • TTL: ${keyInfo.ttl}s' : ''}'),
                            trailing: IconButton(
                              onPressed: () => _deleteKey(keyInfo.key),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                            onTap: () => _loadKeyValue(keyInfo.key),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Key value viewer
        Expanded(
          flex: 2,
          child: _selectedKey.isEmpty
              ? const Center(child: Text('Select a key to view its value'))
              : _buildKeyValueViewer(),
        ),
      ],
    );
  }

  Widget _buildKeyValueViewer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getTypeIcon(_selectedKeyType)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedKey,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _selectedKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              Text('Type: $_selectedKeyType'),
              if (_selectedKeyTTL != null)
                Text('TTL: ${_selectedKeyTTL}s')
              else
                const Text('TTL: No expiration'),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildValueEditor(),
          ),
        ),
      ],
    );
  }

  Widget _buildValueEditor() {
    if (_selectedValue == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    String displayValue;
    if (_selectedValue is List) {
      displayValue = _selectedValue.map((e) => e.toString()).join('\n');
    } else if (_selectedValue is Map) {
      displayValue = _selectedValue.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    } else {
      displayValue = _selectedValue.toString();
    }
    
    return Stack(
      children: [
        TextField(
          controller: TextEditingController(text: displayValue),
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          readOnly: true,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: displayValue));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Value copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              iconSize: 18,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: const EdgeInsets.all(4),
              tooltip: 'Copy value',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleTab() {
    if (!_isConnected) {
      return const Center(
        child: Text('Connect to a Redis server to use the console'),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    labelText: 'Redis Command',
                    hintText: 'e.g., GET mykey',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _executeCommand(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _executeCommand,
                child: const Text('Execute'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _commandHistory.isEmpty
              ? const Center(child: Text('No commands executed yet'))
              : ListView.builder(
                  itemCount: _commandHistory.length,
                  itemBuilder: (context, index) {
                    final result = _commandHistory[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  result.isError ? Icons.error : Icons.check_circle,
                                  color: result.isError ? Colors.red : Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  result.command,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  '${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}:${result.timestamp.second.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (result.isError)
                              Text(
                                result.errorMessage ?? 'Unknown error',
                                style: const TextStyle(color: Colors.red),
                              )
                            else
                              Text(result.result?.toString() ?? 'null'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Text('Command history and statistics will be shown here'),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'string':
        return Icons.text_fields;
      case 'list':
        return Icons.list;
      case 'set':
        return Icons.set_meal;
      case 'zset':
        return Icons.sort;
      case 'hash':
        return Icons.tag;
      default:
        return Icons.help;
    }
  }
}
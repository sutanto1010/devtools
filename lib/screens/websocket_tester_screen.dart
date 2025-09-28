import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class WebSocketTesterScreen extends StatefulWidget {
  const WebSocketTesterScreen({super.key});

  @override
  State<WebSocketTesterScreen> createState() => _WebSocketTesterScreenState();
}

class _WebSocketTesterScreenState extends State<WebSocketTesterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Connection management
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  DateTime? _connectedAt;
  DateTime? _lastMessageAt;
  
  // Controllers
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _headerKeyController = TextEditingController();
  final TextEditingController _headerValueController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  
  // Data
  final List<WebSocketMessage> _messages = [];
  final Map<String, String> _headers = {};
  final List<String> _savedConnections = [];
  String _selectedProtocol = 'ws://';
  bool _autoScroll = true;
  bool _showTimestamps = true;
  bool _prettyPrintJson = true;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 3;
  bool _autoReconnect = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Duration _pingInterval = const Duration(seconds: 30);
  bool _enablePing = false;
  
  // Statistics
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _bytesReceived = 0;
  int _bytesSent = 0;
  
  // Syntax highlighting
  Highlighter? _jsonHighlighter;
  bool _isHighlighterReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _urlController.text = 'ws://localhost:8080';
    _initializeHighlighter();
    _loadSavedConnections();
  }

  @override
  void dispose() {
    _disconnect();
    _tabController.dispose();
    _urlController.dispose();
    _messageController.dispose();
    _headerKeyController.dispose();
    _headerValueController.dispose();
    _messagesScrollController.dispose();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeHighlighter() async {
    try {
      await Highlighter.initialize(['json']);
      _jsonHighlighter = Highlighter(
        language: 'json',
        theme: await HighlighterTheme.loadLightTheme(),
      );
      setState(() {
        _isHighlighterReady = true;
      });
    } catch (e) {
      setState(() {
        _isHighlighterReady = false;
      });
    }
  }

  Future<void> _loadSavedConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connections = prefs.getStringList('websocket_connections') ?? [];
    setState(() {
      _savedConnections.clear();
      _savedConnections.addAll(connections);
    });
  }

  Future<void> _saveConnection(String url) async {
    if (!_savedConnections.contains(url)) {
      _savedConnections.insert(0, url);
      if (_savedConnections.length > 10) {
        _savedConnections.removeLast();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('websocket_connections', _savedConnections);
    }
  }

  void _connect() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        throw Exception('URL cannot be empty');
      }

      // Validate URL
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('ws') && !uri.scheme.startsWith('wss'))) {
        throw Exception('Invalid WebSocket URL. Must start with ws:// or wss://');
      }

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(
        uri,
        protocols: _headers.isNotEmpty ? null : null,
      );

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _onMessageReceived,
        onError: _onError,
        onDone: _onDisconnected,
      );

      await _saveConnection(url);

      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _connectionStatus = 'Connected';
        _connectedAt = DateTime.now();
        _reconnectAttempts = 0;
      });

      _addSystemMessage('Connected to $url', MessageType.system);

      // Start ping timer if enabled
      if (_enablePing) {
        _startPingTimer();
      }

    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connection failed';
      });
      _addSystemMessage('Connection failed: $e', MessageType.error);
      
      if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
        _scheduleReconnect();
      }
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Disconnected';
      _connectedAt = null;
    });

    _addSystemMessage('Disconnected', MessageType.system);
  }

  void _onMessageReceived(dynamic message) {
    setState(() {
      _messagesReceived++;
      _bytesReceived += message.toString().length;
      _lastMessageAt = DateTime.now();
    });

    _addMessage(message.toString(), MessageType.received);
  }

  void _onError(error) {
    _addSystemMessage('Error: $error', MessageType.error);
    if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _onDisconnected() {
    setState(() {
      _isConnected = false;
      _connectionStatus = 'Disconnected';
    });
    _addSystemMessage('Connection closed', MessageType.system);
    
    if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    _addSystemMessage('Reconnecting in 5 seconds... (Attempt $_reconnectAttempts/$_maxReconnectAttempts)', MessageType.system);
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        _connect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected) {
        _sendMessage('ping', isPing: true);
      }
    });
  }

  void _sendMessage(String message, {bool isPing = false}) {
    if (!_isConnected || _channel == null) {
      _addSystemMessage('Not connected to WebSocket', MessageType.error);
      return;
    }

    try {
      _channel!.sink.add(message);
      
      setState(() {
        _messagesSent++;
        _bytesSent += message.length;
      });

      if (!isPing) {
        _addMessage(message, MessageType.sent);
      } else {
        _addSystemMessage('Ping sent', MessageType.system);
      }
    } catch (e) {
      _addSystemMessage('Failed to send message: $e', MessageType.error);
    }
  }

  void _addMessage(String content, MessageType type) {
    final message = WebSocketMessage(
      content: content,
      type: type,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_messagesScrollController.hasClients) {
          _messagesScrollController.animateTo(
            _messagesScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _addSystemMessage(String content, MessageType type) {
    _addMessage(content, type);
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
      _messagesSent = 0;
      _messagesReceived = 0;
      _bytesReceived = 0;
      _bytesSent = 0;
    });
  }

  void _addHeader() {
    final key = _headerKeyController.text.trim();
    final value = _headerValueController.text.trim();
    
    if (key.isNotEmpty && value.isNotEmpty) {
      setState(() {
        _headers[key] = value;
      });
      _headerKeyController.clear();
      _headerValueController.clear();
    }
  }

  void _removeHeader(String key) {
    setState(() {
      _headers.remove(key);
    });
  }

  String _formatMessage(String content) {
    if (!_prettyPrintJson) return content;
    
    try {
      final decoded = jsonDecode(content);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      return content;
    }
  }

  Widget _buildConnectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL Input
          Row(
            children: [
              SizedBox(
                width: 80,
                child: DropdownButton<String>(
                  value: _selectedProtocol,
                  items: ['ws://', 'wss://'].map((protocol) {
                    return DropdownMenuItem(
                      value: protocol,
                      child: Text(protocol),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProtocol = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'WebSocket URL',
                    hintText: 'localhost:8080/ws',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isConnecting ? null : (_isConnected ? _disconnect : _connect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isConnected ? 'Disconnect' : 'Connect'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Saved Connections
          if (_savedConnections.isNotEmpty) ...[
            const Text('Recent Connections:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _savedConnections.map((url) {
                return ActionChip(
                  label: Text(url),
                  onPressed: () {
                    _urlController.text = url;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Connection Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.check_circle : Icons.cancel,
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: $_connectionStatus',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_connectedAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Connected at: ${_connectedAt!.toLocal()}'),
                  ],
                  if (_lastMessageAt != null) ...[
                    const SizedBox(height: 4),
                    Text('Last message: ${_lastMessageAt!.toLocal()}'),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Messages Sent: $_messagesSent'),
                            Text('Messages Received: $_messagesReceived'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bytes Sent: $_bytesSent'),
                            Text('Bytes Received: $_bytesReceived'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Connection Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connection Options', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Auto Reconnect'),
                    subtitle: const Text('Automatically reconnect on connection loss'),
                    value: _autoReconnect,
                    onChanged: (value) {
                      setState(() {
                        _autoReconnect = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Enable Ping'),
                    subtitle: const Text('Send periodic ping messages'),
                    value: _enablePing,
                    onChanged: (value) {
                      setState(() {
                        _enablePing = value;
                        if (_enablePing && _isConnected) {
                          _startPingTimer();
                        } else {
                          _pingTimer?.cancel();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        // Message controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Enter message to send',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSubmitted: (_) => _sendCurrentMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _isConnected ? _sendCurrentMessage : null,
                    child: const Text('Send'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _clearMessages,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Message options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Checkbox(
                value: _autoScroll,
                onChanged: (value) {
                  setState(() {
                    _autoScroll = value!;
                  });
                },
              ),
              const Text('Auto Scroll'),
              const SizedBox(width: 16),
              Checkbox(
                value: _showTimestamps,
                onChanged: (value) {
                  setState(() {
                    _showTimestamps = value!;
                  });
                },
              ),
              const Text('Show Timestamps'),
              const SizedBox(width: 16),
              Checkbox(
                value: _prettyPrintJson,
                onChanged: (value) {
                  setState(() {
                    _prettyPrintJson = value!;
                  });
                },
              ),
              const Text('Pretty Print JSON'),
            ],
          ),
        ),
        
        const Divider(),
        
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet. Connect to a WebSocket server and start sending messages.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _messagesScrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageTile(message);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMessageTile(WebSocketMessage message) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (message.type) {
      case MessageType.sent:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.arrow_upward;
        break;
      case MessageType.received:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.arrow_downward;
        break;
      case MessageType.error:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        break;
      case MessageType.system:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
        icon = Icons.info;
        break;
    }

    final formattedContent = _formatMessage(message.content);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                message.type.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 12,
                ),
              ),
              if (_showTimestamps) ...[
                const Spacer(),
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${message.timestamp.minute.toString().padLeft(2, '0')}:'
                  '${message.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isHighlighterReady && _isJsonString(message.content)
              ? _buildHighlightedText(formattedContent)
              : SelectableText(
                  formattedContent,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    try {
      final highlighted = _jsonHighlighter!.highlight(text);
      return SelectableText.rich(
        highlighted,
        style: const TextStyle(fontFamily: 'monospace'),
      );
    } catch (e) {
      return SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace'),
      );
    }
  }

  bool _isJsonString(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _sendCurrentMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _sendMessage(message);
      _messageController.clear();
    }
  }

  Widget _buildHeadersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Headers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Add header form
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _headerKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Header Key',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _headerValueController,
                  decoration: const InputDecoration(
                    labelText: 'Header Value',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addHeader,
                child: const Text('Add'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Headers list
          if (_headers.isEmpty)
            const Center(
              child: Text(
                'No custom headers added',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _headers.length,
                itemBuilder: (context, index) {
                  final key = _headers.keys.elementAt(index);
                  final value = _headers[key]!;
                  
                  return Card(
                    child: ListTile(
                      title: Text(key),
                      subtitle: Text(value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeHeader(key),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reconnection Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Max Reconnect Attempts:'),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: _maxReconnectAttempts.toString()),
                          onChanged: (value) {
                            final attempts = int.tryParse(value);
                            if (attempts != null && attempts > 0) {
                              _maxReconnectAttempts = attempts;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ping Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Ping Interval (seconds):'),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: _pingInterval.inSeconds.toString()),
                          onChanged: (value) {
                            final seconds = int.tryParse(value);
                            if (seconds != null && seconds > 0) {
                              _pingInterval = Duration(seconds: seconds);
                              if (_enablePing && _isConnected) {
                                _startPingTimer();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export/Import', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _exportMessages,
                        child: const Text('Export Messages'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _exportConfiguration,
                        child: const Text('Export Config'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportMessages() {
    final messagesJson = _messages.map((msg) => {
      'type': msg.type.name,
      'content': msg.content,
      'timestamp': msg.timestamp.toIso8601String(),
    }).toList();
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(messagesJson);
    Clipboard.setData(ClipboardData(text: jsonString));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages exported to clipboard')),
    );
  }

  void _exportConfiguration() {
    final config = {
      'url': _urlController.text,
      'headers': _headers,
      'autoReconnect': _autoReconnect,
      'enablePing': _enablePing,
      'pingInterval': _pingInterval.inSeconds,
      'maxReconnectAttempts': _maxReconnectAttempts,
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(config);
    Clipboard.setData(ClipboardData(text: jsonString));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration exported to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Tester'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings_ethernet), text: 'Connection'),
            Tab(icon: Icon(Icons.message), text: 'Messages'),
            Tab(icon: Icon(Icons.http), text: 'Headers'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
          _buildMessagesTab(),
          _buildHeadersTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }
}

class WebSocketMessage {
  final String content;
  final MessageType type;
  final DateTime timestamp;

  WebSocketMessage({
    required this.content,
    required this.type,
    required this.timestamp,
  });
}

enum MessageType {
  sent,
  received,
  error,
  system,
}
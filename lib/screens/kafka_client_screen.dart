import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class KafkaClientScreen extends StatefulWidget {
  const KafkaClientScreen({super.key});

  @override
  State<KafkaClientScreen> createState() => _KafkaClientScreenState();
}

class _KafkaClientScreenState extends State<KafkaClientScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Connection management
  Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  DateTime? _connectedAt;
  
  // Controllers
  final TextEditingController _brokerController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final TextEditingController _offsetController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  final ScrollController _topicsScrollController = ScrollController();
  
  // Data
  final List<KafkaMessage> _messages = [];
  final List<KafkaTopic> _topics = [];
  final List<KafkaConnection> _savedConnections = [];
  final Map<String, String> _producerConfig = {};
  final Map<String, String> _consumerConfig = {};
  
  // Settings
  String _selectedBroker = '';
  String _selectedTopic = '';
  int _selectedPartition = 0;
  bool _autoScroll = true;
  bool _showTimestamps = true;
  bool _prettyPrintJson = true;
  bool _isProducing = false;
  bool _isConsuming = false;
  String _offsetReset = 'latest'; // earliest, latest
  
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
    _tabController = TabController(length: 5, vsync: this);
    _brokerController.text = 'localhost:9092';
    _groupIdController.text = 'devtools-consumer-group';
    _offsetController.text = '0';
    _initializeHighlighter();
    _loadSavedConnections();
    _loadProducerConfig();
    _loadConsumerConfig();
  }

  @override
  void dispose() {
    _disconnect();
    _tabController.dispose();
    _brokerController.dispose();
    _topicController.dispose();
    _messageController.dispose();
    _keyController.dispose();
    _groupIdController.dispose();
    _offsetController.dispose();
    _messagesScrollController.dispose();
    _topicsScrollController.dispose();
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
    final connectionsJson = prefs.getStringList('kafka_connections') ?? [];
    
    setState(() {
      _savedConnections.clear();
      for (final json in connectionsJson) {
        try {
          _savedConnections.add(KafkaConnection.fromJson(jsonDecode(json)));
        } catch (e) {
          // Skip invalid connections
        }
      }
    });
  }

  Future<void> _saveConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = _savedConnections
        .map((conn) => jsonEncode(conn.toJson()))
        .toList();
    
    await prefs.setStringList('kafka_connections', connectionsJson);
  }

  Future<void> _loadProducerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('kafka_producer_config');
    if (configJson != null) {
      try {
        final config = Map<String, String>.from(jsonDecode(configJson));
        setState(() {
          _producerConfig.clear();
          _producerConfig.addAll(config);
        });
      } catch (e) {
        // Use default config
      }
    }
  }

  Future<void> _loadConsumerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('kafka_consumer_config');
    if (configJson != null) {
      try {
        final config = Map<String, String>.from(jsonDecode(configJson));
        setState(() {
          _consumerConfig.clear();
          _consumerConfig.addAll(config);
        });
      } catch (e) {
        // Use default config
      }
    }
  }

  Future<void> _saveProducerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kafka_producer_config', jsonEncode(_producerConfig));
  }

  Future<void> _saveConsumerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kafka_consumer_config', jsonEncode(_consumerConfig));
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      final brokerParts = _brokerController.text.split(':');
      final host = brokerParts[0];
      final port = brokerParts.length > 1 ? int.parse(brokerParts[1]) : 9092;
      
      _socket = await Socket.connect(host, port);
      
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _connectionStatus = 'Connected';
        _connectedAt = DateTime.now();
      });
      
      // Load topics after connection
      await _loadTopics();
      
      _showSnackBar('Connected to Kafka broker successfully', Colors.green);
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _connectionStatus = 'Connection failed: ${e.toString()}';
      });
      _showSnackBar('Failed to connect: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
    
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _isConsuming = false;
      _isProducing = false;
      _connectionStatus = 'Disconnected';
      _connectedAt = null;
    });
  }

  Future<void> _loadTopics() async {
    if (!_isConnected) return;
    
    try {
      // Simulate loading topics (in a real implementation, this would use Kafka protocol)
      setState(() {
        _topics.clear();
        _topics.addAll([
          KafkaTopic(name: 'test-topic', partitions: 3, replicas: 1),
          KafkaTopic(name: 'user-events', partitions: 6, replicas: 2),
          KafkaTopic(name: 'system-logs', partitions: 1, replicas: 1),
          KafkaTopic(name: 'analytics', partitions: 12, replicas: 3),
        ]);
      });
    } catch (e) {
      _showSnackBar('Failed to load topics: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _createTopic() async {
    if (!_isConnected || _topicController.text.isEmpty) return;
    
    try {
      // Simulate topic creation
      final newTopic = KafkaTopic(
        name: _topicController.text,
        partitions: 1,
        replicas: 1,
      );
      
      setState(() {
        _topics.add(newTopic);
      });
      
      _topicController.clear();
      _showSnackBar('Topic created successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to create topic: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _produceMessage() async {
    if (!_isConnected || _selectedTopic.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar('Please connect and select a topic first', Colors.orange);
      return;
    }
    
    setState(() {
      _isProducing = true;
    });
    
    try {
      final message = KafkaMessage(
        topic: _selectedTopic,
        partition: _selectedPartition,
        offset: _messagesSent,
        key: _keyController.text.isEmpty ? null : _keyController.text,
        value: _messageController.text,
        timestamp: DateTime.now(),
        headers: {},
      );
      
      // Simulate message production
      await Future.delayed(const Duration(milliseconds: 100));
      
      setState(() {
        _messages.insert(0, message);
        _messagesSent++;
        _bytesSent += _messageController.text.length;
      });
      
      _messageController.clear();
      _keyController.clear();
      
      if (_autoScroll) {
        _scrollToTop();
      }
      
      _showSnackBar('Message sent successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to send message: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isProducing = false;
      });
    }
  }

  Future<void> _startConsuming() async {
    if (!_isConnected || _selectedTopic.isEmpty) {
      _showSnackBar('Please connect and select a topic first', Colors.orange);
      return;
    }
    
    setState(() {
      _isConsuming = true;
    });
    
    // Simulate consuming messages
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isConsuming || !_isConnected) {
        timer.cancel();
        return;
      }
      
      // Simulate receiving a message
      final message = KafkaMessage(
        topic: _selectedTopic,
        partition: 0,
        offset: _messagesReceived,
        key: 'key-${_messagesReceived}',
        value: '{"id": ${_messagesReceived}, "message": "Sample message", "timestamp": "${DateTime.now().toIso8601String()}"}',
        timestamp: DateTime.now(),
        headers: {'source': 'kafka-simulator'},
      );
      
      setState(() {
        _messages.insert(0, message);
        _messagesReceived++;
        _bytesReceived += message.value.length;
      });
      
      if (_autoScroll) {
        _scrollToTop();
      }
    });
    
    _showSnackBar('Started consuming messages', Colors.green);
  }

  void _stopConsuming() {
    setState(() {
      _isConsuming = false;
    });
    _showSnackBar('Stopped consuming messages', Colors.orange);
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

  void _scrollToTop() {
    if (_messagesScrollController.hasClients) {
      _messagesScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildConnectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _brokerController,
                    decoration: const InputDecoration(
                      labelText: 'Broker Address',
                      hintText: 'localhost:9092',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isConnected,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isConnecting ? null : (_isConnected ? _disconnect : _connect),
                        icon: _isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_isConnected ? Icons.link_off : Icons.link),
                        label: Text(_isConnecting ? 'Connecting...' : (_isConnected ? 'Disconnect' : 'Connect')),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Status: $_connectionStatus',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_connectedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Connected at: ${_connectedAt!.toString()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Messages Sent', _messagesSent.toString(), Icons.send),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Messages Received', _messagesReceived.toString(), Icons.inbox),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Bytes Sent', _formatBytes(_bytesSent), Icons.upload),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('Bytes Received', _formatBytes(_bytesReceived), Icons.download),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Topic',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            labelText: 'Topic Name',
                            hintText: 'my-topic',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isConnected,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isConnected ? _createTopic : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          'Topics',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _isConnected ? _loadTopics : null,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh Topics',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _topics.isEmpty
                        ? const Center(
                            child: Text('No topics available. Connect to see topics.'),
                          )
                        : ListView.builder(
                            controller: _topicsScrollController,
                            itemCount: _topics.length,
                            itemBuilder: (context, index) {
                              final topic = _topics[index];
                              final isSelected = topic.name == _selectedTopic;
                              
                              return ListTile(
                                selected: isSelected,
                                leading: const Icon(Icons.topic),
                                title: Text(topic.name),
                                subtitle: Text('Partitions: ${topic.partitions}, Replicas: ${topic.replicas}'),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                onTap: () {
                                  setState(() {
                                    _selectedTopic = topic.name;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducerTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producer',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTopic.isEmpty ? null : _selectedTopic,
                          decoration: const InputDecoration(
                            labelText: 'Topic',
                            border: OutlineInputBorder(),
                          ),
                          items: _topics.map((topic) {
                            return DropdownMenuItem(
                              value: topic.name,
                              child: Text(topic.name),
                            );
                          }).toList(),
                          onChanged: _isConnected ? (value) {
                            setState(() {
                              _selectedTopic = value ?? '';
                            });
                          } : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Partition',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _selectedPartition = int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keyController,
                    decoration: const InputDecoration(
                      labelText: 'Message Key (Optional)',
                      hintText: 'user-123',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isConnected,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message Value',
                      hintText: '{"id": 1, "name": "John Doe"}',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    enabled: _isConnected,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isConnected && !_isProducing ? _produceMessage : null,
                        icon: _isProducing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isProducing ? 'Sending...' : 'Send Message'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          _messageController.text = '{\n  "id": 1,\n  "message": "Hello Kafka!",\n  "timestamp": "${DateTime.now().toIso8601String()}"\n}';
                        },
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Sample JSON'),
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

  Widget _buildConsumerTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consumer',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTopic.isEmpty ? null : _selectedTopic,
                          decoration: const InputDecoration(
                            labelText: 'Topic',
                            border: OutlineInputBorder(),
                          ),
                          items: _topics.map((topic) {
                            return DropdownMenuItem(
                              value: topic.name,
                              child: Text(topic.name),
                            );
                          }).toList(),
                          onChanged: _isConnected ? (value) {
                            setState(() {
                              _selectedTopic = value ?? '';
                            });
                          } : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _groupIdController,
                          decoration: const InputDecoration(
                            labelText: 'Consumer Group',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isConnected,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _offsetReset,
                          decoration: const InputDecoration(
                            labelText: 'Offset Reset',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'earliest', child: Text('Earliest')),
                            DropdownMenuItem(value: 'latest', child: Text('Latest')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _offsetReset = value ?? 'latest';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _offsetController,
                          decoration: const InputDecoration(
                            labelText: 'Start Offset (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: _isConnected,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isConnected && !_isConsuming ? _startConsuming : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Consuming'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isConsuming ? _stopConsuming : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Consuming'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildMessagesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Switch(
                        value: _showTimestamps,
                        onChanged: (value) {
                          setState(() {
                            _showTimestamps = value;
                          });
                        },
                      ),
                      const Text('Timestamps'),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Switch(
                        value: _prettyPrintJson,
                        onChanged: (value) {
                          setState(() {
                            _prettyPrintJson = value;
                          });
                        },
                      ),
                      const Text('Pretty JSON'),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Switch(
                        value: _autoScroll,
                        onChanged: (value) {
                          setState(() {
                            _autoScroll = value;
                          });
                        },
                      ),
                      const Text('Auto Scroll'),
                    ],
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _clearMessages,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text('No messages yet. Start producing or consuming messages.'),
                    )
                  : ListView.builder(
                      controller: _messagesScrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageCard(message);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(KafkaMessage message) {
    String displayValue = message.value;
    
    if (_prettyPrintJson && _isValidJson(message.value)) {
      try {
        final jsonObject = jsonDecode(message.value);
        displayValue = const JsonEncoder.withIndent('  ').convert(jsonObject);
      } catch (e) {
        // Keep original value if JSON parsing fails
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                message.topic,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text('Partition: ${message.partition}'),
            const SizedBox(width: 8),
            Text('Offset: ${message.offset}'),
            if (message.key != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Key: ${message.key}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        subtitle: _showTimestamps
            ? Text(
                message.timestamp.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.value));
                        _showSnackBar('Message value copied to clipboard', Colors.green);
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: _isHighlighterReady && _isValidJson(message.value)
                      ? SelectableText.rich(
                          _jsonHighlighter!.highlight(displayValue),
                          style: const TextStyle(fontFamily: 'monospace'),
                        )
                      : SelectableText(
                          displayValue,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                ),
                if (message.headers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Headers:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...message.headers.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kafka Client'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.link), text: 'Connection'),
            Tab(icon: Icon(Icons.topic), text: 'Topics'),
            Tab(icon: Icon(Icons.send), text: 'Producer'),
            Tab(icon: Icon(Icons.inbox), text: 'Consumer'),
            Tab(icon: Icon(Icons.message), text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
          _buildTopicsTab(),
          _buildProducerTab(),
          _buildConsumerTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }
}

// Data models
class KafkaMessage {
  final String topic;
  final int partition;
  final int offset;
  final String? key;
  final String value;
  final DateTime timestamp;
  final Map<String, String> headers;

  KafkaMessage({
    required this.topic,
    required this.partition,
    required this.offset,
    this.key,
    required this.value,
    required this.timestamp,
    required this.headers,
  });

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'partition': partition,
      'offset': offset,
      'key': key,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'headers': headers,
    };
  }

  factory KafkaMessage.fromJson(Map<String, dynamic> json) {
    return KafkaMessage(
      topic: json['topic'],
      partition: json['partition'],
      offset: json['offset'],
      key: json['key'],
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      headers: Map<String, String>.from(json['headers'] ?? {}),
    );
  }
}

class KafkaTopic {
  final String name;
  final int partitions;
  final int replicas;

  KafkaTopic({
    required this.name,
    required this.partitions,
    required this.replicas,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'partitions': partitions,
      'replicas': replicas,
    };
  }

  factory KafkaTopic.fromJson(Map<String, dynamic> json) {
    return KafkaTopic(
      name: json['name'],
      partitions: json['partitions'],
      replicas: json['replicas'],
    );
  }
}

class KafkaConnection {
  final String name;
  final String brokers;
  final Map<String, String> properties;

  KafkaConnection({
    required this.name,
    required this.brokers,
    required this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brokers': brokers,
      'properties': properties,
    };
  }

  factory KafkaConnection.fromJson(Map<String, dynamic> json) {
    return KafkaConnection(
      name: json['name'],
      brokers: json['brokers'],
      properties: Map<String, String>.from(json['properties'] ?? {}),
    );
  }
}
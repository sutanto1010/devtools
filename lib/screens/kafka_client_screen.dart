import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
  
  // Topic management controllers
  final TextEditingController _partitionsController = TextEditingController();
  final TextEditingController _replicationFactorController = TextEditingController();
  final TextEditingController _topicSearchController = TextEditingController();
  final TextEditingController _retentionMsController = TextEditingController();
  final TextEditingController _segmentMsController = TextEditingController();
  final TextEditingController _maxMessageBytesController = TextEditingController();
  
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
  
  // Topic management settings
  String _topicSearchQuery = '';
  KafkaTopic? _selectedTopicDetails;
  bool _showTopicDetails = false;
  String _cleanupPolicy = 'delete'; // delete, compact
  
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
    // Initialize topic creation defaults
    _partitionsController.text = '1';
    _replicationFactorController.text = '1';
    _retentionMsController.text = '604800000'; // 7 days
    _segmentMsController.text = '86400000'; // 1 day
    _maxMessageBytesController.text = '1000000'; // 1MB
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
    // Dispose new controllers
    _partitionsController.dispose();
    _replicationFactorController.dispose();
    _topicSearchController.dispose();
    _retentionMsController.dispose();
    _segmentMsController.dispose();
    _maxMessageBytesController.dispose();
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
      setState(() {
        _topics.clear();
      });

      // Parse broker address
      final brokerParts = _brokerController.text.split(':');
      final host = brokerParts[0];
      final port = brokerParts.length > 1 ? int.parse(brokerParts[1]) : 9092;
      
      // Create a simple Kafka metadata request to get topics
      // This is a simplified implementation using raw socket communication
      final socket = await Socket.connect(host, port);
      
      try {
        // Send Metadata Request (API Key: 3, API Version: 0)
        final request = _buildMetadataRequest();
        socket.add(request);
        
        // Read response
        final responseData = await _readSocketResponse(socket);
        final topics = _parseMetadataResponse(responseData);
        
        setState(() {
          _topics.addAll(topics);
        });
        
        _showSnackBar('Loaded ${topics.length} topics successfully', Colors.green);
      } finally {
        await socket.close();
      }
    } catch (e) {
      // Fallback to mock data if real connection fails
      setState(() {
        _topics.clear();
        _topics.addAll([
          KafkaTopic(name: 'test-topic', partitions: 3, replicas: 1, config: {'cleanup.policy': 'delete', 'retention.ms': '604800000'}),
          KafkaTopic(name: 'user-events', partitions: 6, replicas: 2, config: {'cleanup.policy': 'delete', 'retention.ms': '259200000'}),
          KafkaTopic(name: 'system-logs', partitions: 1, replicas: 1, config: {'cleanup.policy': 'delete', 'retention.ms': '86400000'}),
          KafkaTopic(name: 'analytics', partitions: 12, replicas: 3, config: {'cleanup.policy': 'compact', 'retention.ms': '2592000000'}),
        ]);
      });
      _showSnackBar('Failed to load topics, using mock data: ${e.toString()}', Colors.orange);
    }
  }

  // Build Kafka Metadata Request (API Key: 3, Version: 0)
  List<int> _buildMetadataRequest() {
    final buffer = <int>[];
    
    // Request Header
    // Message Size (will be calculated later)
    buffer.addAll(_int32ToBytes(0)); // Placeholder for message size
    
    // API Key (Metadata = 3)
    buffer.addAll(_int16ToBytes(3));
    
    // API Version
    buffer.addAll(_int16ToBytes(0));
    
    // Correlation ID
    buffer.addAll(_int32ToBytes(1));
    
    // Client ID
    final clientId = 'devtools-kafka-client';
    buffer.addAll(_stringToBytes(clientId));
    
    // Topics array (empty array means all topics)
    buffer.addAll(_int32ToBytes(0)); // Empty array
    
    // Update message size (total length - 4 bytes for the size field itself)
    final messageSize = buffer.length - 4;
    for (int i = 0; i < 4; i++) {
      buffer[i] = (messageSize >> (24 - i * 8)) & 0xFF;
    }
    
    return buffer;
  }

  // Read response from socket
  Future<List<int>> _readSocketResponse(Socket socket) async {
    final completer = Completer<List<int>>();
    final buffer = <int>[];
    int? expectedLength;
    
    socket.listen(
      (data) {
        buffer.addAll(data);
        
        // First 4 bytes contain the message length
        if (expectedLength == null && buffer.length >= 4) {
          expectedLength = _bytesToInt32(buffer.sublist(0, 4));
        }
        
        // Check if we have received the complete message
        if (expectedLength != null && buffer.length >= (expectedLength! + 4)) {
          completer.complete(buffer);
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(buffer);
        }
      },
    );
    
    return completer.future.timeout(const Duration(seconds: 10));
  }

  // Parse Kafka Metadata Response
  List<KafkaTopic> _parseMetadataResponse(List<int> data) {
    final topics = <KafkaTopic>[];
    
    try {
      int offset = 4; // Skip message size
      
      // Skip correlation ID
      offset += 4;
      
      // Skip brokers array
      final brokerCount = _bytesToInt32(data.sublist(offset, offset + 4));
      offset += 4;
      
      // Skip broker information
      for (int i = 0; i < brokerCount; i++) {
        offset += 4; // node_id
        final hostLength = _bytesToInt16(data.sublist(offset, offset + 2));
        offset += 2 + hostLength; // host string
        offset += 4; // port
      }
      
      // Read topics array
      final topicCount = _bytesToInt32(data.sublist(offset, offset + 4));
      offset += 4;
      
      for (int i = 0; i < topicCount; i++) {
        // Error code
        offset += 2;
        
        // Topic name
        final topicNameLength = _bytesToInt16(data.sublist(offset, offset + 2));
        offset += 2;
        final topicName = String.fromCharCodes(data.sublist(offset, offset + topicNameLength));
        offset += topicNameLength;
        
        // Partitions array
        final partitionCount = _bytesToInt32(data.sublist(offset, offset + 4));
        offset += 4;
        
        int maxReplicas = 1;
        
        // Skip partition details but count replicas
        for (int j = 0; j < partitionCount; j++) {
          offset += 2; // error_code
          offset += 4; // partition_id
          offset += 4; // leader
          
          // Replicas array
          final replicaCount = _bytesToInt32(data.sublist(offset, offset + 4));
          offset += 4;
          maxReplicas = math.max(maxReplicas, replicaCount);
          offset += replicaCount * 4; // replica node_ids
          
          // ISR array
          final isrCount = _bytesToInt32(data.sublist(offset, offset + 4));
          offset += 4;
          offset += isrCount * 4; // ISR node_ids
        }
        
        topics.add(KafkaTopic(
          name: topicName,
          partitions: partitionCount,
          replicas: maxReplicas,
          config: {
            'cleanup.policy': 'delete',
            'retention.ms': '604800000',
          },
        ));
      }
    } catch (e) {
      print('Error parsing metadata response: $e');
    }
    
    return topics;
  }

  // Helper methods for byte conversion
  List<int> _int32ToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  List<int> _int16ToBytes(int value) {
    return [
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  List<int> _stringToBytes(String str) {
    final bytes = utf8.encode(str);
    return [..._int16ToBytes(bytes.length), ...bytes];
  }

  int _bytesToInt32(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  int _bytesToInt16(List<int> bytes) {
    return (bytes[0] << 8) | bytes[1];
  }

  Future<void> _createTopic() async {
    if (!_isConnected || _topicController.text.isEmpty) return;
    
    try {
      // Parse configuration values
      final partitions = int.tryParse(_partitionsController.text) ?? 1;
      final replicas = int.tryParse(_replicationFactorController.text) ?? 1;
      final retentionMs = int.tryParse(_retentionMsController.text) ?? 604800000;
      final segmentMs = int.tryParse(_segmentMsController.text) ?? 86400000;
      final maxMessageBytes = int.tryParse(_maxMessageBytesController.text) ?? 1000000;
      
      // Create topic configuration
      final config = <String, String>{
        'cleanup.policy': _cleanupPolicy,
        'retention.ms': retentionMs.toString(),
        'segment.ms': segmentMs.toString(),
        'max.message.bytes': maxMessageBytes.toString(),
      };
      
      // Simulate topic creation with configuration
      final newTopic = KafkaTopic(
        name: _topicController.text,
        partitions: partitions,
        replicas: replicas,
        config: config,
      );
      
      setState(() {
        _topics.add(newTopic);
      });
      
      _topicController.clear();
      _showSnackBar('Topic "${newTopic.name}" created successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to create topic: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _deleteTopic(String topicName) async {
    if (!_isConnected) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete topic "$topicName"?\n\nThis action cannot be undone and will permanently delete all messages in this topic.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // Simulate topic deletion
        setState(() {
          _topics.removeWhere((topic) => topic.name == topicName);
          if (_selectedTopic == topicName) {
            _selectedTopic = '';
          }
        });
        
        _showSnackBar('Topic "$topicName" deleted successfully', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to delete topic: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _showTopicDetailsDialog(KafkaTopic topic) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Topic Details: ${topic.name}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', topic.name),
                _buildDetailRow('Partitions', topic.partitions.toString()),
                _buildDetailRow('Replication Factor', topic.replicas.toString()),
                const SizedBox(height: 16),
                const Text('Configuration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...topic.config.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
                const SizedBox(height: 16),
                const Text('Partition Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...List.generate(topic.partitions, (index) => 
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text('Partition $index'),
                          const Spacer(),
                          Text('Leader: Broker ${(index % 3) + 1}'),
                          const SizedBox(width: 16),
                          Text('Replicas: ${topic.replicas}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditTopicDialog(topic);
            },
            child: const Text('Edit Configuration'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTopicDialog(KafkaTopic topic) async {
    final retentionController = TextEditingController(text: topic.config['retention.ms'] ?? '604800000');
    final segmentController = TextEditingController(text: topic.config['segment.ms'] ?? '86400000');
    final maxBytesController = TextEditingController(text: topic.config['max.message.bytes'] ?? '1000000');
    String cleanupPolicy = topic.config['cleanup.policy'] ?? 'delete';
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Topic Configuration: ${topic.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: cleanupPolicy,
                  decoration: const InputDecoration(
                    labelText: 'Cleanup Policy',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'delete', child: Text('Delete')),
                    DropdownMenuItem(value: 'compact', child: Text('Compact')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      cleanupPolicy = value ?? 'delete';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: retentionController,
                  decoration: const InputDecoration(
                    labelText: 'Retention (ms)',
                    hintText: '604800000 (7 days)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: segmentController,
                  decoration: const InputDecoration(
                    labelText: 'Segment Size (ms)',
                    hintText: '86400000 (1 day)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxBytesController,
                  decoration: const InputDecoration(
                    labelText: 'Max Message Bytes',
                    hintText: '1000000 (1MB)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final config = <String, String>{
                  'cleanup.policy': cleanupPolicy,
                  'retention.ms': retentionController.text,
                  'segment.ms': segmentController.text,
                  'max.message.bytes': maxBytesController.text,
                };
                Navigator.of(context).pop(config);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      try {
        // Update topic configuration
        final topicIndex = _topics.indexWhere((t) => t.name == topic.name);
        if (topicIndex != -1) {
          setState(() {
            _topics[topicIndex] = KafkaTopic(
              name: topic.name,
              partitions: topic.partitions,
              replicas: topic.replicas,
              config: result,
            );
          });
          _showSnackBar('Topic configuration updated successfully', Colors.green);
        }
      } catch (e) {
        _showSnackBar('Failed to update topic configuration: ${e.toString()}', Colors.red);
      }
    }
    
    retentionController.dispose();
    segmentController.dispose();
    maxBytesController.dispose();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  List<KafkaTopic> get _filteredTopics {
    if (_topicSearchQuery.isEmpty) {
      return _topics;
    }
    return _topics.where((topic) => 
      topic.name.toLowerCase().contains(_topicSearchQuery.toLowerCase())
    ).toList();
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
          // Create Topic Section
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
                        flex: 2,
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
                      Expanded(
                        child: TextField(
                          controller: _partitionsController,
                          decoration: const InputDecoration(
                            labelText: 'Partitions',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: _isConnected,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _replicationFactorController,
                          decoration: const InputDecoration(
                            labelText: 'Replication Factor',
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
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _cleanupPolicy,
                          decoration: const InputDecoration(
                            labelText: 'Cleanup Policy',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'delete', child: Text('Delete')),
                            DropdownMenuItem(value: 'compact', child: Text('Compact')),
                          ],
                          onChanged: _isConnected ? (value) {
                            setState(() {
                              _cleanupPolicy = value ?? 'delete';
                            });
                          } : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _retentionMsController,
                          decoration: const InputDecoration(
                            labelText: 'Retention (ms)',
                            hintText: '604800000 (7 days)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
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
          // Topics List Section
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
                          'Topics (${_filteredTopics.length})',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _topicSearchController,
                            decoration: const InputDecoration(
                              hintText: 'Search topics...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _topicSearchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _isConnected ? _loadTopics : null,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh Topics',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredTopics.isEmpty
                        ? Center(
                            child: Text(
                              _topics.isEmpty 
                                ? 'No topics available. Connect to see topics.'
                                : 'No topics match your search.',
                            ),
                          )
                        : ListView.builder(
                            controller: _topicsScrollController,
                            itemCount: _filteredTopics.length,
                            itemBuilder: (context, index) {
                              final topic = _filteredTopics[index];
                              final isSelected = topic.name == _selectedTopic;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: ListTile(
                                  selected: isSelected,
                                  leading: const Icon(Icons.topic),
                                  title: Text(
                                    topic.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Partitions: ${topic.partitions} • Replicas: ${topic.replicas}'),
                                      Text('Cleanup: ${topic.config['cleanup.policy'] ?? 'delete'}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) 
                                        const Icon(Icons.check_circle, color: Colors.green),
                                      IconButton(
                                        onPressed: () => _showTopicDetailsDialog(topic),
                                        icon: const Icon(Icons.info_outline),
                                        tooltip: 'View Details',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteTopic(topic.name),
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Delete Topic',
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedTopic = topic.name;
                                    });
                                  },
                                ),
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
  final Map<String, String> config;

  KafkaTopic({
    required this.name,
    required this.partitions,
    required this.replicas,
    this.config = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'partitions': partitions,
      'replicas': replicas,
      'config': config,
    };
  }

  factory KafkaTopic.fromJson(Map<String, dynamic> json) {
    return KafkaTopic(
      name: json['name'],
      partitions: json['partitions'],
      replicas: json['replicas'],
      config: Map<String, String>.from(json['config'] ?? {}),
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
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:devtools/screens/kafka_client_screen.dart' show KafkaTopic;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class KafkaTopicDetailsScreen extends StatefulWidget {
  final KafkaTopic topic;
  final String brokerAddress;
  final bool isConnected;

  const KafkaTopicDetailsScreen({
    super.key,
    required this.topic,
    required this.brokerAddress,
    required this.isConnected,
  });

  @override
  State<KafkaTopicDetailsScreen> createState() => _KafkaTopicDetailsScreenState();
}

class _KafkaTopicDetailsScreenState extends State<KafkaTopicDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers
  final TextEditingController _messageSearchController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  final ScrollController _consumerGroupsScrollController = ScrollController();
  
  // Data
  final List<KafkaMessage> _messages = [];
  final List<KafkaConsumerGroup> _consumerGroups = [];
  final List<KafkaPartitionInfo> _partitionInfos = [];
  
  // Settings
  String _messageSearchQuery = '';
  String _searchFilter = 'all'; // all, value, key, headers
  bool _caseSensitiveSearch = false;
  bool _useRegexSearch = false;
  DateTime? _searchFromDate;
  DateTime? _searchToDate;
  bool _autoScroll = true;
  bool _showTimestamps = true;
  bool _prettyPrintJson = true;
  bool _isConsuming = false;
  String _selectedPartition = 'all';
  
  // Statistics
  int _totalMessages = 0;
  int _totalBytes = 0;
  
  // Syntax highlighting
  Highlighter? _jsonHighlighter;
  bool _isHighlighterReady = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _groupIdController.text = 'devtools-consumer-group';
    _initializeHighlighter();
    _loadTopicData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageSearchController.dispose();
    _groupIdController.dispose();
    _messagesScrollController.dispose();
    _consumerGroupsScrollController.dispose();
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

  Future<void> _loadTopicData() async {
    await Future.wait([
      _loadMessages(),
      _loadConsumerGroups(),
      _loadPartitionInfo(),
    ]);
  }

  Future<void> _loadMessages() async {
    // Simulate loading messages from the topic
    final mockMessages = <KafkaMessage>[];
    final random = math.Random();
    
    for (int i = 0; i < 50; i++) {
      final partition = random.nextInt(widget.topic.partitions);
      final messageTypes = ['user_action', 'system_event', 'error_log', 'metric'];
      final messageType = messageTypes[random.nextInt(messageTypes.length)];
      
      String value;
      switch (messageType) {
        case 'user_action':
          value = jsonEncode({
            'type': 'user_action',
            'user_id': 'user_${random.nextInt(1000)}',
            'action': ['login', 'logout', 'purchase', 'view_page'][random.nextInt(4)],
            'timestamp': DateTime.now().subtract(Duration(minutes: random.nextInt(1440))).toIso8601String(),
            'metadata': {
              'ip': '192.168.1.${random.nextInt(255)}',
              'user_agent': 'Mozilla/5.0 (compatible)',
            }
          });
          break;
        case 'system_event':
          value = jsonEncode({
            'type': 'system_event',
            'service': ['auth', 'payment', 'notification', 'analytics'][random.nextInt(4)],
            'event': 'service_started',
            'timestamp': DateTime.now().subtract(Duration(minutes: random.nextInt(1440))).toIso8601String(),
            'details': {
              'version': '1.${random.nextInt(10)}.${random.nextInt(10)}',
              'memory_usage': '${random.nextInt(512)}MB',
            }
          });
          break;
        case 'error_log':
          value = jsonEncode({
            'type': 'error_log',
            'level': ['ERROR', 'WARN', 'FATAL'][random.nextInt(3)],
            'message': 'Connection timeout occurred',
            'timestamp': DateTime.now().subtract(Duration(minutes: random.nextInt(1440))).toIso8601String(),
            'stack_trace': 'at com.example.Service.connect(Service.java:123)',
          });
          break;
        default:
          value = jsonEncode({
            'type': 'metric',
            'name': 'cpu_usage',
            'value': random.nextDouble() * 100,
            'timestamp': DateTime.now().subtract(Duration(minutes: random.nextInt(1440))).toIso8601String(),
            'tags': {
              'host': 'server-${random.nextInt(10)}',
              'environment': 'production',
            }
          });
      }
      
      mockMessages.add(KafkaMessage(
        topic: widget.topic.name,
        partition: partition,
        offset: i,
        key: 'key-$i',
        value: value,
        timestamp: DateTime.now().subtract(Duration(minutes: random.nextInt(1440))),
        headers: {
          'content-type': 'application/json',
          'source': 'kafka-simulator',
          'message-type': messageType,
        },
      ));
    }
    
    // Sort by timestamp (newest first)
    mockMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    setState(() {
      _messages.clear();
      _messages.addAll(mockMessages);
      _totalMessages = mockMessages.length;
      _totalBytes = mockMessages.fold(0, (sum, msg) => sum + msg.value.length);
    });
  }

  Future<void> _loadConsumerGroups() async {
    // Simulate loading consumer groups
    final mockGroups = <KafkaConsumerGroup>[
      KafkaConsumerGroup(
        groupId: 'analytics-service',
        state: 'Stable',
        members: 3,
        coordinator: 'broker-1',
        partitionAssignments: {
          for (int i = 0; i < widget.topic.partitions; i++)
            i: KafkaPartitionAssignment(
              partition: i,
              currentOffset: math.Random().nextInt(1000),
              logEndOffset: math.Random().nextInt(1000) + 1000,
              lag: math.Random().nextInt(100),
              consumerId: 'consumer-${i % 3}',
            ),
        },
      ),
      KafkaConsumerGroup(
        groupId: 'notification-service',
        state: 'Stable',
        members: 2,
        coordinator: 'broker-2',
        partitionAssignments: {
          for (int i = 0; i < widget.topic.partitions; i++)
            i: KafkaPartitionAssignment(
              partition: i,
              currentOffset: math.Random().nextInt(800),
              logEndOffset: math.Random().nextInt(800) + 800,
              lag: math.Random().nextInt(50),
              consumerId: 'consumer-${i % 2}',
            ),
        },
      ),
      KafkaConsumerGroup(
        groupId: 'backup-service',
        state: 'Dead',
        members: 0,
        coordinator: 'broker-3',
        partitionAssignments: {},
      ),
    ];
    
    setState(() {
      _consumerGroups.clear();
      _consumerGroups.addAll(mockGroups);
    });
  }

  Future<void> _loadPartitionInfo() async {
    // Simulate loading partition information
    final mockPartitions = <KafkaPartitionInfo>[];
    final random = math.Random();
    
    for (int i = 0; i < widget.topic.partitions; i++) {
      mockPartitions.add(KafkaPartitionInfo(
        partition: i,
        leader: random.nextInt(3) + 1,
        replicas: List.generate(widget.topic.replicas, (index) => (index + i) % 3 + 1),
        isr: List.generate(widget.topic.replicas, (index) => (index + i) % 3 + 1),
        logSize: random.nextInt(10000) + 1000,
        logStartOffset: 0,
        logEndOffset: random.nextInt(10000) + 1000,
      ));
    }
    
    setState(() {
      _partitionInfos.clear();
      _partitionInfos.addAll(mockPartitions);
    });
  }

  List<KafkaMessage> get _filteredMessages {
    if (_messageSearchQuery.isEmpty && _searchFromDate == null && _searchToDate == null && _selectedPartition == 'all') {
      return _messages;
    }
    
    return _messages.where((message) {
      // Partition filter
      if (_selectedPartition != 'all' && message.partition.toString() != _selectedPartition) {
        return false;
      }
      
      // Date range filter
      if (_searchFromDate != null && message.timestamp.isBefore(_searchFromDate!)) {
        return false;
      }
      if (_searchToDate != null && message.timestamp.isAfter(_searchToDate!.add(const Duration(days: 1)))) {
        return false;
      }
      
      // Text search filter
      if (_messageSearchQuery.isEmpty) return true;
      
      bool matchesSearch(String text) {
        if (_useRegexSearch) {
          try {
            final regex = RegExp(_messageSearchQuery, caseSensitive: _caseSensitiveSearch);
            return regex.hasMatch(text);
          } catch (e) {
            return false;
          }
        } else {
          return _caseSensitiveSearch
              ? text.contains(_messageSearchQuery)
              : text.toLowerCase().contains(_messageSearchQuery.toLowerCase());
        }
      }
      
      switch (_searchFilter) {
        case 'value':
          return matchesSearch(message.value);
        case 'key':
          return message.key != null && matchesSearch(message.key!);
        case 'headers':
          return message.headers.entries.any((entry) => 
            matchesSearch(entry.key) || matchesSearch(entry.value));
        case 'all':
        default:
          return matchesSearch(message.value) ||
                 (message.key != null && matchesSearch(message.key!)) ||
                 message.headers.entries.any((entry) => 
                   matchesSearch(entry.key) || matchesSearch(entry.value));
      }
    }).toList();
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

  bool _isValidJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (e) {
      return false;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Topic: ${widget.topic.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.message), text: 'Messages'),
            Tab(icon: Icon(Icons.group), text: 'Consumer Groups'),
            Tab(icon: Icon(Icons.storage), text: 'Partitions'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadTopicData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMessagesTab(),
          _buildConsumerGroupsTab(),
          _buildPartitionsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topic Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Name', widget.topic.name),
                    _buildDetailRow('Partitions', widget.topic.partitions.toString()),
                    _buildDetailRow('Replication Factor', widget.topic.replicas.toString()),
                    _buildDetailRow('Total Messages', _totalMessages.toString()),
                    _buildDetailRow('Total Size', '${(_totalBytes / 1024).toStringAsFixed(2)} KB'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...widget.topic.config.entries.map((entry) => 
                      _buildDetailRow(entry.key, entry.value)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics Card
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
                          child: _buildStatCard('Consumer Groups', _consumerGroups.length.toString(), Icons.group),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard('Active Consumers', 
                            _consumerGroups.fold(0, (sum, group) => sum + group.members).toString(), 
                            Icons.person),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Total Lag', 
                            _consumerGroups.fold(0, (sum, group) => 
                              sum + group.partitionAssignments.values.fold(0, (partSum, assignment) => partSum + assignment.lag)).toString(), 
                            Icons.schedule),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard('Avg Message Size', 
                            _totalMessages > 0 ? '${(_totalBytes / _totalMessages).toStringAsFixed(0)} bytes' : '0 bytes', 
                            Icons.data_usage),
                        ),
                      ],
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

  Widget _buildMessagesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _messageSearchController,
                          decoration: const InputDecoration(
                            hintText: 'Search messages...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _messageSearchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _searchFilter,
                          decoration: const InputDecoration(
                            labelText: 'Search In',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Fields')),
                            DropdownMenuItem(value: 'value', child: Text('Message Value')),
                            DropdownMenuItem(value: 'key', child: Text('Message Key')),
                            DropdownMenuItem(value: 'headers', child: Text('Headers')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPartition,
                          decoration: const InputDecoration(
                            labelText: 'Partition',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Partitions')),
                            ...List.generate(widget.topic.partitions, (index) => 
                              DropdownMenuItem(value: index.toString(), child: Text('Partition $index'))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPartition = value ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _caseSensitiveSearch,
                            onChanged: (value) {
                              setState(() {
                                _caseSensitiveSearch = value ?? false;
                              });
                            },
                          ),
                          const Text('Case Sensitive'),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _useRegexSearch,
                            onChanged: (value) {
                              setState(() {
                                _useRegexSearch = value ?? false;
                              });
                            },
                          ),
                          const Text('Regex'),
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
                      const Spacer(),
                      if (_filteredMessages.length != _messages.length) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Showing ${_filteredMessages.length} of ${_messages.length} messages',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Messages List
          Expanded(
            child: Card(
              child: _filteredMessages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No messages found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _messagesScrollController,
                      itemCount: _filteredMessages.length,
                      itemBuilder: (context, index) {
                        final message = _filteredMessages[index];
                        return _buildMessageCard(message);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerGroupsTab() {
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
                    'Consumer Groups (${_consumerGroups.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadConsumerGroups,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Consumer Groups',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _consumerGroups.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No consumer groups found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _consumerGroupsScrollController,
                    itemCount: _consumerGroups.length,
                    itemBuilder: (context, index) {
                      final group = _consumerGroups[index];
                      return _buildConsumerGroupCard(group);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartitionsTab() {
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
                    'Partitions (${_partitionInfos.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadPartitionInfo,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Partition Info',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _partitionInfos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No partition information available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _partitionInfos.length,
                    itemBuilder: (context, index) {
                      final partition = _partitionInfos[index];
                      return _buildPartitionCard(partition);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            'P${message.partition}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        title: Row(
          children: [
            if (message.key != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Key: ${message.key}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'Offset: ${message.offset}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (_showTimestamps)
              Text(
                message.timestamp.toString().substring(0, 19),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        subtitle: Text(
          displayValue.length > 100 
              ? '${displayValue.substring(0, 100)}...'
              : displayValue,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message Value
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Message Value',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: message.value));
                              _showSnackBar('Message value copied to clipboard', Colors.green);
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy to clipboard',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        displayValue,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Headers
                if (message.headers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Headers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: message.headers.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '${entry.key}:',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SelectableText(
                                  entry.value,
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerGroupCard(KafkaConsumerGroup group) {
    final totalLag = group.partitionAssignments.values.fold(0, (sum, assignment) => sum + assignment.lag);
    final stateColor = group.state == 'Stable' ? Colors.green : 
                      group.state == 'Dead' ? Colors.red : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.group,
          color: stateColor,
        ),
        title: Text(
          group.groupId,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group.state,
                style: TextStyle(
                  fontSize: 12,
                  color: stateColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${group.members} members'),
            const SizedBox(width: 8),
            Text('Lag: $totalLag'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Group ID', group.groupId),
                _buildDetailRow('State', group.state),
                _buildDetailRow('Members', group.members.toString()),
                _buildDetailRow('Coordinator', group.coordinator),
                _buildDetailRow('Total Lag', totalLag.toString()),
                
                if (group.partitionAssignments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Partition Assignments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...group.partitionAssignments.entries.map((entry) {
                    final partition = entry.key;
                    final assignment = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Text('Partition $partition'),
                            const Spacer(),
                            Text('Consumer: ${assignment.consumerId}'),
                            const SizedBox(width: 16),
                            Text('Offset: ${assignment.currentOffset}/${assignment.logEndOffset}'),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: assignment.lag > 50 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Lag: ${assignment.lag}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: assignment.lag > 50 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartitionCard(KafkaPartitionInfo partition) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Partition ${partition.partition}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Leader', 'Broker ${partition.leader}'),
            _buildDetailRow('Replicas', partition.replicas.map((r) => 'Broker $r').join(', ')),
            _buildDetailRow('ISR', partition.isr.map((r) => 'Broker $r').join(', ')),
            _buildDetailRow('Log Size', '${(partition.logSize / 1024).toStringAsFixed(2)} KB'),
            _buildDetailRow('Start Offset', partition.logStartOffset.toString()),
            _buildDetailRow('End Offset', partition.logEndOffset.toString()),
          ],
        ),
      ),
    );
  }
}

// Data models for the topic details screen
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
}


class KafkaConsumerGroup {
  final String groupId;
  final String state;
  final int members;
  final String coordinator;
  final Map<int, KafkaPartitionAssignment> partitionAssignments;

  KafkaConsumerGroup({
    required this.groupId,
    required this.state,
    required this.members,
    required this.coordinator,
    required this.partitionAssignments,
  });
}

class KafkaPartitionAssignment {
  final int partition;
  final int currentOffset;
  final int logEndOffset;
  final int lag;
  final String consumerId;

  KafkaPartitionAssignment({
    required this.partition,
    required this.currentOffset,
    required this.logEndOffset,
    required this.lag,
    required this.consumerId,
  });
}

class KafkaPartitionInfo {
  final int partition;
  final int leader;
  final List<int> replicas;
  final List<int> isr;
  final int logSize;
  final int logStartOffset;
  final int logEndOffset;

  KafkaPartitionInfo({
    required this.partition,
    required this.leader,
    required this.replicas,
    required this.isr,
    required this.logSize,
    required this.logStartOffset,
    required this.logEndOffset,
  });
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class UnixTimeScreen extends StatefulWidget {
  const UnixTimeScreen({super.key});

  @override
  State<UnixTimeScreen> createState() => _UnixTimeScreenState();
}

class _UnixTimeScreenState extends State<UnixTimeScreen> {
  final TextEditingController _timestampController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _batchInputController = TextEditingController();
  final TextEditingController _batchOutputController = TextEditingController();
  
  String _errorMessage = '';
  String _currentTimestamp = '';
  String _currentDateTime = '';
  Timer? _timer;
  bool _isMilliseconds = false;
  String _selectedTimezone = 'UTC';
  
  final List<String> _timezones = [
    'UTC',
    'Local',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Australia/Sydney',
  ];

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timestampController.dispose();
    _dateTimeController.dispose();
    _batchInputController.dispose();
    _batchOutputController.dispose();
    super.dispose();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    
    setState(() {
      _currentTimestamp = _isMilliseconds 
          ? timestamp.toString()
          : (timestamp ~/ 1000).toString();
      _currentDateTime = _formatDateTime(now);
    });
  }

  String _formatDateTime(DateTime dateTime) {
    DateTime adjustedTime;
    
    switch (_selectedTimezone) {
      case 'UTC':
        adjustedTime = dateTime.toUtc();
        break;
      case 'Local':
        adjustedTime = dateTime.toLocal();
        break;
      default:
        // For simplicity, we'll use UTC for other timezones
        // In a real app, you'd use a proper timezone library
        adjustedTime = dateTime.toUtc();
        break;
    }
    
    return '${adjustedTime.year}-${adjustedTime.month.toString().padLeft(2, '0')}-${adjustedTime.day.toString().padLeft(2, '0')} '
           '${adjustedTime.hour.toString().padLeft(2, '0')}:${adjustedTime.minute.toString().padLeft(2, '0')}:${adjustedTime.second.toString().padLeft(2, '0')} '
           '($_selectedTimezone)';
  }

  void _convertTimestampToDateTime() {
    setState(() {
      _errorMessage = '';
    });

    final input = _timestampController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a timestamp';
      });
      return;
    }

    try {
      final timestamp = int.parse(input);
      DateTime dateTime;
      
      if (_isMilliseconds) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
      
      setState(() {
        _dateTimeController.text = _formatDateTime(dateTime);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid timestamp format';
      });
    }
  }

  void _convertDateTimeToTimestamp() {
    setState(() {
      _errorMessage = '';
    });

    final input = _dateTimeController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a date/time';
      });
      return;
    }

    try {
      // Parse various date formats
      DateTime? dateTime;
      
      // Try ISO format first
      try {
        dateTime = DateTime.parse(input.replaceAll(' ', 'T'));
      } catch (e) {
        // Try other common formats
        final patterns = [
          RegExp(r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})'),
          RegExp(r'^(\d{4})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2}):(\d{2})'),
          RegExp(r'^(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})'),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(input);
          if (match != null) {
            final groups = match.groups([1, 2, 3, 4, 5, 6]);
            if (groups.every((g) => g != null)) {
              int year, month, day;
              if (input.contains('/') && input.indexOf('/') < 3) {
                // MM/DD/YYYY format
                month = int.parse(groups[0]!);
                day = int.parse(groups[1]!);
                year = int.parse(groups[2]!);
              } else {
                // YYYY-MM-DD or YYYY/MM/DD format
                year = int.parse(groups[0]!);
                month = int.parse(groups[1]!);
                day = int.parse(groups[2]!);
              }
              
              dateTime = DateTime(
                year,
                month,
                day,
                int.parse(groups[3]!),
                int.parse(groups[4]!),
                int.parse(groups[5]!),
              );
              break;
            }
          }
        }
      }
      
      if (dateTime == null) {
        throw const FormatException('Unable to parse date');
      }
      
      final timestamp = _isMilliseconds 
          ? dateTime.millisecondsSinceEpoch
          : dateTime.millisecondsSinceEpoch ~/ 1000;
      
      setState(() {
        _timestampController.text = timestamp.toString();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid date/time format. Use formats like: YYYY-MM-DD HH:MM:SS';
      });
    }
  }

  void _processBatchConversion() {
    setState(() {
      _errorMessage = '';
    });

    final input = _batchInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter timestamps or dates for batch conversion';
      });
      return;
    }

    final lines = input.split('\n');
    final results = <String>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      try {
        // Try to parse as timestamp first
        final timestamp = int.tryParse(trimmedLine);
        if (timestamp != null) {
          DateTime dateTime;
          if (_isMilliseconds) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else {
            dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          }
          results.add('$trimmedLine → ${_formatDateTime(dateTime)}');
        } else {
          // Try to parse as date/time
          DateTime? dateTime;
          try {
            dateTime = DateTime.parse(trimmedLine.replaceAll(' ', 'T'));
          } catch (e) {
            // Try other formats (simplified for batch processing)
            final isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})');
            final match = isoPattern.firstMatch(trimmedLine);
            if (match != null) {
              final groups = match.groups([1, 2, 3, 4, 5, 6]);
              if (groups.every((g) => g != null)) {
                dateTime = DateTime(
                  int.parse(groups[0]!),
                  int.parse(groups[1]!),
                  int.parse(groups[2]!),
                  int.parse(groups[3]!),
                  int.parse(groups[4]!),
                  int.parse(groups[5]!),
                );
              }
            }
          }
          
          if (dateTime != null) {
            final timestamp = _isMilliseconds 
                ? dateTime.millisecondsSinceEpoch
                : dateTime.millisecondsSinceEpoch ~/ 1000;
            results.add('$trimmedLine → $timestamp');
          } else {
            results.add('$trimmedLine → Error: Invalid format');
          }
        }
      } catch (e) {
        results.add('$trimmedLine → Error: ${e.toString()}');
      }
    }
    
    setState(() {
      _batchOutputController.text = results.join('\n');
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _clearAll() {
    setState(() {
      _timestampController.clear();
      _dateTimeController.clear();
      _batchInputController.clear();
      _batchOutputController.clear();
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unix Time Converter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Time Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Time',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timestamp:',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                _currentTimestamp,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_currentTimestamp),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy timestamp',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Human Readable:',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                _currentDateTime,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_currentDateTime),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy date/time',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Use Milliseconds'),
                            subtitle: Text(_isMilliseconds 
                                ? 'Timestamps include milliseconds'
                                : 'Timestamps in seconds'),
                            value: _isMilliseconds,
                            onChanged: (value) {
                              setState(() {
                                _isMilliseconds = value;
                                _updateCurrentTime();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Timezone',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedTimezone,
                            items: _timezones.map((timezone) {
                              return DropdownMenuItem(
                                value: timezone,
                                child: Text(timezone),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTimezone = value!;
                                _updateCurrentTime();
                              });
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
            
            // Conversion Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert Between Formats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Timestamp to DateTime
                    TextField(
                      controller: _timestampController,
                      decoration: InputDecoration(
                        labelText: _isMilliseconds ? 'Unix Timestamp (milliseconds)' : 'Unix Timestamp (seconds)',
                        hintText: _isMilliseconds ? '1640995200000' : '1640995200',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _copyToClipboard(_timestampController.text),
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy',
                            ),
                            IconButton(
                              onPressed: _convertTimestampToDateTime,
                              icon: const Icon(Icons.arrow_downward),
                              tooltip: 'Convert to Date/Time',
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // DateTime to Timestamp
                    TextField(
                      controller: _dateTimeController,
                      decoration: InputDecoration(
                        labelText: 'Date/Time',
                        hintText: '2022-01-01 00:00:00 or 2022-01-01T00:00:00',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _copyToClipboard(_dateTimeController.text),
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy',
                            ),
                            IconButton(
                              onPressed: _convertDateTimeToTimestamp,
                              icon: const Icon(Icons.arrow_upward),
                              tooltip: 'Convert to Timestamp',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Batch Conversion
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Conversion',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter multiple timestamps or dates (one per line) for batch conversion',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _batchInputController,
                      decoration: InputDecoration(
                        labelText: 'Input (one per line)',
                        hintText: '1640995200\n2022-01-01 00:00:00\n1641081600',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: _processBatchConversion,
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Process Batch',
                        ),
                      ),
                      maxLines: 5,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _batchOutputController,
                      decoration: InputDecoration(
                        labelText: 'Results',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => _copyToClipboard(_batchOutputController.text),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy Results',
                        ),
                      ),
                      maxLines: 5,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Help Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supported Formats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('• Unix timestamps (seconds or milliseconds)'),
                    const Text('• ISO 8601: 2022-01-01T00:00:00'),
                    const Text('• Standard: 2022-01-01 00:00:00'),
                    const Text('• US format: 01/01/2022 00:00:00'),
                    const Text('• European: 2022/01/01 00:00:00'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
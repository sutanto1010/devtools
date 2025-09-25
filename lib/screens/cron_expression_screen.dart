import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CronExpressionScreen extends StatefulWidget {
  const CronExpressionScreen({super.key});

  @override
  State<CronExpressionScreen> createState() => _CronExpressionScreenState();
}

class _CronExpressionScreenState extends State<CronExpressionScreen> {
  final TextEditingController _cronController = TextEditingController();
  String _englishDescription = '';
  List<DateTime> _nextOccurrences = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cronController.text = '0 9 * * 1-5'; // Default: 9 AM on weekdays
    _parseCronExpression();
  }

  void _parseCronExpression() {
    setState(() {
      _errorMessage = '';
      try {
        final cronExpression = _cronController.text.trim();
        if (cronExpression.isEmpty) {
          _englishDescription = '';
          _nextOccurrences = [];
          return;
        }

        _englishDescription = _convertCronToEnglish(cronExpression);
        _nextOccurrences = _calculateNextOccurrences(cronExpression, 10);
      } catch (e) {
        _errorMessage = 'Invalid CRON expression: ${e.toString()}';
        _englishDescription = '';
        _nextOccurrences = [];
      }
    });
  }

  String _convertCronToEnglish(String cronExpression) {
    final parts = cronExpression.split(' ');
    if (parts.length != 5) {
      throw Exception('CRON expression must have 5 parts (minute hour day month weekday)');
    }

    final minute = parts[0];
    final hour = parts[1];
    final day = parts[2];
    final month = parts[3];
    final weekday = parts[4];

    String description = 'Run ';

    // Time part
    if (minute == '*' && hour == '*') {
      description += 'every minute';
    } else if (minute != '*' && hour == '*') {
      description += 'at ${_parseMinute(minute)} of every hour';
    } else if (minute == '*' && hour != '*') {
      description += 'every minute during ${_parseHour(hour)}';
    } else {
      description += 'at ${_parseTime(hour, minute)}';
    }

    // Day/weekday part
    if (day != '*' && weekday != '*') {
      description += ' on ${_parseDay(day)} and ${_parseWeekday(weekday)}';
    } else if (day != '*') {
      description += ' on ${_parseDay(day)}';
    } else if (weekday != '*') {
      description += ' on ${_parseWeekday(weekday)}';
    } else {
      description += ' every day';
    }

    // Month part
    if (month != '*') {
      description += ' in ${_parseMonth(month)}';
    }

    return description;
  }

  String _parseMinute(String minute) {
    if (minute == '*') return 'every minute';
    if (minute.contains('/')) {
      final parts = minute.split('/');
      return 'every ${parts[1]} minutes';
    }
    if (minute.contains(',')) {
      return 'minutes ${minute.replaceAll(',', ', ')}';
    }
    if (minute.contains('-')) {
      return 'minutes ${minute.replaceAll('-', ' to ')}';
    }
    return 'minute $minute';
  }

  String _parseHour(String hour) {
    if (hour == '*') return 'every hour';
    if (hour.contains('/')) {
      final parts = hour.split('/');
      return 'every ${parts[1]} hours';
    }
    if (hour.contains(',')) {
      final hours = hour.split(',').map((h) => _formatHour(int.parse(h))).join(', ');
      return hours;
    }
    if (hour.contains('-')) {
      final parts = hour.split('-');
      return '${_formatHour(int.parse(parts[0]))} to ${_formatHour(int.parse(parts[1]))}';
    }
    return _formatHour(int.parse(hour));
  }

  String _parseTime(String hour, String minute) {
    if (hour.contains(',') || minute.contains(',')) {
      return 'specified times';
    }
    final h = int.parse(hour);
    final m = int.parse(minute);
    return _formatTime(h, m);
  }

  String _parseDay(String day) {
    if (day == '*') return 'every day';
    if (day.contains('/')) {
      final parts = day.split('/');
      return 'every ${parts[1]} days';
    }
    if (day.contains(',')) {
      return 'days ${day.replaceAll(',', ', ')}';
    }
    if (day.contains('-')) {
      return 'days ${day.replaceAll('-', ' to ')}';
    }
    return 'day $day';
  }

  String _parseWeekday(String weekday) {
    if (weekday == '*') return 'every day of the week';
    
    final weekdays = {
      '0': 'Sunday', '1': 'Monday', '2': 'Tuesday', '3': 'Wednesday',
      '4': 'Thursday', '5': 'Friday', '6': 'Saturday', '7': 'Sunday'
    };

    if (weekday.contains(',')) {
      final days = weekday.split(',').map((d) => weekdays[d] ?? d).join(', ');
      return days;
    }
    if (weekday.contains('-')) {
      final parts = weekday.split('-');
      return '${weekdays[parts[0]] ?? parts[0]} to ${weekdays[parts[1]] ?? parts[1]}';
    }
    if (weekday == '1-5') return 'weekdays';
    if (weekday == '6-7' || weekday == '0,6') return 'weekends';
    
    return weekdays[weekday] ?? weekday;
  }

  String _parseMonth(String month) {
    if (month == '*') return 'every month';
    
    final months = {
      '1': 'January', '2': 'February', '3': 'March', '4': 'April',
      '5': 'May', '6': 'June', '7': 'July', '8': 'August',
      '9': 'September', '10': 'October', '11': 'November', '12': 'December'
    };

    if (month.contains(',')) {
      final monthNames = month.split(',').map((m) => months[m] ?? m).join(', ');
      return monthNames;
    }
    if (month.contains('-')) {
      final parts = month.split('-');
      return '${months[parts[0]] ?? parts[0]} to ${months[parts[1]] ?? parts[1]}';
    }
    
    return months[month] ?? month;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _formatTime(int hour, int minute) {
    final hourStr = _formatHour(hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr'.replaceAll(' AM:', ':').replaceAll(' PM:', ':') + 
           (hour < 12 ? ' AM' : ' PM');
  }

  List<DateTime> _calculateNextOccurrences(String cronExpression, int count) {
    final parts = cronExpression.split(' ');
    if (parts.length != 5) return [];

    final occurrences = <DateTime>[];
    var current = DateTime.now();
    
    // Simple implementation - for production, use a proper CRON library
    for (int i = 0; i < count * 100 && occurrences.length < count; i++) {
      current = current.add(const Duration(minutes: 1));
      if (_matchesCronExpression(current, parts)) {
        occurrences.add(current);
      }
    }
    
    return occurrences;
  }

  bool _matchesCronExpression(DateTime dateTime, List<String> parts) {
    final minute = parts[0];
    final hour = parts[1];
    final day = parts[2];
    final month = parts[3];
    final weekday = parts[4];

    // Check minute
    if (!_matchesField(dateTime.minute.toString(), minute)) return false;
    
    // Check hour
    if (!_matchesField(dateTime.hour.toString(), hour)) return false;
    
    // Check day
    if (!_matchesField(dateTime.day.toString(), day)) return false;
    
    // Check month
    if (!_matchesField(dateTime.month.toString(), month)) return false;
    
    // Check weekday (0 = Sunday, 1 = Monday, etc.)
    final dayOfWeek = dateTime.weekday == 7 ? 0 : dateTime.weekday;
    if (!_matchesField(dayOfWeek.toString(), weekday)) return false;
    
    return true;
  }

  bool _matchesField(String value, String pattern) {
    if (pattern == '*') return true;
    
    if (pattern.contains(',')) {
      return pattern.split(',').contains(value);
    }
    
    if (pattern.contains('-')) {
      final parts = pattern.split('-');
      final start = int.parse(parts[0]);
      final end = int.parse(parts[1]);
      final val = int.parse(value);
      return val >= start && val <= end;
    }
    
    if (pattern.contains('/')) {
      final parts = pattern.split('/');
      final step = int.parse(parts[1]);
      final val = int.parse(value);
      return val % step == 0;
    }
    
    return pattern == value;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _cronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                    Text(
                      'CRON Expression',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cronController,
                      decoration: const InputDecoration(
                        hintText: 'Enter CRON expression (e.g., 0 9 * * 1-5)',
                        border: OutlineInputBorder(),
                        helperText: 'Format: minute hour day month weekday',
                      ),
                      onChanged: (_) => _parseCronExpression(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cronController.text = '0 9 * * 1-5',
                            child: const Text('Weekdays 9 AM'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cronController.text = '0 0 1 * *',
                            child: const Text('Monthly'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cronController.text = '*/15 * * * *',
                            child: const Text('Every 15 min'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (_englishDescription.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'English Description',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(_englishDescription),
                            tooltip: 'Copy description',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _englishDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_nextOccurrences.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next ${_nextOccurrences.length} Occurrences',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _nextOccurrences.length,
                            itemBuilder: (context, index) {
                              final occurrence = _nextOccurrences[index];
                              final now = DateTime.now();
                              final difference = occurrence.difference(now);
                              
                              String timeUntil = '';
                              if (difference.inDays > 0) {
                                timeUntil = 'in ${difference.inDays} days';
                              } else if (difference.inHours > 0) {
                                timeUntil = 'in ${difference.inHours} hours';
                              } else if (difference.inMinutes > 0) {
                                timeUntil = 'in ${difference.inMinutes} minutes';
                              } else {
                                timeUntil = 'now';
                              }
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(
                                  '${occurrence.day}/${occurrence.month}/${occurrence.year} '
                                  '${_formatTime(occurrence.hour, occurrence.minute)}',
                                ),
                                subtitle: Text(
                                  '${_getDayName(occurrence.weekday)} - $timeUntil',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => _copyToClipboard(
                                    occurrence.toIso8601String(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }
}
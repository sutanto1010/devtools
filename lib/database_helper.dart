import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'devtools_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tool_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id TEXT NOT NULL,
        tool_title TEXT NOT NULL,
        tool_description TEXT NOT NULL,
        tool_icon_code_point INTEGER NOT NULL,
        session_data TEXT,
        timestamp INTEGER NOT NULL,
        usage_count INTEGER DEFAULT 1
      )
    ''');
  }

  Future<void> addToolUsage({
    required String toolId,
    required String toolTitle,
    required String toolDescription,
    required int iconCodePoint,
    Map<String, dynamic>? sessionData,
  }) async {
    final db = await database;
    
    // Check if tool already exists in history
    final existing = await db.query(
      'tool_history',
      where: 'tool_id = ?',
      whereArgs: [toolId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing record
      await db.update(
        'tool_history',
        {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'usage_count': (existing.first['usage_count'] as int ) + 1,
          'session_data': sessionData != null ? json.encode(sessionData) : null,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Insert new record
      await db.insert(
        'tool_history',
        {
          'tool_id': toolId,
          'tool_title': toolTitle,
          'tool_description': toolDescription,
          'tool_icon_code_point': iconCodePoint,
          'session_data': sessionData != null ? json.encode(sessionData) : null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'usage_count': 1,
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTools({int limit = 10}) async {
    final db = await database;
    final result = await db.query(
      'tool_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return result.map((row) => {
      'id': row['tool_id'],
      'title': row['tool_title'],
      'description': row['tool_description'],
      'iconCodePoint': row['tool_icon_code_point'] as int,
      'sessionData': row['session_data'] != null 
          ? json.decode(row['session_data'] as String) 
          : null,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      'usageCount': row['usage_count'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await database;
    final result = await db.query(
      'tool_history',
      orderBy: 'timestamp DESC',
    );
    
    return result.map((row) => {
      'id': row['tool_id'],
      'title': row['tool_title'],
      'description': row['tool_description'],
      'iconCodePoint': row['tool_icon_code_point'] as int,
      'sessionData': row['session_data'] != null 
          ? json.decode(row['session_data'] as String) 
          : null,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      'usageCount': row['usage_count'],
    }).toList();
  }

  Future<Map<String, dynamic>?> getToolSessionData(String toolId) async {
    final db = await database;
    final result = await db.query(
      'tool_history',
      where: 'tool_id = ?',
      whereArgs: [toolId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (result.isNotEmpty && result.first['session_data'] != null) {
      return json.decode(result.first['session_data'] as String);
    }
    return null;
  }

  Future<void> updateToolSessionData(String toolId, Map<String, dynamic> sessionData) async {
    final db = await database;
    await db.update(
      'tool_history',
      {
        'session_data': json.encode(sessionData),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'tool_id = ?',
      whereArgs: [toolId],
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('tool_history');
  }

  Future<void> deleteToolHistory(String toolId) async {
    final db = await database;
    await db.delete(
      'tool_history',
      where: 'tool_id = ?',
      whereArgs: [toolId],
    );
  }
}
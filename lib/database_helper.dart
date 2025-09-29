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
      version: 2, // Increment version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Remove usage_count column and recreate table for individual entries
      await db.execute('DROP TABLE IF EXISTS tool_history');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> addToolUsage({
    required String toolId,
    required String toolTitle,
    required String toolDescription,
    required int iconCodePoint,
    Map<String, dynamic>? sessionData,
  }) async {
    final db = await database;
    
    // Always insert new record for individual history tracking
    await db.insert(
      'tool_history',
      {
        'tool_id': toolId,
        'tool_title': toolTitle,
        'tool_description': toolDescription,
        'tool_icon_code_point': iconCodePoint,
        'session_data': sessionData != null ? json.encode(sessionData) : null,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRecentTools({int limit = 10}) async {
    final db = await database;
    // Get the most recent entry per tool_id, then order by timestamp DESC and limit
    final result = await db.rawQuery('''
      SELECT * FROM tool_history
      WHERE id IN (
        SELECT MAX(id) FROM tool_history GROUP BY tool_id
      )
      AND tool_id NOT LIKE '%screenshot%'
      ORDER BY timestamp DESC
      LIMIT ?
    ''', [limit]);

    return result.map((row) => {
      'id': row['tool_id'],
      'title': row['tool_title'],
      'description': row['tool_description'],
      'iconCodePoint': row['tool_icon_code_point'] as int,
      'sessionData': row['session_data'] != null 
          ? json.decode(row['session_data'] as String) 
          : null,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      'historyId': row['id'], // Add unique history ID
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
      'historyId': row['id'], // Add unique history ID
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
    // Update the most recent entry for this tool
    final recentEntry = await db.query(
      'tool_history',
      where: 'tool_id = ?',
      whereArgs: [toolId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (recentEntry.isNotEmpty) {
      await db.update(
        'tool_history',
        {
          'session_data': json.encode(sessionData),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [recentEntry.first['id']],
      );
    }
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

  Future<void> deleteHistoryItem(int historyId) async {
    final db = await database;
    await db.delete(
      'tool_history',
      where: 'id = ?',
      whereArgs: [historyId],
    );
  }
}
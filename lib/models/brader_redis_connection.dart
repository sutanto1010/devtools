class BraderRedisConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? password;
  final int database;
  final bool useSSL;
  final int connectionTimeout;
  final DateTime createdAt;
  final DateTime lastUsed;

  BraderRedisConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.password,
    this.database = 0,
    this.useSSL = false,
    this.connectionTimeout = 5000,
    required this.createdAt,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'password': password,
      'database': database,
      'useSSL': useSSL ? 1 : 0,
      'connectionTimeout': connectionTimeout,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUsed': lastUsed.millisecondsSinceEpoch,
    };
  }

  factory BraderRedisConnection.fromJson(Map<String, dynamic> json) {
    return BraderRedisConnection(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      port: json['port'],
      password: json['password'],
      database: json['database'] ?? 0,
      useSSL: (json['useSSL'] ?? 0) == 1,
      connectionTimeout: json['connectionTimeout'] ?? 5000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(json['lastUsed']),
    );
  }

  BraderRedisConnection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? password,
    int? database,
    bool? useSSL,
    int? connectionTimeout,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return BraderRedisConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      password: password ?? this.password,
      database: database ?? this.database,
      useSSL: useSSL ?? this.useSSL,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  String get connectionString {
    final auth = password != null && password!.isNotEmpty ? ':$password@' : '';
    final protocol = useSSL ? 'rediss' : 'redis';
    return '$protocol://$auth$host:$port/$database';
  }
}

class RedisKeyInfo {
  final String key;
  final String type;
  final int? ttl;
  final int? size;

  RedisKeyInfo({
    required this.key,
    required this.type,
    this.ttl,
    this.size,
  });
}

class RedisCommandResult {
  final String command;
  final dynamic result;
  final bool isError;
  final String? errorMessage;
  final DateTime timestamp;

  RedisCommandResult({
    required this.command,
    this.result,
    this.isError = false,
    this.errorMessage,
    required this.timestamp,
  });
}
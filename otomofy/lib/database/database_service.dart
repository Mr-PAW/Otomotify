import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GameRecord {
  final int? id;
  final int timeMs;
  final DateTime completedAt;

  GameRecord({this.id, required this.timeMs, required this.completedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time_ms': timeMs,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory GameRecord.fromMap(Map<String, dynamic> map) {
    return GameRecord(
      id: map['id'],
      timeMs: map['time_ms'],
      completedAt: DateTime.parse(map['completed_at']),
    );
  }

  String get formattedTime {
    final seconds = (timeMs / 1000).floor();
    final ms = (timeMs % 1000) ~/ 10;
    return '${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}s';
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'car_maze.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE game_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time_ms INTEGER NOT NULL,
            completed_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertRecord(int timeMs) async {
    final db = await database;
    await db.insert('game_records', {
      'time_ms': timeMs,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<GameRecord>> getRecords() async {
    final db = await database;
    final maps = await db.query(
      'game_records',
      orderBy: 'time_ms ASC',
      limit: 10,
    );
    return maps.map((m) => GameRecord.fromMap(m)).toList();
  }

  Future<GameRecord?> getBestRecord() async {
    final db = await database;
    final maps = await db.query(
      'game_records',
      orderBy: 'time_ms ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GameRecord.fromMap(maps.first);
  }

  Future<void> clearRecords() async {
    final db = await database;
    await db.delete('game_records');
  }
}

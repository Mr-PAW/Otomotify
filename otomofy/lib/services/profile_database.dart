import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ProfileDatabase {
  static final ProfileDatabase instance = ProfileDatabase._init();

  static Database? _database;

  ProfileDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('profile_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE profiles (
  userId TEXT PRIMARY KEY,
  nama TEXT,
  username TEXT,
  email TEXT,
  phone TEXT,
  profile_picture TEXT
)
''');
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    await db.insert(
      'profiles',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'profiles',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }
}

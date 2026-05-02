import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DbHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  _initDb() async {
    String path = join(await getDatabasesPath(), 'otomotify.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          password TEXT
        )
      ''');
      },
    );
  }

  // Fungsi buat nge-hash password (biar nggak plain text di DB)
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // ubah string ke bytes
    var digest = sha256.convert(bytes); // proses hashing
    return digest.toString();
  }

  // Fungsi Register (Buat testing aja biar ada isinya)
  Future<int> registerUser(String user, String pass) async {
    var dbClient = await db;
    return await dbClient.insert('users', {
      'username': user,
      'password': hashPassword(pass),
    });
  }

  // Fungsi Login
  Future<bool> login(String user, String pass) async {
    var dbClient = await db;
    var res = await dbClient.rawQuery(
      "SELECT * FROM users WHERE username = ? AND password = ?",
      [user, hashPassword(pass)],
    );
    return res.isNotEmpty;
  }
}


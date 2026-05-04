import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'hisnul.sqlite3';
  static const int _dbVersion = 2;
  static const String _prefKeyDbVer = 'db_ver';

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, _dbName);

    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_prefKeyDbVer) ?? 0;

    final dbFile = File(dbPath);
    if (!dbFile.existsSync() || savedVersion < _dbVersion) {
      await _copyDatabase(dbPath);
      await prefs.setInt(_prefKeyDbVer, _dbVersion);
    }

    return await openDatabase(dbPath, version: _dbVersion);
  }

  Future<void> _copyDatabase(String dbPath) async {
    final data = await rootBundle.load('assets/db/$_dbName');
    final bytes = data.buffer.asUint8List();
    await File(dbPath).writeAsBytes(bytes, flush: true);
  }

  // ─── Dua Group Queries ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDuaGroups({String? searchFilter}) async {
    final db = await database;
    final filter = searchFilter?.isNotEmpty == true ? '%$searchFilter%' : '%';
    return db.rawQuery('''
      SELECT g._id, g.en_title,
        (SELECT COUNT(*) FROM dua WHERE group_id = g._id AND fav = 1) as fav_count
      FROM dua_group g
      WHERE g.en_title LIKE ?
      ORDER BY g._id
    ''', [filter]);
  }

  Future<List<Map<String, dynamic>>> getDuaGroupsFiltered(List<int> ids) async {
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return db.rawQuery('''
      SELECT g._id, g.en_title,
        (SELECT COUNT(*) FROM dua WHERE group_id = g._id AND fav = 1) as fav_count
      FROM dua_group g
      WHERE g._id IN ($placeholders)
      ORDER BY g._id
    ''', ids);
  }

  Future<List<Map<String, dynamic>>> getDuaDetails(int groupId) async {
    final db = await database;
    return db.query(
      'dua',
      columns: ['_id', 'fav', 'ar_dua', 'en_translation', 'en_transliteration', 'en_reference'],
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  Future<List<Map<String, dynamic>>> getFavoriteDuaGroups() async {
    final db = await database;
    return db.rawQuery('''
      SELECT DISTINCT g._id, g.en_title,
        (SELECT COUNT(*) FROM dua WHERE group_id = g._id AND fav = 1) as fav_count
      FROM dua_group g
      INNER JOIN dua d ON d.group_id = g._id
      WHERE d.fav = 1
      ORDER BY g._id
    ''');
  }

  Future<List<Map<String, dynamic>>> getFavoriteDuaDetails(int groupId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT _id, fav, ar_dua, en_translation, en_transliteration, en_reference
      FROM dua
      WHERE group_id = ? AND fav = 1
    ''', [groupId]);
  }

  // ─── Favorite Toggle ─────────────────────────────────────────────────────

  Future<bool> toggleDuaFavorite(int duaId, bool newFav) async {
    final db = await database;
    final rows = await db.update(
      'dua',
      {'fav': newFav ? 1 : 0},
      where: '_id = ?',
      whereArgs: [duaId],
    );
    return rows == 1;
  }

  Future<void> setGroupFavStatus(int groupId, bool isFav) async {
    final db = await database;
    await db.update(
      'dua',
      {'fav': isFav ? 1 : 0},
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }
}

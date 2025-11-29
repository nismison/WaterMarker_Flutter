import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseUtil {
  static const dbName = 'media_index.db';
  static const table = 'local_media_index';

  static Future<String> getDbPath() async {
    final base = await getDatabasesPath();
    return p.join(base, dbName);
  }

  static Future<void> deleteDb() async {
    final path = await getDbPath();
    await deleteDatabase(path);
    debugPrint('[DB] 已删除数据库: $path');
  }

  static Future<Database> open() async {
    final path = await getDbPath();
    return openDatabase(path, version: 1);
  }

  static Future<void> initTable() async {
    final db = await open();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        asset_id TEXT PRIMARY KEY,
        uploaded INTEGER NOT NULL
      );
    ''');
    debugPrint('[DB] local_media_index 已初始化');
  }

  static Future<void> clearTable() async {
    final db = await open();
    await db.delete(table);
    debugPrint('[DB] local_media_index 已清空');
  }
}

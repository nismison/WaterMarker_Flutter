import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// 通用本地 SQLite 数据库工具类
/// 提供：
/// - 删除数据库文件（回到首次启动状态）
/// - 删除/重建指定表
/// - 清空指定表
/// - 初始化媒体索引表（本项目用）
///
/// 注意：
/// 调用方不要关心 _db 的存在，由各自的实现类（如 SqfliteMediaIndex）自行调用 init()。
class DatabaseUtil {
  static const String dbName = 'media_index.db';
  static const String tableMediaIndex = 'local_media_index';

  /// 获取数据库文件路径
  static Future<String> getDbPath() async {
    final base = await getDatabasesPath();
    return p.join(base, dbName);
  }

  /// 删除整个数据库文件（彻底重置）
  static Future<void> deleteDb() async {
    final path = await getDbPath();
    await deleteDatabase(path);
    debugPrint('[DB] 数据库已删除: $path');
  }

  /// 打开数据库（通用）
  static Future<Database> openDb() async {
    final path = await getDbPath();
    return openDatabase(path, version: 1);
  }

  /// 删除表（DROP TABLE）
  static Future<void> dropTable(String table) async {
    final db = await openDb();
    await db.execute('DROP TABLE IF EXISTS $table');
    debugPrint('[DB] 已删除表: $table');
  }

  /// 清空表所有内容（DELETE FROM）
  static Future<void> clearTable(String table) async {
    final db = await openDb();
    await db.delete(table);
    debugPrint('[DB] 已清空表数据: $table');
  }

  /// 初始化媒体索引表（本项目唯一需要的表）
  static Future<void> initMediaIndexTable() async {
    final db = await openDb();

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableMediaIndex (
        path TEXT PRIMARY KEY,
        uploaded INTEGER NOT NULL
      );
    ''');

    debugPrint('[DB] 媒体索引表已初始化');
  }

  /// 删除媒体索引表并重建（不会删除数据库文件）
  static Future<void> resetMediaIndexTable() async {
    await dropTable(tableMediaIndex);
    await initMediaIndexTable();
    debugPrint('[DB] 媒体索引表已重建');
  }

  /// 清空媒体索引表数据
  static Future<void> clearMediaIndexTable() async {
    await clearTable(tableMediaIndex);
  }

  /// 检查数据库文件是否存在
  static Future<bool> dbExists() async {
    final path = await getDbPath();
    return databaseExists(path);
  }
}

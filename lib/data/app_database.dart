import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 负责管理整个 App 的 SQLite 实例
///
/// 设计点：
/// - 单例 + 懒加载，确保全局只开一个 Database；
/// - 以后需要升级 schema 时，只改 _onCreate / _onUpgrade 即可。
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'watermarker_media.db');

    // version 从 1 开始，后续有 schema 变化时递增
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // 初始化 schema（与上面 SQL 对应）
    await db.execute('''
      CREATE TABLE media_index (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        path            TEXT    NOT NULL UNIQUE,
        size            INTEGER NOT NULL,
        mtime           INTEGER NOT NULL,
        md5             TEXT,
        uploaded        INTEGER NOT NULL DEFAULT 0,
        first_seen_ts   INTEGER NOT NULL,
        last_check_ts   INTEGER,
        last_upload_ts  INTEGER,
        error_count     INTEGER NOT NULL DEFAULT 0,
        last_error      TEXT
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_media_uploaded ON media_index(uploaded);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_media_mtime ON media_index(mtime);
    ''');
  }

  /// 预留升级逻辑
  ///
  /// 以后需要加字段/索引时，用 ALTER TABLE & CREATE INDEX 即可，
  /// 不要做破坏性操作，避免线上用户数据丢失。
  FutureOr<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    // 示例：
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE media_index ADD COLUMN xxx TEXT;');
    // }
  }
}

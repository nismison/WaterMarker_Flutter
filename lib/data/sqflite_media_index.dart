import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'local_media_index.dart';
import 'local_media_record.dart';

/// 基于 sqflite 的 LocalMediaIndex 实现
///
/// 主要实现策略：
/// - getByPath: 简单 SELECT LIMIT 1；
/// - upsert: 先 UPDATE（保留 first_seen_ts），没有再 INSERT；
/// - markUploaded: 更新 md5/size/mtime/last_check_ts/last_upload_ts/uploaded。
class SqfliteMediaIndex implements LocalMediaIndex {
  SqfliteMediaIndex();

  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<LocalMediaRecord?> getByPath(String path) async {
    final db = await _db;

    final rows = await db.query(
      'media_index',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return LocalMediaRecord.fromMap(rows.first);
  }

  @override
  Future<void> upsert(LocalMediaRecord record) async {
    final db = await _db;

    // 先尝试更新（不动 first_seen_ts）
    final updateMap = record.toMap()
      ..remove('first_seen_ts'); // 保留旧 first_seen_ts
    final updated = await db.update(
      'media_index',
      updateMap,
      where: 'path = ?',
      whereArgs: [record.path],
    );

    if (updated > 0) {
      return;
    }

    // 没有旧记录，则插入（使用当前 first_seen_ts）
    await db.insert(
      'media_index',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> markUploaded({
    required String path,
    required String md5,
    required int size,
    required int mtime,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await getByPath(path);

    if (existing != null) {
      final updateMap = <String, Object?>{
        'md5': md5,
        'size': size,
        'mtime': mtime,
        'uploaded': 1,
        'last_check_ts': now,
        'last_upload_ts': now,
        // 上传成功后可以把 error_count 清零
        'error_count': 0,
        'last_error': null,
      };

      await db.update(
        'media_index',
        updateMap,
        where: 'path = ?',
        whereArgs: [path],
      );
    } else {
      // 第一次看到这个文件就已经确认“已上传”
      final record = LocalMediaRecord(
        path: path,
        size: size,
        mtime: mtime,
        md5: md5,
        uploaded: true,
        firstSeenTs: now,
        lastCheckTs: now,
        lastUploadTs: now,
        errorCount: 0,
        lastError: null,
      );
      await db.insert(
        'media_index',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  /// 可选：记录一次错误，方便后续排查“哪些文件一直失败”
  Future<void> markError({
    required String path,
    required String message,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await getByPath(path);
    if (existing == null) {
      final record = LocalMediaRecord(
        path: path,
        size: 0,
        mtime: 0,
        md5: null,
        uploaded: false,
        firstSeenTs: now,
        lastCheckTs: now,
        lastUploadTs: null,
        errorCount: 1,
        lastError: message,
      );
      await db.insert('media_index', record.toMap());
      return;
    }

    await db.update(
      'media_index',
      {
        'last_check_ts': now,
        'error_count': existing.errorCount + 1,
        'last_error': message,
      },
      where: 'path = ?',
      whereArgs: [path],
    );
  }
}

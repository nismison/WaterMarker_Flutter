import 'package:sqflite/sqflite.dart';
import '../utils/database_util.dart';
import 'local_media_index.dart';
import 'local_media_record.dart';

class SqfliteMediaIndex implements LocalMediaIndex {
  Database? _db;

  Future<void> _ensureDb() async {
    if (_db != null) return;
    final path = await DatabaseUtil.getDbPath();
    _db = await openDatabase(path, version: 1);
    await DatabaseUtil.initMediaIndexTable();
  }

  @override
  Future<LocalMediaRecord?> get(String path) async {
    await _ensureDb();
    final rows = await _db!.query(
      DatabaseUtil.tableMediaIndex,
      where: 'path = ?',
      whereArgs: [path],
    );
    if (rows.isEmpty) return null;
    return LocalMediaRecord.fromMap(rows.first);
  }

  @override
  Future<void> upsert(LocalMediaRecord record) async {
    await _ensureDb();
    await _db!.insert(
      DatabaseUtil.tableMediaIndex,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markUploaded(String path) async {
    await _ensureDb();
    await _db!.insert(DatabaseUtil.tableMediaIndex, {
      'path': path,
      'uploaded': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<LocalMediaRecord>> getUnuploaded({int limit = 100}) async {
    await _ensureDb();
    final rows = await _db!.query(
      DatabaseUtil.tableMediaIndex,
      where: 'uploaded = 0',
      limit: limit,
    );
    return rows.map(LocalMediaRecord.fromMap).toList();
  }

  @override
  Future<void> batchUpsert(List<LocalMediaRecord> records) async {
    await _ensureDb();
    final batch = _db!.batch();
    for (final r in records) {
      batch.insert(
        DatabaseUtil.tableMediaIndex,
        r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}

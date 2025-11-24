import 'local_media_record.dart';

abstract class LocalMediaIndex {
  Future<LocalMediaRecord?> get(String assetId);

  Future<void> upsert(LocalMediaRecord record);

  Future<void> markUploaded(String assetId);

  Future<List<LocalMediaRecord>> getUnuploaded({int limit = 100});

  Future<void> batchUpsert(List<LocalMediaRecord> records);
}

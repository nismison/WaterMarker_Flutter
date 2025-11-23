import 'local_media_record.dart';

/// 媒体索引访问接口
///
/// 这样设计的原因是：
/// - 上层同步逻辑只依赖接口，未来你要换 Hive/别的实现也不用动业务。
abstract class LocalMediaIndex {
  /// 按 path 查一条记录
  Future<LocalMediaRecord?> getByPath(String path);

  /// 插入或更新（以 path 为主键）
  ///
  /// 要求：如果记录已存在，优先保留已有的 firstSeenTs。
  Future<void> upsert(LocalMediaRecord record);

  /// 标记某个文件“服务器确认已存在/已上传”
  ///
  /// 一般在：
  /// - 秒传命中；
  /// - 上传成功；
  /// 之后调用。
  Future<void> markUploaded({
    required String path,
    required String md5,
    required int size,
    required int mtime,
  });
}

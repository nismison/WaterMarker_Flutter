// lib/models/fm_model.dart

/// FM 工单条目模型。
///
/// 对应后端 /api/fm/pending_accept 和 /api/fm/pending_process 返回的 items 中的每一项：
///
/// {
///   "acceptTime": "2025-11-29 14:30:01",
///   "address": "南宁市邕宁区良堤路6号",
///   "assetCode": "45010228",
///   "assetName": "南宁中国锦园",
///   "assetType": "XM000001",
///   "completedTimeDiff": "",
///   "content": "2025-11-29消防通道门日巡查",
///   "createTime": "2025-11-29 14:03:28",
///   "createUser": "",
///   "cycleName": "日",
///   "cycleType": "D",
///   "dealAttachments": null,
///   "dealTenantId": null,
///   "dealUserId": "10695306",
///   "dealUserMobile": "19127224860",
///   "dealUserName": "梁振卓",
///   "endDealTime": "2025-11-29 20:03:28",
///   "eventNo": "20251129140000-736365875690246-72",
///   "finishTime": null,
///   "groupMake": 0,
///   "id": "746536163574917",
///   "isCustomer": 0,
///   "jobId": 72,
///   "labelType": "5",
///   "labelTypeName": "安全",
///   "mappingCode": null,
///   "needCertificate": 0,
///   "operateTime": null,
///   "outResponseOverTime": "",
///   "ownSpaceCode": null,
///   "packageOrderId": null,
///   "planTime": "2025-11-29 14:00:00",
///   "pmsId": "736365875690246",
///   "programCate": 1,
///   "programCode": "D137",
///   "projectCode": "45010228",
///   "projectName": "南宁中国锦园",
///   "source": "0",
///   "sourceName": "默认系统派发",
///   "status": "3",
///   "statusName": "已接受",
///   "taskId": "d5c32741-ccec-11f0-a848-4e2610e5bc87",
///   "tenantId": "10010",
///   "timeDiff": "33分钟前",
///   "title": "消防通道门日巡查",
///   "updateTime": "2025-11-29 14:30:02",
///   "updateUser": "梁振卓",
///   "woType": "PM"
/// }
class FmTaskItem {
  final String id;
  final String title;

  final String? acceptTime;
  final String? address;
  final String? assetCode;
  final String? assetName;
  final String? assetType;
  final String? completedTimeDiff;
  final String? content;
  final String? createTime;
  final String? createUser;
  final String? cycleName;
  final String? cycleType;
  final dynamic dealAttachments;
  final String? dealTenantId;
  final String? dealUserId;
  final String? dealUserMobile;
  final String? dealUserName;
  final String? endDealTime;
  final String? eventNo;
  final String? finishTime;
  final int? groupMake;
  final int? isCustomer;
  final int? jobId;
  final String? labelType;
  final String? labelTypeName;
  final String? mappingCode;
  final int? needCertificate;
  final String? operateTime;
  final String? outResponseOverTime;
  final String? ownSpaceCode;
  final String? packageOrderId;
  final String? planTime;
  final String? pmsId;
  final int? programCate;
  final String? programCode;
  final String? projectCode;
  final String? projectName;
  final String? source;
  final String? sourceName;
  final String? status;
  final String? statusName;
  final String? taskId;
  final String? tenantId;
  final String? timeDiff;
  final String? updateTime;
  final String? updateUser;
  final String? woType;

  /// 保留原始数据，便于未来扩展或调试。
  final Map<String, dynamic> raw;

  FmTaskItem({
    required this.id,
    required this.title,
    this.acceptTime,
    this.address,
    this.assetCode,
    this.assetName,
    this.assetType,
    this.completedTimeDiff,
    this.content,
    this.createTime,
    this.createUser,
    this.cycleName,
    this.cycleType,
    this.dealAttachments,
    this.dealTenantId,
    this.dealUserId,
    this.dealUserMobile,
    this.dealUserName,
    this.endDealTime,
    this.eventNo,
    this.finishTime,
    this.groupMake,
    this.isCustomer,
    this.jobId,
    this.labelType,
    this.labelTypeName,
    this.mappingCode,
    this.needCertificate,
    this.operateTime,
    this.outResponseOverTime,
    this.ownSpaceCode,
    this.packageOrderId,
    this.planTime,
    this.pmsId,
    this.programCate,
    this.programCode,
    this.projectCode,
    this.projectName,
    this.source,
    this.sourceName,
    this.status,
    this.statusName,
    this.taskId,
    this.tenantId,
    this.timeDiff,
    this.updateTime,
    this.updateUser,
    this.woType,
    required this.raw,
  });

  factory FmTaskItem.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    return FmTaskItem(
      id: _asString(map['id']),
      title: _asString(map['title']),
      acceptTime: _asStringOrNull(map['acceptTime']),
      address: _asStringOrNull(map['address']),
      assetCode: _asStringOrNull(map['assetCode']),
      assetName: _asStringOrNull(map['assetName']),
      assetType: _asStringOrNull(map['assetType']),
      completedTimeDiff: _asStringOrNull(map['completedTimeDiff']),
      content: _asStringOrNull(map['content']),
      createTime: _asStringOrNull(map['createTime']),
      createUser: _asStringOrNull(map['createUser']),
      cycleName: _asStringOrNull(map['cycleName']),
      cycleType: _asStringOrNull(map['cycleType']),
      dealAttachments: map['dealAttachments'],
      dealTenantId: _asStringOrNull(map['dealTenantId']),
      dealUserId: _asStringOrNull(map['dealUserId']),
      dealUserMobile: _asStringOrNull(map['dealUserMobile']),
      dealUserName: _asStringOrNull(map['dealUserName']),
      endDealTime: _asStringOrNull(map['endDealTime']),
      eventNo: _asStringOrNull(map['eventNo']),
      finishTime: _asStringOrNull(map['finishTime']),
      groupMake: _asIntOrNull(map['groupMake']),
      isCustomer: _asIntOrNull(map['isCustomer']),
      jobId: _asIntOrNull(map['jobId']),
      labelType: _asStringOrNull(map['labelType']),
      labelTypeName: _asStringOrNull(map['labelTypeName']),
      mappingCode: _asStringOrNull(map['mappingCode']),
      needCertificate: _asIntOrNull(map['needCertificate']),
      operateTime: _asStringOrNull(map['operateTime']),
      outResponseOverTime: _asStringOrNull(map['outResponseOverTime']),
      ownSpaceCode: _asStringOrNull(map['ownSpaceCode']),
      packageOrderId: _asStringOrNull(map['packageOrderId']),
      planTime: _asStringOrNull(map['planTime']),
      pmsId: _asStringOrNull(map['pmsId']),
      programCate: _asIntOrNull(map['programCate']),
      programCode: _asStringOrNull(map['programCode']),
      projectCode: _asStringOrNull(map['projectCode']),
      projectName: _asStringOrNull(map['projectName']),
      source: _asStringOrNull(map['source']),
      sourceName: _asStringOrNull(map['sourceName']),
      status: _asStringOrNull(map['status']),
      statusName: _asStringOrNull(map['statusName']),
      taskId: _asStringOrNull(map['taskId']),
      tenantId: _asStringOrNull(map['tenantId']),
      timeDiff: _asStringOrNull(map['timeDiff']),
      updateTime: _asStringOrNull(map['updateTime']),
      updateUser: _asStringOrNull(map['updateUser']),
      woType: _asStringOrNull(map['woType']),
      raw: map,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acceptTime': acceptTime,
      'address': address,
      'assetCode': assetCode,
      'assetName': assetName,
      'assetType': assetType,
      'completedTimeDiff': completedTimeDiff,
      'content': content,
      'createTime': createTime,
      'createUser': createUser,
      'cycleName': cycleName,
      'cycleType': cycleType,
      'dealAttachments': dealAttachments,
      'dealTenantId': dealTenantId,
      'dealUserId': dealUserId,
      'dealUserMobile': dealUserMobile,
      'dealUserName': dealUserName,
      'endDealTime': endDealTime,
      'eventNo': eventNo,
      'finishTime': finishTime,
      'groupMake': groupMake,
      'id': id,
      'isCustomer': isCustomer,
      'jobId': jobId,
      'labelType': labelType,
      'labelTypeName': labelTypeName,
      'mappingCode': mappingCode,
      'needCertificate': needCertificate,
      'operateTime': operateTime,
      'outResponseOverTime': outResponseOverTime,
      'ownSpaceCode': ownSpaceCode,
      'packageOrderId': packageOrderId,
      'planTime': planTime,
      'pmsId': pmsId,
      'programCate': programCate,
      'programCode': programCode,
      'projectCode': projectCode,
      'projectName': projectName,
      'source': source,
      'sourceName': sourceName,
      'status': status,
      'statusName': statusName,
      'taskId': taskId,
      'tenantId': tenantId,
      'timeDiff': timeDiff,
      'title': title,
      'updateTime': updateTime,
      'updateUser': updateUser,
      'woType': woType,
    };
  }

  /// isCustomer / needCertificate 等 0/1 字段的语义化访问。
  bool get isCustomerBool => isCustomer == 1;

  bool get needCertificateBool => needCertificate == 1;
}

/// FM 工单列表结果，对应：
/// {
///   "success": true,
///   "data": {
///     "items": [ {...}, {...} ]
///   }
/// }
class FmTaskListResult {
  /// 工单列表
  final List<FmTaskItem> items;

  FmTaskListResult({required this.items});

  factory FmTaskListResult.fromJson(Map<String, dynamic> json) {
    final dynamic list = json['items'];
    final List<FmTaskItem> items = <FmTaskItem>[];

    if (list is List) {
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          items.add(FmTaskItem.fromJson(e));
        } else if (e is Map) {
          items.add(FmTaskItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return FmTaskListResult(items: items);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'items': items.map((e) => e.toJson()).toList()};
  }

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;
}

/// 接单接口返回的数据模型。
///
/// 当前后端直接转发 FMApi.accept_task(order_id) 的结果，
/// 未约定具体字段，这里仍然只做原始 Map 封装。
class FmAcceptTaskResult {
  final Map<String, dynamic> raw;

  FmAcceptTaskResult({required this.raw});

  factory FmAcceptTaskResult.fromJson(Map<String, dynamic> json) {
    return FmAcceptTaskResult(raw: Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}

/// ------- 本文件内部使用的小工具函数 -------

String _asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) {
    return int.tryParse(v);
  }
  return null;
}

/// 完成工单接口返回的数据模型。
///
/// 后端返回：
/// {
///   "order_id": "...",
///   "title": "...",
///   "user": "...",
///   "user_number": "...",
///   "upload_count": 3
/// }
class FmCompleteTaskResult {
  /// 工单 ID
  final String orderId;

  /// 工单标题
  final String title;

  /// 处理人名称
  final String user;

  /// 处理人工号
  final String userNumber;

  /// 上传的图片/附件数量
  final int uploadCount;

  /// 原始数据，方便后续扩展或调试
  final Map<String, dynamic> raw;

  FmCompleteTaskResult({
    required this.orderId,
    required this.title,
    required this.user,
    required this.userNumber,
    required this.uploadCount,
    required this.raw,
  });

  factory FmCompleteTaskResult.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    return FmCompleteTaskResult(
      orderId: _asString(map['order_id']),
      title: _asString(map['title']),
      user: _asString(map['user']),
      userNumber: _asString(map['user_number']),
      uploadCount: _asIntOrNull(map['upload_count']) ?? 0,
      raw: map,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'order_id': orderId,
      'title': title,
      'user': user,
      'user_number': userNumber,
      'upload_count': uploadCount,
    };
  }
}

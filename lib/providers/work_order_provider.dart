import 'package:flutter/foundation.dart';
import 'package:watermarker_v2/api/fm_api.dart';
import 'package:watermarker_v2/models/fm_model.dart';

/// 工单模型（去掉了下划线，方便全局复用）
class WorkOrder {
  final String title;
  final String location;
  final String timeout; // yyyy-MM-dd hh:mm:ss
  final String orderType; // "pending_accept" / "pending_process"
  final String orderId;

  const WorkOrder({
    required this.title,
    required this.location,
    required this.timeout,
    required this.orderType,
    required this.orderId,
  });
}

class WorkOrderProvider extends ChangeNotifier {
  final FmApi _fmApi;

  WorkOrderProvider({FmApi? fmApi}) : _fmApi = fmApi ?? FmApi();

  // =======================
  // 内部状态
  // =======================

  List<WorkOrder> _pendingAccept = [];
  List<WorkOrder> _pendingProcess = [];

  bool _isLoadingPendingAccept = false;
  bool _isLoadingPendingProcess = false;

  // 是否已经加载过（用于 Tab 第一次进来时懒加载）
  bool _hasLoadedPendingAccept = false;
  bool _hasLoadedPendingProcess = false;

  // =======================
  // 对外只读 getter
  // =======================

  List<WorkOrder> get pendingAccept => List.unmodifiable(_pendingAccept);

  List<WorkOrder> get pendingProcess => List.unmodifiable(_pendingProcess);

  bool get isLoadingPendingAccept => _isLoadingPendingAccept;

  bool get isLoadingPendingProcess => _isLoadingPendingProcess;

  bool get hasLoadedPendingAccept => _hasLoadedPendingAccept;

  bool get hasLoadedPendingProcess => _hasLoadedPendingProcess;

  // =======================
  // 加载列表
  // =======================

  Future<void> loadPendingAccept({bool forceRefresh = false}) async {
    if (_isLoadingPendingAccept) return;
    if (!forceRefresh && _hasLoadedPendingAccept) return;

    _isLoadingPendingAccept = true;
    notifyListeners();

    try {
      final FmTaskListResult result = await _fmApi.fetchPendingAccept(
        userNumber: '2409840',
      );

      _pendingAccept = result.items
          .map(
            (item) => WorkOrder(
              title: item.title,
              location: item.address ?? "",
              timeout: item.endDealTime ?? "",
              orderType: "pending_accept",
              orderId: item.id,
            ),
          )
          .toList();
      _hasLoadedPendingAccept = true;
    } finally {
      _isLoadingPendingAccept = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingProcess({bool forceRefresh = false}) async {
    if (_isLoadingPendingProcess) return;
    if (!forceRefresh && _hasLoadedPendingProcess) return;

    _isLoadingPendingProcess = true;
    notifyListeners();

    try {
      final FmTaskListResult result = await _fmApi.fetchPendingProcess(
        userNumber: '2409840',
      );

      _pendingProcess = result.items
          .map(
            (item) => WorkOrder(
              title: item.title,
              location: item.address ?? "",
              timeout: item.endDealTime ?? "",
              orderType: "pending_process",
              orderId: item.id,
            ),
          )
          .toList();
      _hasLoadedPendingProcess = true;
    } finally {
      _isLoadingPendingProcess = false;
      notifyListeners();
    }
  }

  Future<void> refreshPendingAccept() async {
    await loadPendingAccept(forceRefresh: true);
  }

  Future<void> refreshPendingProcess() async {
    await loadPendingProcess(forceRefresh: true);
  }

  // =======================
  // 操作数据：比如关单后从待处理列表中移除
  // =======================

  void removeFromPendingProcess(String orderId) {
    _pendingProcess = _pendingProcess
        .where((o) => o.orderId != orderId)
        .toList();
    notifyListeners();
  }

  // 如果以后要做“接单”，可以在这里 add / move 列表项
  // void moveFromAcceptToProcess(String orderId) { ... }
  void moveFromAcceptToProcess(String orderId) {
    final order = _pendingAccept.firstWhere((o) => o.orderId == orderId);
    _pendingAccept = _pendingAccept.where((o) => o.orderId != orderId).toList();
    _pendingProcess.add(order);
    notifyListeners();
  }
}

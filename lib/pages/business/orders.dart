import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:forui/forui.dart';
import 'package:lottie/lottie.dart';

import 'package:watermarker_v2/api/fm_api.dart';
import 'package:watermarker_v2/utils/loading_manager.dart';

import '../../models/fm_model.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // 保持你原来的 TabBar 样式不动
          title: const TabBar(
            dividerColor: Color.fromRGBO(229, 229, 229, 0.5),
            indicatorColor: Colors.black87,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            tabs: [
              Tab(text: '待接工单'),
              Tab(text: '待处理工单'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [PendingAcceptList(), PendingProcessList()],
        ),
      ),
    );
  }
}

/// =======================
/// 公共模型 & 卡片组件（样式保持之前那套）
/// =======================

class _WorkOrder {
  final String title;
  final String location;
  final String timeout; // yyyy-MM-dd hh:mm:ss
  final String orderType;
  final String orderId;

  const _WorkOrder({
    required this.title,
    required this.location,
    required this.timeout,
    required this.orderType,
    required this.orderId,
  });
}

class _WorkOrderCard extends StatelessWidget {
  final _WorkOrder order;
  final VoidCallback? onClosed;

  const _WorkOrderCard({required this.order, this.onClosed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 工单标题（加粗黑色字体）
            Text(
              order.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            // 2. 分隔符
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: Color.fromRGBO(229, 229, 229, 0.8),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3. 具体位置：xxxxx（灰色字体）
                      Text(
                        '具体位置：${order.location}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 10),

                      // 4. 超时时间：（灰色） + 时间（红色）
                      Row(
                        children: [
                          Text(
                            '超时时间：',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            order.timeout,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (order.orderType == "pending_process")
                  FButton(
                    child: Text("关单"),
                    onPress: () async {
                      showFDialog(
                        context: context,
                        builder: (context, style, animation) => FDialog(
                          style: style.call,
                          animation: animation,
                          direction: Axis.horizontal,
                          title: const Text('提交工单'),
                          body: Text('是否提交工单？'),
                          actions: [
                            FButton(
                              style: FButtonStyle.outline(),
                              onPress: () => Navigator.of(context).pop(),
                              child: const Text('取消'),
                            ),
                            FButton(
                              onPress: () async {
                                Navigator.of(context).pop();
                                GlobalLoading().show(context, text: '正在提交...');

                                try {
                                  await FmApi().completeTask(
                                    userName: "梁振卓",
                                    userNumber: "2409840",
                                    orderId: order.orderId,
                                  );
                                  Fluttertoast.showToast(
                                    msg: '提交工单成功',
                                    backgroundColor: Colors.green,
                                  );

                                  onClosed?.call();
                                } catch (e) {
                                  Fluttertoast.showToast(
                                    msg: '提交工单失败：${e.toString()}',
                                    backgroundColor: Colors.red,
                                  );
                                } finally {
                                  GlobalLoading().hide();
                                }
                              },
                              child: const Text('提交'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PendingAcceptList extends StatelessWidget {
  const PendingAcceptList({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkOrderList(
      loader: _loadPendingAccept, // 回调
      emptyText: '暂无待接工单',
      actionText: '一键接单',
      onAction: () {
        // TODO: 一键接单逻辑
      },
    );
  }
}

/// 获取待接工单数据
Future<List<_WorkOrder>> _loadPendingAccept() async {
  final FmApi fmApi = FmApi();

  final FmTaskListResult result = await fmApi.fetchPendingAccept(
    userNumber: '2409840',
  );

  return result.items
      .map(
        (item) => _WorkOrder(
          title: item.title,
          location: item.address ?? "",
          timeout: item.endDealTime ?? "",
          orderType: "pending_accept",
          orderId: item.id,
        ),
      )
      .toList();
}

class PendingProcessList extends StatelessWidget {
  const PendingProcessList({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkOrderList(
      loader: _loadPendingProcess,
      emptyText: '暂无待处理工单',
      actionText: '一键关单',
      onAction: () {
        // TODO: 一键关单逻辑
      },
    );
  }
}

/// 获取待处理工单数据
Future<List<_WorkOrder>> _loadPendingProcess() async {
  final FmApi fmApi = FmApi();

  final FmTaskListResult result = await fmApi.fetchPendingProcess(
    userNumber: '2409840',
  );

  return result.items
      .map(
        (item) => _WorkOrder(
          title: item.title,
          location: item.address ?? "",
          timeout: item.endDealTime ?? "",
          orderType: "pending_process",
          orderId: item.id,
        ),
      )
      .toList();
}

class WorkOrderList extends StatefulWidget {
  /// 真正去加载数据的函数（待接 / 待处理各自实现）
  final Future<List<_WorkOrder>> Function() loader;

  /// 空数据时的提示文案
  final String emptyText;

  /// 底部按钮的文案
  final String actionText;

  /// 底部按钮点击回调
  final VoidCallback onAction;

  const WorkOrderList({
    super.key,
    required this.loader,
    required this.emptyText,
    required this.actionText,
    required this.onAction,
  });

  @override
  State<WorkOrderList> createState() => _WorkOrderListState();
}

class _WorkOrderListState extends State<WorkOrderList>
    with AutomaticKeepAliveClientMixin {
  List<_WorkOrder> _data = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await widget.loader(); // 关键：用回调拿数据

      if (!mounted) return;
      setState(() {
        _data = list;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      displacement: 0,
      child: _isLoading && _data.isEmpty
          // 加载中：用 ListView 包一层，保证可下拉
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/loading_files.json',
                        repeat: true,
                        animate: true,
                        width: 200,
                        height: 200,
                      ),
                      const Text(
                        '正在加载数据...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : (_data.isEmpty
                // 空数据：同样用 ListView 包一层
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/empty_ghost.json',
                              repeat: true,
                              animate: true,
                              width: 200,
                              height: 200,
                            ),
                            Text(
                              widget.emptyText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                // 有数据：列表 + 底部按钮，复用你原来的布局
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _data.length,
                          itemBuilder: (context, index) {
                            final item = _data[index];
                            return _WorkOrderCard(
                              order: item,
                              onClosed: () {
                                // 这里可以用 index，也可以更稳一点，用 orderId 删除
                                setState(() {
                                  _data = List<_WorkOrder>.from(_data)
                                    ..removeWhere(
                                      (o) => o.orderId == item.orderId,
                                    );
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        child: FButton(
                          style: context.theme.buttonStyles.primary
                              .copyWith(
                                contentStyle: context
                                    .theme
                                    .buttonStyles
                                    .primary
                                    .contentStyle
                                    .copyWith(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 15,
                                      ),
                                    )
                                    .call,
                              )
                              .call,
                          onPress: widget.onAction,
                          child: Text(widget.actionText),
                        ),
                      ),
                    ],
                  )),
    );
  }
}

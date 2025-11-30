import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:forui/forui.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:watermarker_v2/api/fm_api.dart';
import 'package:watermarker_v2/utils/loading_manager.dart';
import 'package:watermarker_v2/providers/work_order_provider.dart';

/// 解析 timeout 字符串并计算与当前时间的差值
Duration calcTimeoutDiff(String timeout) {
  // 如果你的 timeout 是 24 小时制字符串：2025-11-30 18:30:00
  final format = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 如果你真的用的是 12 小时制（例如 "2025-11-30 06:30:00 PM"）
  // 就需要：DateFormat('yyyy-MM-dd hh:mm:ss a');

  final DateTime timeoutTime = format.parse(timeout);
  final DateTime now = DateTime.now();

  // timeout - now：正数表示还有多久超时；负数表示已经超时多久
  return timeoutTime.difference(now);
}

bool isSameDayWithNow(String timeout) {
  final format = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateTime timeoutTime = format.parse(timeout);

  final DateTime now = DateTime.now();

  return timeoutTime.year == now.year &&
      timeoutTime.month == now.month &&
      timeoutTime.day == now.day;
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FTabs(
            children: [
              FTabEntry(
                label: const Text(
                  '待接工单',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Expanded(child: PendingAcceptList()),
              ),
              FTabEntry(
                label: const Text(
                  '待处理工单',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Expanded(child: PendingProcessList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// 工单卡片
/// =======================

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder order;

  const _WorkOrderCard({required this.order});

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
            Row(
              children: [
                calcTimeoutDiff(order.timeout).inHours < 2
                    ? _buildStatusPill("即将超时", Colors.red)
                    : isSameDayWithNow(order.timeout)
                    ? _buildStatusPill("今日超时", Colors.orange)
                    : _buildStatusPill("不急", Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            // 2. 分隔符
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: const Divider(
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
                      Row(
                        children: [
                          Icon(FIcons.mapPin, size: 16),
                          SizedBox(width: 5),
                          Text(
                            '具体位置：${order.location}',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.1,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(FIcons.clockAlert, size: 16),
                              SizedBox(width: 5),
                              Text(
                                '超时时间：',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.1,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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

                order.orderType == "pending_process"
                    ? FButton(
                        child: const Text("关单"),
                        onPress: () async {
                          showFDialog(
                            context: context,
                            builder: (dialogContext, style, animation) =>
                                FDialog(
                                  style: style.call,
                                  animation: animation,
                                  direction: Axis.horizontal,
                                  title: const Text('提交工单'),
                                  body: const Text('是否提交工单？'),
                                  actions: [
                                    FButton(
                                      style: FButtonStyle.outline(),
                                      onPress: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('取消'),
                                    ),
                                    FButton(
                                      onPress: () async {
                                        Navigator.of(dialogContext).pop();

                                        final workOrderProvider = context
                                            .read<WorkOrderProvider>();

                                        GlobalLoading().show(
                                          context,
                                          text: '正在提交...',
                                        );

                                        try {
                                          await FmApi().completeTask(
                                            userName: "梁振卓",
                                            userNumber: "2409840",
                                            orderId: order.orderId,
                                          );

                                          Fluttertoast.showToast(
                                            msg: '提交工单成功',
                                            backgroundColor: Colors.green,
                                            gravity: ToastGravity.CENTER,
                                          );

                                          workOrderProvider
                                              .removeFromPendingProcess(
                                                order.orderId,
                                              );
                                        } catch (e) {
                                          Fluttertoast.showToast(
                                            msg: '提交工单失败：${e.toString()}',
                                            backgroundColor: Colors.red,
                                            gravity: ToastGravity.CENTER,
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
                      )
                    : FButton(
                        child: const Text("接单"),
                        onPress: () async {
                          final workOrderProvider = context
                              .read<WorkOrderProvider>();

                          GlobalLoading().show(context, text: '正在接单...');

                          try {
                            await FmApi().acceptTask(
                              userNumber: "2409840",
                              orderId: order.orderId,
                            );

                            Fluttertoast.showToast(
                              msg: '接单成功',
                              backgroundColor: Colors.green,
                              gravity: ToastGravity.CENTER,
                            );

                            workOrderProvider.moveFromAcceptToProcess(
                              order.orderId,
                            );
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: '接单失败：${e.toString()}',
                              backgroundColor: Colors.red,
                              gravity: ToastGravity.CENTER,
                            );
                          } finally {
                            GlobalLoading().hide();
                          }
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 状态胶囊：待接单 / 待处理
  Widget _buildStatusPill(String text, Color bgColor) {
    final Color textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// =======================
/// 待接工单 Tab
/// =======================

class PendingAcceptList extends StatefulWidget {
  const PendingAcceptList({super.key});

  @override
  State<PendingAcceptList> createState() => _PendingAcceptListState();
}

class _PendingAcceptListState extends State<PendingAcceptList>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    // 首次进入时懒加载待接工单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkOrderProvider>();
      provider.loadPendingAccept();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<WorkOrderProvider>(
      builder: (context, provider, _) {
        return WorkOrderList(
          type: 'pending_accept',
          data: provider.pendingAccept,
          isLoading: provider.isLoadingPendingAccept,
          emptyText: '暂无待接工单',
          actionText: '一键接单',
          onAction: () async {
            showFDialog(
              context: context,
              builder: (dialogContext, style, animation) => FDialog(
                style: style.call,
                animation: animation,
                direction: Axis.horizontal,
                title: const Text('一键接单'),
                body: const Text('是否接取所有工单？'),
                actions: [
                  FButton(
                    style: FButtonStyle.outline(),
                    onPress: () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                  FButton(
                    child: const Text('确定'),
                    onPress: () async {
                      Navigator.of(dialogContext).pop();

                      GlobalLoading().show(context, text: '正在接单...');

                      try {
                        await FmApi().acceptMultiTask(
                          userNumber: '2409840',
                          orderIds: provider.pendingAccept
                              .map((order) => order.orderId)
                              .toList(),
                        );

                        Fluttertoast.showToast(
                          msg: '接单成功',
                          backgroundColor: Colors.green,
                          gravity: ToastGravity.CENTER,
                        );

                        for (final order in provider.pendingAccept) {
                          provider.moveFromAcceptToProcess(order.orderId);
                        }
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: '接单失败：${e.toString()}',
                          backgroundColor: Colors.red,
                          gravity: ToastGravity.CENTER,
                        );
                      } finally {
                        GlobalLoading().hide();
                      }
                    },
                  ),
                ],
              ),
            );
          },
          onRefresh: provider.refreshPendingAccept,
        );
      },
    );
  }
}

/// =======================
/// 待处理工单 Tab
/// =======================

class PendingProcessList extends StatefulWidget {
  const PendingProcessList({super.key});

  @override
  State<PendingProcessList> createState() => _PendingProcessListState();
}

class _PendingProcessListState extends State<PendingProcessList>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    // 首次进入时懒加载待处理工单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkOrderProvider>();
      provider.loadPendingProcess();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<WorkOrderProvider>(
      builder: (context, provider, _) {
        return WorkOrderList(
          type: 'pending_process',
          data: provider.pendingProcess,
          isLoading: provider.isLoadingPendingProcess,
          emptyText: '暂无待处理工单',
          actionText: '一键关单',
          onAction: () {
            // TODO: 一键关单逻辑，同样建议放到 Provider
          },
          onRefresh: provider.refreshPendingProcess,
        );
      },
    );
  }
}

/// =======================
/// 纯展示型列表组件（不再自己维护 _data 和 loading）
/// =======================

class WorkOrderList extends StatelessWidget {
  final List<WorkOrder> data;
  final bool isLoading;
  final String emptyText;
  final String actionText;
  final VoidCallback onAction;
  final String type;
  final Future<void> Function() onRefresh;

  const WorkOrderList({
    super.key,
    required this.data,
    required this.isLoading,
    required this.emptyText,
    required this.actionText,
    required this.onAction,
    required this.onRefresh,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 0,
      child: isLoading && data.isEmpty
          // 加载中：用 ListView 包一层，保证可下拉
          ? const Center(child: CircularProgressIndicator())
          : (data.isEmpty
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
                              emptyText,
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
                // 有数据：列表 + 底部按钮
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            return _WorkOrderCard(order: item);
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
                          onPress: onAction,
                          child: Text(actionText),
                        ),
                      ),
                    ],
                  )),
    );
  }
}

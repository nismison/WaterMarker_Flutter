import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lottie/lottie.dart';

class BaichuanPage extends StatelessWidget {
  const BaichuanPage({super.key});

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

  const _WorkOrder({
    required this.title,
    required this.location,
    required this.timeout,
  });
}

class _WorkOrderCard extends StatelessWidget {
  final _WorkOrder order;

  const _WorkOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(10),
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
            // const FDivider(),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: Color.fromRGBO(229, 229, 229, 0.8),
              ),
            ),

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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  order.timeout,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// 待接工单列表（下拉刷新 + 保持状态）
/// =======================

class PendingAcceptList extends StatefulWidget {
  const PendingAcceptList({super.key});

  @override
  State<PendingAcceptList> createState() => _PendingAcceptListState();
}

class _PendingAcceptListState extends State<PendingAcceptList>
    with AutomaticKeepAliveClientMixin {
  List<_WorkOrder> _data = const [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  bool get wantKeepAlive => true; // 关键：Tab 切换时保留状态

  /// TODO：接接口时替换为真实的待接工单请求
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      const mock = [
        _WorkOrder(
          title: '巡检机房空调温度异常',
          location: '上海市浦东新区张江路 123 号 A 楼 3 楼机房',
          timeout: '2025-11-30 14:30:00',
        ),
        _WorkOrder(
          title: '办公区网络中断',
          location: '上海市徐汇区零陵路 456 号 2 楼开放办公区',
          timeout: '2025-11-29 09:00:00',
        ),
      ];

      if (!mounted) return;
      setState(() {
        _data = mock;
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
    super.build(context); // 和 AutomaticKeepAliveClientMixin 配套

    return RefreshIndicator(
      onRefresh: _onRefresh,
      displacement: 0,
      child: _isLoading && _data.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsetsGeometry.only(bottom: 100),
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
                    Text(
                      '正在加载数据...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : (_data.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 100),
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
                            '暂无待接工单',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _data.length,
                    itemBuilder: (context, index) {
                      final item = _data[index];
                      return _WorkOrderCard(order: item);
                    },
                  )),
    );
  }
}

/// =======================
/// 待处理工单列表（下拉刷新 + 保持状态）
/// =======================

class PendingProcessList extends StatefulWidget {
  const PendingProcessList({super.key});

  @override
  State<PendingProcessList> createState() => _PendingProcessListState();
}

class _PendingProcessListState extends State<PendingProcessList>
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

  /// TODO：接接口时替换为真实的待处理工单请求
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      const mock = [
        _WorkOrder(
          title: '生产环境磁盘空间告警',
          location: '上海市虹口区东大名路 789 号 数据中心 2 区',
          timeout: '2025-11-28 23:59:59',
        ),
        _WorkOrder(
          title: '门禁系统读卡器故障',
          location: '上海市静安区北京西路 101 号 1 楼大厅',
          timeout: '2025-11-29 10:15:00',
        ),
      ];

      if (!mounted) return;
      setState(() {
        _data = mock;
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
          ? Center(
              child: Padding(
                padding: EdgeInsetsGeometry.only(bottom: 100),
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
                    Text(
                      '正在加载数据...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : (_data.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 100),
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
                            '暂无待处理工单',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _data.length,
                    itemBuilder: (context, index) {
                      final item = _data[index];
                      return _WorkOrderCard(order: item);
                    },
                  )),
    );
  }
}

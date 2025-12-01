import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:forui/forui.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import 'package:watermarker_v2/api/fm_api.dart';
import 'package:watermarker_v2/models/fm_model.dart';
import 'package:watermarker_v2/models/user_info_model.dart';
import 'package:watermarker_v2/providers/fm_config_provider.dart';
import 'package:watermarker_v2/utils/loading_manager.dart';

/// 上下班打卡页面（Provider 版本）
///
/// 依赖：
/// - FmConfig（提供 UserInfoModel）
/// - FmApi.fetchCheckinRecord
class FmCheckinPage extends StatelessWidget {
  const FmCheckinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FmConfigProvider>(
      builder: (context, fmConfig, _) {
        final UserInfoModel? userInfo = fmConfig.userInfo;

        // 未配置用户信息时的占位界面
        if (userInfo == null) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.person_off_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '未配置用户信息',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '请先完成登录或绑定账号后再使用打卡功能',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 已有用户信息：注入 ViewModel
        return ChangeNotifierProvider<FmCheckinViewModel>(
          create: (_) =>
              FmCheckinViewModel(userInfo: userInfo, fmConfig: fmConfig),
          child: const _FmCheckinView(),
        );
      },
    );
  }
}

/// 视图部分
class _FmCheckinView extends StatelessWidget {
  const _FmCheckinView();

  /// 秒级时间戳转 HH:mm:ss
  String _formatTimestamp(int? seconds) {
    if (seconds == null || seconds <= 0) return '-';

    // 假设 seconds 是标准的 Unix 时间戳（秒，UTC）
    final dtUtc = DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    );

    // 固定转成 UTC+8
    final dt = dtUtc.add(const Duration(hours: 8));

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  /// 排班卡片
  Widget _buildScheduleSection(
    BuildContext context,
    List<FmCheckinSchedule> schedule,
  ) {
    if (schedule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.event_busy_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              '今日暂无排班信息',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(79, 70, 229, 0.12),
            ),
            child: const Icon(
              FIcons.clockFading,
              size: 22,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule[0].type ?? '未命名班次',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTimestamp(schedule[0].startTime)}  ~  ${_formatTimestamp(schedule[0].endTime)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 打卡记录列表：稍微做个“时间线”样式
  Widget _buildRecordSection(List<FmCheckinRecord> records) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日打卡记录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  '今天还没有打卡记录',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            )
          else
            Column(
              children: [
                for (int i = 0; i < records.length; i++)
                  _CheckinTimelineTile(
                    timeText: _formatTimestamp(records[i].recordTime),
                    isFirst: i == 0,
                    isLast: i == records.length - 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// 底部大圆形打卡按钮（带按压动画）
  Widget _buildCheckinButton(BuildContext context) {
    return Consumer<FmCheckinViewModel>(
      builder: (context, vm, _) {
        final bool highlight = vm.isButtonHighlighted;

        return SizedBox(
          height: 120,
          child: Center(
            child: MouseRegion(
              onEnter: (_) => vm.setButtonHover(true),
              onExit: (_) => vm.setButtonHover(false),
              child: GestureDetector(
                onTapDown: (_) => vm.setButtonPressed(true),
                onTapUp: (_) => vm.setButtonPressed(false),
                onTapCancel: () => vm.setButtonPressed(false),
                onTap: () async {
                  try {
                    GlobalLoading().show(context, text: "打卡中...");
                    await vm._fmApi.checkin(
                      phone: vm.userPhone,
                      deviceModel: vm.userDeviceModel,
                      deviceUuid: vm.userDeviceId,
                    );

                    Fluttertoast.showToast(
                      msg: "打卡成功",
                      backgroundColor: Colors.green,
                      gravity: ToastGravity.CENTER,
                    );

                    vm.reload(); // 刷新数据
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: "打卡失败: ${e.toString()}",
                      backgroundColor: Colors.red,
                      gravity: ToastGravity.CENTER,
                    );
                  } finally {
                    GlobalLoading().hide();
                  }
                },
                child: AnimatedScale(
                  scale: highlight ? 0.94 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF22C55E),
                          Color(0xFF22C55E),
                          Color(0xFF16A34A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: highlight
                          ? [
                              BoxShadow(
                                color: const Color.fromRGBO(22, 163, 74, 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color.fromRGBO(22, 163, 74, 0.45),
                                blurRadius: 22,
                                offset: const Offset(0, 14),
                              ),
                            ],
                    ),
                    child: const Center(
                      child: Text(
                        '打卡',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FmCheckinViewModel>(
      builder: (context, vm, _) {
        final data = vm.data;
        final isLoading = vm.isLoading;
        final error = vm.errorMessage;

        return FScaffold(
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // 主体内容（可下拉刷新），底部预留空间给悬浮按钮
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: RefreshIndicator(
                      onRefresh: vm.reload,
                      displacement: 0,
                      child: isLoading && data == null
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                          ? ListView(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 140, // 给悬浮按钮留一点空间
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 140, // 给悬浮按钮留一点空间
                              ),
                              children: [
                                if (data != null)
                                  _buildScheduleSection(context, data.schedule),
                                const SizedBox(height: 16),
                                if (data != null)
                                  _buildRecordSection(data.record),
                              ],
                            ),
                    ),
                  ),
                ),

                // 悬浮在页面上的大圆形打卡按钮（底部居中）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: _buildCheckinButton(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 时间线样式的打卡记录小组件
/// 打卡记录行（不再做时间线，仅分行展示时间）。
class _CheckinTimelineTile extends StatelessWidget {
  final String timeText;
  final bool isFirst;
  final bool isLast;

  const _CheckinTimelineTile({
    required this.timeText,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧小圆点
          Icon(FIcons.circleCheck, size: 16, color: const Color(0xFF22C55E)),
          const SizedBox(width: 10),
          // 右侧时间文本
          Expanded(
            child: Text(
              timeText,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ViewModel
class FmCheckinViewModel extends ChangeNotifier {
  final FmApi _fmApi = FmApi();
  final UserInfoModel _userInfo;
  final FmConfigProvider _fmConfigProvider;

  FmCheckinRecordResult? _data;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isButtonPressed = false;
  bool _isButtonHover = false;

  /// 标记 ChangeNotifier 是否已被 dispose
  bool _disposed = false;

  FmCheckinRecordResult? get data => _data;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get userName => _userInfo.name;

  String get userNumber => _userInfo.userNumber;

  String get userPhone => _userInfo.phone;

  String get userDeviceModel => _userInfo.deviceModel;

  String get userDeviceId => _userInfo.deviceId;

  /// 按钮是否处于高亮（按下或 hover）状态
  bool get isButtonHighlighted => _isButtonPressed || _isButtonHover;

  FmCheckinViewModel({
    required UserInfoModel userInfo,
    required FmConfigProvider fmConfig,
  }) : _userInfo = userInfo,
       _fmConfigProvider = fmConfig {
    // 先尝试用 Provider 中缓存的数据填充，避免页面从 0 开始白屏
    final cached = _fmConfigProvider.checkinData;
    if (cached != null) {
      _data = cached;
    }

    // 再拉最新数据
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      final result = await _fmApi.fetchCheckinRecord(
        userNumber: _userInfo.userNumber,
        phone: _userInfo.phone,
      );

      // 即使 ViewModel 被销毁了，缓存仍然可以写回到 FmConfigProvider，
      // 所以这里不受 _disposed 限制。
      _fmConfigProvider.setCheckinData(result);

      // 但 UI 状态只在未销毁时更新
      if (!_disposed) {
        _data = result;
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = e.toString();
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> reload() => _loadData();

  // 按钮按下/抬起状态（用于缩放和阴影）
  void setButtonPressed(bool value) {
    if (_isButtonPressed == value || _disposed) return;
    _isButtonPressed = value;
    notifyListeners();
  }

  // Hover 状态（Web/桌面有效，移动端无感知）
  void setButtonHover(bool value) {
    if (_isButtonHover == value || _disposed) return;
    _isButtonHover = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

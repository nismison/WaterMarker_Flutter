import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:water_marker_test2/pages/qr_scan_page.dart';
import 'package:water_marker_test2/pages/select_images_page.dart';
import 'package:water_marker_test2/pages/watermark_preview_page.dart';
import '../providers/image_picker_provider.dart';
import '../utils/watermark/watermark_generator.dart';
import '../widgets/date_picker_dialog.dart';
import '../widgets/time_picker_dialog.dart';
import '../widgets/user_picker_dialog.dart';
import 'advanced_image_preview_page.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _scanFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final result = await QrCodeToolsPlugin.decodeFrom(file.path);
    if (!mounted) return;

    if (result != null && result.trim().isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('解析成功: $result')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未识别到二维码')));
    }
  }

  Future<void> _scanWithCamera() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QRScanPage()));
  }

  void _showScanOptions() {
    showFSheet(
      context: context,
      side: FLayout.btt,
      builder: (_) => FTileGroup(
        children: [
          FTile(
            prefix: Icon(FIcons.image),
            title: const Text('从相册识别二维码'),
            onPress: () {
              Navigator.pop(context);
              _scanFromGallery();
            },
          ),
          FTile(
            prefix: Icon(FIcons.image),
            title: const Text('打开相机扫描二维码'),
            onPress: () {
              Navigator.pop(context);
              _scanWithCamera();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImagePickerProvider>();

    final dateText =
        "${provider.selectedDate.year}-${provider.selectedDate.month.toString().padLeft(2, '0')}-${provider.selectedDate.day.toString().padLeft(2, '0')}";
    final timeText =
        "${provider.selectedTime.hour.toString().padLeft(2, '0')}:${provider.selectedTime.minute.toString().padLeft(2, '0')}";

    return FScaffold(
      scaffoldStyle: FScaffoldStyle(
        systemOverlayStyle: SystemUiOverlayStyle(),
        backgroundColor: Colors.white,
        sidebarBackgroundColor: Colors.white,
        childPadding: EdgeInsetsGeometry.zero,
        footerDecoration: BoxDecoration(),
      ).call,
      header: FHeader(
        title: const Text('水印生成器'),
        suffixes: [
          FHeaderAction(
            icon: const Icon(FIcons.scanQrCode, size: 30),
            onPress: _showScanOptions,
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 图片 Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                provider.pickedImages.length + (provider.canAddMore ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1, // 1:1
            ),
            itemBuilder: (_, index) {
              if (index < provider.pickedImages.length) {
                final img = provider.pickedImages[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          child: Hero(
                            tag: img.path,
                            child: Image.file(
                              File(img.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          onTap: () {
                            showImagePreview(
                              context,
                              imagePath: img.path,
                              useHero: true,
                              fadeDuration: Duration(milliseconds: 150),
                              imageList: provider.pickedImages.map((e) => e.path).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => provider.removeImage(index),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // 添加图片按钮
                return GestureDetector(
                  onTap: () => _openSelectImages(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 40, color: Colors.grey),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),

          FTileGroup(
            divider: FItemDivider.full,
            children: [
              // 水印日期
              FTile(
                prefix: const Icon(FIcons.calendar, size: 25),
                title: const Text('水印日期'),
                details: Text(dateText),
                suffix: const Icon(FIcons.chevronRight),
                onPress: () => showDatePickerDialog(
                  context: context,
                  initialDate: provider.selectedDate,
                  onSelected: provider.updateDate,
                ),
              ),

              // 水印时间
              FTile(
                prefix: const Icon(FIcons.alarmClock),
                title: const Text('水印时间'),
                details: Text(timeText),
                suffix: const Icon(FIcons.chevronRight),
                onPress: () => showTimePickerDialog(
                  context: context,
                  initialTime: provider.selectedTime,
                  onSelected: provider.updateTime,
                ),
              ),

              // 用户姓名
              FTile(
                prefix: const Icon(FIcons.circleUserRound),
                title: const Text('姓名'),
                details: Text(provider.selectedUserName),
                suffix: const Icon(FIcons.chevronRight),
                onPress: () => showUserPickerDialog(
                  context: context,
                  userList: provider.userList,
                  initialName: provider.selectedUserName,
                  onSelected: provider.updateUser,
                ),
              ),

              // 用户编号（锁定，去掉 onPress 和右箭头）
              FTile(
                prefix: const Icon(FIcons.hash),
                title: const Text('用户编号'),
                details: Text(provider.selectedUserNumber),
                suffix: const Icon(FIcons.lockKeyhole, color: Colors.grey),
                enabled: false,
                onPress: null,
              ),
            ],
          ),

          const SizedBox(height: 12),
          // 生成按钮
          FButton(
            onPress: () => _handleGenerate(provider),
            child: const Text('生成'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _handleGenerate(ImagePickerProvider provider) async {
    if (provider.pickedImages.isEmpty) {
      debugPrint("请先选择至少一张图片");
      return;
    }
    if (provider.selectedUser == null) {
      debugPrint("请先选择用户");
      return;
    }

    final DateTime datetime = provider.combinedDateTime;
    final String userNumber = provider.selectedUserNumber;
    // selectedUser 是 Map<String, dynamic>
    final String name = (provider.selectedUser!['name'] ?? '').toString();
    final List<String> watermarkedPaths = [];

    debugPrint("开始生成...");
    debugPrint("时间：$datetime");
    debugPrint("用户编号：$userNumber");
    debugPrint("选择图片数：${provider.pickedImages.length}");

    for (int i = 0; i < provider.pickedImages.length; i++) {
      final XFile xfile = provider.pickedImages[i];
      final File inputFile = File(xfile.path);

      try {
        final String watermarkedPath = await generateWatermarkForImage(
          inputFile: inputFile,
          name: name,
          userNumber: userNumber,
          datetime: datetime,
          minuteOffset: i * 2,
        );
        watermarkedPaths.add(watermarkedPath);
        debugPrint("第 ${i + 1} 张生成完成：$watermarkedPath");
      } catch (e, st) {
        debugPrint("第 ${i + 1} 张生成失败: $e");
        debugPrint(st.toString());
      }
    }

    debugPrint("全部图片生成完成");
    // 跳转预览页面
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WatermarkPreviewPage(imagePaths: watermarkedPaths),
        ),
      );
    }
  }

  Future<void> _openSelectImages(BuildContext context) async {
    final provider = context.read<ImagePickerProvider>();
    final List<String>? result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectImagesPage(
          maxSelection: provider.maxImages,
          preSelectedPaths: provider.pickedPaths,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      provider.addSelected(result);
    }
  }
}

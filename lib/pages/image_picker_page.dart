import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

import 'package:water_marker_test2/pages/qr_scan_page.dart';
import 'package:water_marker_test2/pages/watermark_preview_page.dart';

import '../providers/image_picker_provider.dart';
import '../utils/image_picker_helper.dart';
import '../utils/loading_manager.dart';
import '../utils/storage_permission_util.dart';
import '../utils/watermark/encryption.dart';
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
  @override
  void initState() {
    super.initState();
  }

  // ----------------------------------------------------------------------
  // QR 扫码（原逻辑不变）
  // ----------------------------------------------------------------------
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
            onPress: () async {
              Navigator.pop(context);
              // 必须检查媒体权限
              if (!(await AppPermissions.hasGalleryPermission())) {
                Fluttertoast.showToast(
                  msg: "没有媒体权限",
                  backgroundColor: Colors.red,
                );
                AppPermissions.ensureGalleryPermission();
                return;
              }

              final selectedPaths = await showImagePicker(
                context,
                maxSelection: 1,
              );
              if (selectedPaths == null || selectedPaths.isEmpty) return;

              final path = selectedPaths[0];
              final result = await QrCodeToolsPlugin.decodeFrom(path);

              if (!mounted) return;

              if (result != null && result.trim().isNotEmpty) {
                final decrypted = decryptWatermark(jsonDecode(result)['text']);
                if (decrypted == null) {
                  Fluttertoast.showToast(
                    msg: "解密失败",
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                final name = decrypted["n"];
                final number = decrypted["s"];

                final provider = context.read<ImagePickerProvider>();

                final exists = provider.userList.any(
                  (item) => item["number"] == number,
                );

                if (!exists) {
                  provider.addUser({"name": name, "number": number});
                  Fluttertoast.showToast(
                    msg: "已添加新用户 [$name - $number]",
                    backgroundColor: Colors.green,
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: "用户已存在，无需添加",
                    backgroundColor: Colors.red,
                  );
                }
              } else {
                Fluttertoast.showToast(
                  msg: "未识别到二维码",
                  backgroundColor: Colors.red,
                );
              }
            },
          ),
          FTile(
            prefix: Icon(FIcons.camera),
            title: const Text('打开相机扫描二维码'),
            onPress: () async {
              if (!await AppPermissions.hasCameraPermission()) {
                Fluttertoast.showToast(
                  msg: "没有相机权限",
                  backgroundColor: Colors.red,
                );
                AppPermissions.ensureCameraPermission();
                return;
              }
              Navigator.pop(context);
              _scanWithCamera();
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI 主体（大部分代码保持不变）
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImagePickerProvider>();

    final dateText =
        "${provider.selectedDate.year}-${provider.selectedDate.month.toString().padLeft(2, '0')}-${provider.selectedDate.day.toString().padLeft(2, '0')}";
    final timeText =
        "${provider.selectedTime.hour.toString().padLeft(2, '0')}:${provider.selectedTime.minute.toString().padLeft(2, '0')}";

    return FScaffold(
      header: FHeader.nested(
        title: const Row(children: [Text('水印生成器2.0')]),
        suffixes: [
          // 清空按钮不变
          if (provider.pickedImages.isNotEmpty)
            FHeaderAction(
              icon: const Icon(FIcons.trash2),
              onPress: () async {
                showFDialog(
                  context: context,
                  builder: (context, style, animation) => FDialog(
                    style: style.call,
                    animation: animation,
                    direction: Axis.horizontal,
                    title: const Text('清空图片'),
                    body: const Text('是否清空已选图片？'),
                    actions: [
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      FButton(
                        onPress: () {
                          Navigator.of(context).pop();
                          provider.setSelected([]);
                        },
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 扫码按钮
          FHeaderAction(
            icon: const Icon(FIcons.scanQrCode),
            onPress: () async {
              _showScanOptions();
            },
          ),
        ],
      ),

      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // -------------------------------------------------------------------
          // 图片 grid
          // -------------------------------------------------------------------
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                provider.pickedImages.length + (provider.canAddMore ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              // 已选图片（原逻辑不动）
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
                            tag: "index_page_${img.path}",
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
                              tagPrefix: "index_page",
                              fadeDuration: Duration(milliseconds: 150),
                              imageList: provider.pickedImages
                                  .map((e) => e.path)
                                  .toList(),
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
              }

              // 添加图片按钮
              return GestureDetector(
                onTap: () async {
                  if (!(await AppPermissions.hasGalleryPermission())) {
                    Fluttertoast.showToast(
                      msg: "没有媒体权限",
                      backgroundColor: Colors.red,
                    );
                    AppPermissions.ensureGalleryPermission();
                    return;
                  }

                  final provider = context.read<ImagePickerProvider>();
                  final selectedPaths = await showImagePicker(
                    context,
                    maxSelection: provider.maxImages,
                    preSelectedPaths: provider.pickedPaths,
                  );

                  if (selectedPaths == null) return;
                  provider.setSelected(selectedPaths);
                },
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
            },
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // 下面表单项不变
          // -------------------------------------------------------------------
          FTileGroup(
            divider: FItemDivider.full,
            children: [
              FTile(
                prefix: const Text('📅'),
                title: const Text('水印日期'),
                details: Text(dateText),
                suffix: const Icon(FIcons.chevronRight),
                onPress: () => showDatePickerDialog(
                  context: context,
                  initialDate: provider.selectedDate,
                  onSelected: provider.updateDate,
                ),
              ),
              FTile(
                prefix: const Text('🕐'),
                title: const Text('水印时间'),
                details: Text(timeText),
                suffix: const Icon(FIcons.chevronRight),
                onPress: () => showTimePickerDialog(
                  context: context,
                  initialTime: provider.selectedTime,
                  onSelected: provider.updateTime,
                ),
              ),
              FTile(
                prefix: const Text('👤'),
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

          const SizedBox(height: 20),

          // 生成按钮
          FButton(
            style: context.theme.buttonStyles.primary
                .copyWith(
                  contentStyle: context.theme.buttonStyles.primary.contentStyle
                      .copyWith(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                      )
                      .call,
                )
                .call,
            onPress: () => _handleGenerate(provider),
            child: const Text('生成水印'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 生成水印（原逻辑保持不变）
  // ----------------------------------------------------------------------
  void _handleGenerate(ImagePickerProvider provider) async {
    if (provider.pickedImages.isEmpty) {
      Fluttertoast.showToast(msg: "请先选择至少一张图片", backgroundColor: Colors.red);
      return;
    }
    if (provider.selectedUser == null) {
      Fluttertoast.showToast(msg: "请先选择用户", backgroundColor: Colors.red);
      return;
    }

    final DateTime datetime = provider.combinedDateTime;
    final String userNumber = provider.selectedUserNumber;
    final String name = (provider.selectedUser!['name'] ?? '').toString();

    final List<String> watermarkedPaths = [];

    final loading = GlobalLoading();
    loading.show(context, text: "开始生成...");

    debugPrint("开始生成...");
    debugPrint("时间：$datetime");
    debugPrint("用户编号：$userNumber");
    debugPrint("选择图片数：${provider.pickedImages.length}");

    for (int i = 0; i < provider.pickedImages.length; i++) {
      loading.update("正在生成(${i + 1}/${provider.pickedImages.length})");
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

    loading.hide();
    debugPrint("全部图片生成完成");

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WatermarkPreviewPage(imagePaths: watermarkedPaths),
        ),
      );
    }
  }
}

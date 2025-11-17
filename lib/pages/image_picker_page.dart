import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:water_marker_test2/pages/qr_scan_page.dart';
import 'package:water_marker_test2/pages/select_images_page.dart';
import '../providers/image_picker_provider.dart';
import '../widgets/date_picker_dialog.dart';
import '../widgets/time_picker_dialog.dart';
import '../widgets/user_picker_dialog.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final provider = context.read<ImagePickerProvider>();
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) provider.addImages(images);
  }

  Future<void> _scanFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final result = await QrCodeToolsPlugin.decodeFrom(file.path);
    if (!mounted) return;

    if (result != null && result.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解析成功: $result')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未识别到二维码')),
      );
    }
  }

  Future<void> _scanWithCamera() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QRScanPage(),
      ),
    );
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册识别二维码'),
              onTap: () {
                Navigator.pop(context);
                _scanFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('打开相机扫描二维码'),
              onTap: () {
                Navigator.pop(context);
                _scanWithCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImagePickerProvider>();

    final dateText =
        "${provider.selectedDate.year}-${provider.selectedDate.month
        .toString()
        .padLeft(2, '0')}-${provider.selectedDate.day.toString().padLeft(
        2, '0')}";
    final timeText =
        "${provider.selectedTime.hour.toString().padLeft(2, '0')}:${provider
        .selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('水印生成器'),
        actions: [
          TextButton(
            onPressed: _showScanOptions,
            child: const Text(
              '解析二维码',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
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
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Image.file(File(img.path)),
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
                );              }
            },
          ),
          const SizedBox(height: 16),
          // 日期
          _buildSelectorRow(
            icon: Icons.calendar_today,
            label: dateText,
            onTap: () =>
                showDatePickerDialog(
                  context: context,
                  initialDate: provider.selectedDate,
                  onSelected: provider.updateDate,
                ),
          ),
          // 时间
          _buildSelectorRow(
            icon: Icons.access_time,
            label: timeText,
            onTap: () =>
                showTimePickerDialog(
                  context: context,
                  initialTime: provider.selectedTime,
                  onSelected: provider.updateTime,
                ),
          ),
          // 用户
          _buildSelectorRow(
            icon: Icons.person,
            label: provider.selectedUserName,
            onTap: () =>
                showUserPickerDialog(
                  context: context,
                  userList: provider.userList,
                  initialName: provider.selectedUserName,
                  onSelected: provider.updateUser,
                ),
          ),
          // 用户编号输入框
          if (provider.selectedUser != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Colors.grey, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.selectedUserNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const Icon(Icons.lock, color: Colors.grey, size: 16),
                ],
              ),
            ),

          const SizedBox(height: 12),
          // 生成按钮
          ElevatedButton(
            onPressed: () => _handleGenerate(provider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('生成'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSelectorRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _handleGenerate(ImagePickerProvider provider) {
    if (provider.pickedImages.isEmpty) {
      // 这里可以替换为 SnackBar / Toast
      debugPrint("请先选择至少一张图片");
      return;
    }
    if (provider.selectedUser == null) {
      debugPrint("请先选择用户");
      return;
    }

    final datetime = provider.combinedDateTime;
    final userNumber = provider.selectedUserNumber;

    debugPrint("开始生成...");
    debugPrint("日期时间：$datetime");
    debugPrint("用户编号：$userNumber");
    debugPrint("共选择图片：${provider.pickedImages.length} 张");

    // TODO：根据业务进行生成、上传、写入数据库等
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

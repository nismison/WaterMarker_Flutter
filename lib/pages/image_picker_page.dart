import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/image_picker_provider.dart';
import '../widgets/date_picker_dialog.dart';
import '../widgets/time_picker_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImagePickerProvider>();

    final dateText = "${provider.selectedDate.year}-${provider.selectedDate.month.toString().padLeft(2, '0')}-${provider.selectedDate.day.toString().padLeft(2, '0')}";
    final timeText = "${provider.selectedTime.hour.toString().padLeft(2, '0')}:${provider.selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text('选择图片')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Grid
          SizedBox(
            height: 360,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.pickedImages.length + (provider.canAddMore ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, index) {
                if (index < provider.pickedImages.length) {
                  final img = provider.pickedImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(img.path),
                          fit: BoxFit.cover,
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
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                } else {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 40, color: Colors.grey),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          // 日期选择
          _buildSelectorRow(
            icon: Icons.calendar_today,
            label: dateText,
            onTap: () => showDatePickerDialog(
              context: context,
              initialDate: provider.selectedDate,
              onSelected: provider.updateDate,
            ),
          ),

          // 时间选择
          _buildSelectorRow(
            icon: Icons.access_time,
            label: timeText,
            onTap: () => showTimePickerDialog(
              context: context,
              initialTime: provider.selectedTime,
              onSelected: provider.updateTime,
            ),
          ),
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
}

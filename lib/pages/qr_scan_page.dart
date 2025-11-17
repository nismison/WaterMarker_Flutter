import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String? _lastScan;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (!mounted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      return;
    }

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      return;
    }

    // 简单去重，避免重复弹结果
    if (code == _lastScan) {
      return;
    }
    _lastScan = code;

    Navigator.of(context).pop(code);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('识别成功: $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect, // ✅ 新版签名：只传一个 BarcodeCapture
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

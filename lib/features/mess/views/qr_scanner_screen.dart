import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Invite Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && !isScanned) {
            final String? code = barcodes.first.rawValue;
            if (code != null && code.length == 6) {
              setState(() => isScanned = true);
              Navigator.pop(context, code);
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryIndigo,
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }
}

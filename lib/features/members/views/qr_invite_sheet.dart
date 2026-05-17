import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';

class QRInviteSheet extends StatelessWidget {
  final String messId;

  const QRInviteSheet({super.key, required this.messId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Invite Roommates', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Ask your friends to scan this QR code or use the ID below to join the mess.', 
            textAlign: TextAlign.center, 
            style: TextStyle(color: Colors.grey)
          ),
          const SizedBox(height: 32),
          
          // 🎨 The Generated QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: QrImageView(
              data: messId, // This embeds your exact Mess ID into the QR image
              version: QrVersions.auto,
              size: 220.0,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryIndigo,
            ),
          ),
          const SizedBox(height: 32),
          
          // 📋 Copy ID Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MESS ID', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Text(messId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryIndigo),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: messId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mess ID copied to clipboard!'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

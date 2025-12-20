import 'package:flutter/material.dart';
import '../services/qr_service.dart';

class QRCodeDisplay extends StatelessWidget {
  final String qrToken;

  const QRCodeDisplay({super.key, required this.qrToken});

  @override
  Widget build(BuildContext context) {
    final qrService = QRService();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Share this QR code with your doctor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          qrService.generateQRCode(
            data: qrToken,
            size: 250,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}


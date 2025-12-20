import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QRService {
  // Generate QR code widget
  QrImageView generateQRCode({
    required String data,
    required double size,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor ?? const Color(0xFFFFFFFF),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }
}


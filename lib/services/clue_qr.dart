import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import 'package:unisinos_usp_app/services/clue_return_destination.dart';

class ClueQr {
  ClueQr(int id) : url = ClueReturnDestination.publicLink(id) {
    matrix = QrImage(
      QrCode.fromData(data: url, errorCorrectLevel: QrErrorCorrectLevel.M),
    );
  }
  final String url;
  late final QrImage matrix;

  void paint(Canvas canvas, double side) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()..color = Colors.white,
    );
    final unit = side / (matrix.moduleCount + 8);
    final ink = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var row = 0; row < matrix.moduleCount; row++) {
      for (var col = 0; col < matrix.moduleCount; col++) {
        if (matrix.isDark(row, col))
          canvas.drawRect(
            Rect.fromLTWH((col + 4) * unit, (row + 4) * unit, unit, unit),
            ink,
          );
      }
    }
  }

  Future<Uint8List> png() async {
    final side = (matrix.moduleCount + 8) * 16;
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), side.toDouble());
    final picture = recorder.endRecording();
    final image = await picture.toImage(side, side);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('QR Code indisponível');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}

class ClueQrPainter extends CustomPainter {
  const ClueQrPainter(this.qr);
  final ClueQr qr;
  @override
  void paint(Canvas canvas, Size size) => qr.paint(canvas, size.shortestSide);
  @override
  bool shouldRepaint(ClueQrPainter old) => qr.url != old.qr.url;
}

import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<bool> saveQrPng(Uint8List bytes, int clueId) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar QR Code da pista',
    fileName: 'pista-$clueId-qrcode.png',
    type: FileType.custom,
    allowedExtensions: ['png'],
    bytes: bytes,
  );
  if (path == null) return false;
  if (!Platform.isAndroid && !Platform.isIOS)
    await File(path).writeAsBytes(bytes);
  return true;
}

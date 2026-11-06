import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Host paths for desktop; app-owned storage for the Android sandbox.
Future<File> evidenceFile(String relative) async {
  final path = Platform.isAndroid
      ? '${(await getApplicationDocumentsDirectory()).path}/usp-plan/$relative'
      : 'docs/validation/$relative';
  final file = File(path);
  await file.parent.create(recursive: true);
  return file;
}

Future<void> publishEvidence(String name, Object value) async {
  final platform = Platform.isAndroid ? 'android' : 'linux';
  final response = await http.post(Uri.parse('http://127.0.0.1:8774/$platform/$name'), body: jsonEncode(value));
  if (response.statusCode != 201) throw StateError('Falha ao preservar evidência sanitizada');
}

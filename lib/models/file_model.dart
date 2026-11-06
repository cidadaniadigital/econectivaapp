import 'dart:convert';
import 'dart:typed_data';

import 'package:widgets_spo/models/mfile_base_model.dart';

class FileModel extends MFileBase {
  final String? mimeType;
  final int? livingClueId;
  final int? postId;
  final int? chatTemplateId;
  final String? sourceType;
  final String? sourceUrl;
  final String? originalContent;

  FileModel({
    required super.id,
    required super.extension,
    super.path,
    super.publicUrl,
    super.name,
    super.createdAt,
    super.updatedAt,
    super.base64,
    super.bytes,
    super.readStream,
    super.size,
    super.isDeleted = false,
    this.mimeType,
    this.livingClueId,
    this.postId,
    this.chatTemplateId,
    this.sourceType,
    this.sourceUrl,
    this.originalContent,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    Uint8List? decodedBytes;
    if (json['bytes'] != null) {
      decodedBytes = json['bytes'] is String
          ? base64Decode(json['bytes'])
          : Uint8List.fromList(List<int>.from(json['bytes']));
    }

    return FileModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      extension: json['extension']?.toString() ?? '',
      path: json['path'],
      mimeType: json['mime_type']?.toString(),
      publicUrl: json['public_url'],
      name: json['name'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      base64: json['base64'],
      size: int.tryParse(json['size']?.toString() ?? ''),
      bytes: decodedBytes,
      livingClueId: json['living_clue_id'] is int
          ? json['living_clue_id']
          : int.tryParse(json['living_clue_id']?.toString() ?? ''),
      postId: json['post_id'] is int
          ? json['post_id']
          : int.tryParse(json['post_id']?.toString() ?? ''),
      chatTemplateId: json['chat_template_id'] is int
          ? json['chat_template_id']
          : int.tryParse(json['chat_template_id']?.toString() ?? ''),
      sourceType: json['source_type']?.toString(),
      sourceUrl: json['source_url']?.toString(),
      originalContent: json['original_content']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'living_clue_id': livingClueId,
      'post_id': postId,
      'chat_template_id': chatTemplateId,
      'source_type': sourceType,
      'source_url': sourceUrl,
      'original_content': originalContent,
    };
  }

  static List<FileModel> fromJsonArray(String body) {
    return List<FileModel>.from(
      (jsonDecode(body) as List<dynamic>? ?? const [])
          .map((map) => FileModel.fromJson(map)),
    );
  }
}

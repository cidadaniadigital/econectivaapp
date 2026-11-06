import 'dart:convert';

class ChatTemplateFileModel {
  ChatTemplateFileModel({
    this.chatTemplateId,
    this.id,
    required this.name,
    this.mimeType,
    this.content,
    this.type,
    this.url,
    this.fileId,
    this.sourceUrl,
    this.sourceType,
    this.originalContent,
    this.extractedContent,
    this.status,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  final int? chatTemplateId;
  final int? id;
  final String name;
  final String? mimeType;
  final String? content;
  final String? type;
  final String? url;
  final int? fileId;
  final String? sourceUrl;
  final String? sourceType;
  final String? originalContent;
  final String? extractedContent;
  final String? status;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get resolvedType =>
      (type ?? sourceType ?? 'text').trim().toLowerCase();

  factory ChatTemplateFileModel.fromJson(Map<String, dynamic> json) {
    return ChatTemplateFileModel(
      chatTemplateId: json['chat_template_id'] is int
          ? json['chat_template_id']
          : int.tryParse(json['chat_template_id']?.toString() ?? ''),
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString(),
      content: json['content']?.toString(),
      type: json['type']?.toString(),
      url: json['url']?.toString(),
      fileId: json['file_id'] is int
          ? json['file_id']
          : int.tryParse(json['file_id']?.toString() ?? ''),
      sourceUrl: json['source_url']?.toString(),
      sourceType: json['source_type']?.toString(),
      originalContent: json['original_content']?.toString(),
      extractedContent: json['extracted_content']?.toString(),
      status: json['status']?.toString(),
      errorMessage: json['error_message']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (chatTemplateId != null) 'chat_template_id': chatTemplateId,
      if (id != null) 'id': id,
      'name': name,
      if ((mimeType ?? '').trim().isNotEmpty) 'mime_type': mimeType,
      'type': resolvedType,
      if (resolvedType == 'text')
        'content': (originalContent ?? content ?? '').trim(),
      if (resolvedType == 'url') 'url': (sourceUrl ?? url ?? '').trim(),
      if (resolvedType == 'file') 'url': (sourceUrl ?? url ?? '').trim(),
    };
  }
}

class ChatTemplateModel {
  ChatTemplateModel({
    required this.id,
    required this.name,
    this.description,
    this.systemInstruction,
    this.files = const <ChatTemplateFileModel>[],
    this.createdAt,
    this.updatedAt,
  });

  int id;
  String name;
  String? description;
  String? systemInstruction;
  List<ChatTemplateFileModel> files;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory ChatTemplateModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawFiles = (json['files'] is List<dynamic>)
        ? json['files'] as List<dynamic>
        : ((json['chat_template_files'] is List<dynamic>)
            ? json['chat_template_files'] as List<dynamic>
            : const []);

    return ChatTemplateModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      systemInstruction: json['system_instruction']?.toString(),
      files: rawFiles
          .whereType<Map<String, dynamic>>()
          .map(ChatTemplateFileModel.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'system_instruction': systemInstruction,
      };

  static List<ChatTemplateModel> fromResponseBody(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatTemplateModel.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic collection =
          decoded['chat_templates'] ?? decoded['data'] ?? decoded['items'];
      if (collection is List<dynamic>) {
        return collection
            .whereType<Map<String, dynamic>>()
            .map(ChatTemplateModel.fromJson)
            .toList();
      }
    }

    return const <ChatTemplateModel>[];
  }
}

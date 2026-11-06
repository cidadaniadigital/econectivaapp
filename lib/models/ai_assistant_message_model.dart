class AiAssistantMessageModel {
  AiAssistantMessageModel({
    this.id,
    this.userId,
    required this.role,
    required this.content,
    this.context,
    required this.createdAt,
  });

  final int? id;
  final int? userId;
  final String role;
  final String content;
  final String? context;
  final DateTime createdAt;

  bool get isUser => role.toLowerCase() == 'user';

  factory AiAssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return AiAssistantMessageModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? ''),
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      context: json['context']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

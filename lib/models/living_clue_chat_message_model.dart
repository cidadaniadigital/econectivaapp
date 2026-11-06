class LivingClueChatMessageModel {
  LivingClueChatMessageModel({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.role,
    this.livingClueId,
    this.userId,
  });

  final int? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? role;
  final int? livingClueId;
  final int? userId;

  String get content => text;

  factory LivingClueChatMessageModel.fromJson(Map<String, dynamic> json) {
    final String resolvedRole =
        json['role']?.toString().toLowerCase() ?? 'assistant';
    return LivingClueChatMessageModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      text: json['content']?.toString() ?? json['message']?.toString() ?? '',
      isUser: resolvedRole == 'user',
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      role: resolvedRole,
      livingClueId: json['living_clue_id'] is int
          ? json['living_clue_id']
          : int.tryParse(json['living_clue_id']?.toString() ?? ''),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? ''),
    );
  }
}

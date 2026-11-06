import 'dart:convert';

class NodeTypeModel {
  NodeTypeModel({
    required this.id,
    required this.name,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  int id;
  String name;
  String color;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory NodeTypeModel.fromJson(Map<String, dynamic> json) {
    return NodeTypeModel(
      id: _parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      color: _normalizeColor((json['color'] ?? json['color_hex'] ?? '#64748B').toString()),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': _normalizeColor(color),
      };

  static List<NodeTypeModel> fromResponseBody(String body) {
    final dynamic decoded = jsonDecode(body);
    final List<dynamic> items = _extractCollection(decoded, keys: const ['node_types', 'data', 'items']);
    return items.whereType<Map<String, dynamic>>().map(NodeTypeModel.fromJson).toList();
  }

  static List<dynamic> _extractCollection(dynamic decoded, {required List<String> keys}) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in keys) {
        final dynamic value = decoded[key];
        if (value is List<dynamic>) return value;
      }
    }
    return const [];
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _normalizeColor(String value) {
    if (value.trim().isEmpty) return '#64748B';
    final String normalized = value.trim().replaceAll('#', '');
    return '#${normalized.toUpperCase()}';
  }
}

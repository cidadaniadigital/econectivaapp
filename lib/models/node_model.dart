import 'dart:convert';

import 'package:unisinos_usp_app/models/node_type_model.dart';

class NodeModel {
  NodeModel({
    required this.id,
    required this.name,
    required this.color,
    required this.nodeTypeId,
    this.x,
    this.y,
    this.nodeType,
    this.createdAt,
    this.updatedAt,
  });

  int id;
  String name;
  String color;
  int nodeTypeId;
  double? x;
  double? y;
  NodeTypeModel? nodeType;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      id: _parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      color: _normalizeColor(
          (json['color'] ?? json['color_hex'] ?? '#38BDF8').toString()),
      nodeTypeId: _parseInt(json['node_type_id'] ?? json['node_type']?['id']),
      x: _parseDouble(json['x']),
      y: _parseDouble(json['y']),
      nodeType: json['node_type'] is Map<String, dynamic>
          ? NodeTypeModel.fromJson(json['node_type'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': _normalizeColor(color),
        'node_type_id': nodeTypeId,
        'x': x,
        'y': y,
      };

  static List<NodeModel> fromResponseBody(String body) {
    final dynamic decoded = jsonDecode(body);
    final List<dynamic> items =
        _extractCollection(decoded, keys: const ['nodes', 'data', 'items']);
    return items
        .whereType<Map<String, dynamic>>()
        .map(NodeModel.fromJson)
        .toList();
  }

  static List<dynamic> _extractCollection(dynamic decoded,
      {required List<String> keys}) {
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

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _normalizeColor(String value) {
    if (value.trim().isEmpty) return '#38BDF8';
    final String normalized = value.trim().replaceAll('#', '');
    return '#${normalized.toUpperCase()}';
  }
}

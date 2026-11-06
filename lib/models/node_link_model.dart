import 'dart:convert';

import 'package:unisinos_usp_app/models/node_model.dart';

class NodeLinkModel {
  NodeLinkModel({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourceNode,
    this.targetNode,
    this.createdAt,
    this.updatedAt,
  });

  int id;
  int sourceNodeId;
  int targetNodeId;
  NodeModel? sourceNode;
  NodeModel? targetNode;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory NodeLinkModel.fromJson(Map<String, dynamic> json) {
    return NodeLinkModel(
      id: _parseInt(json['id']),
      sourceNodeId: _parseInt(json['source_node_id'] ?? json['source_node']?['id']),
      targetNodeId: _parseInt(json['target_node_id'] ?? json['target_node']?['id']),
      sourceNode: json['source_node'] is Map<String, dynamic>
          ? NodeModel.fromJson(json['source_node'] as Map<String, dynamic>)
          : null,
      targetNode: json['target_node'] is Map<String, dynamic>
          ? NodeModel.fromJson(json['target_node'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_node_id': sourceNodeId,
        'target_node_id': targetNodeId,
      };

  static List<NodeLinkModel> fromResponseBody(String body) {
    final dynamic decoded = jsonDecode(body);
    final List<dynamic> items = _extractCollection(decoded, keys: const ['node_links', 'data', 'items', 'links']);
    return items.whereType<Map<String, dynamic>>().map(NodeLinkModel.fromJson).toList();
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
}

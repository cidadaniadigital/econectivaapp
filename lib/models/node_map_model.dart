import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/models/node_model.dart';

class NodeMapModel {
  NodeMapModel({
    required this.nodes,
    required this.links,
  });

  final List<NodeGraphNode> nodes;
  final List<NodeLinkModel> links;

  factory NodeMapModel.fromResponseBody(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return NodeMapModel(nodes: const [], links: const []);
    }

    final Map<String, dynamic> root = _extractRoot(decoded);
    final List<NodeGraphNode> parsedNodes = _extractCollection(
      root,
      keys: const ['nodes', 'data', 'items', 'vertices'],
    ).whereType<Map<String, dynamic>>().map(NodeGraphNode.fromJson).toList();
    final List<NodeLinkModel> parsedLinks = _extractCollection(
      root,
      keys: const ['links', 'edges', 'connections', 'node_links'],
    ).whereType<Map<String, dynamic>>().map(NodeLinkModel.fromJson).toList();

    return NodeMapModel(
      nodes: _withFallbackPositions(parsedNodes),
      links: parsedLinks,
    );
  }

  static List<NodeGraphNode> _withFallbackPositions(List<NodeGraphNode> nodes) {
    if (nodes.isEmpty) return nodes;
    final bool hasMissingPosition = nodes.any((node) => node.position == null);
    if (!hasMissingPosition) return nodes;

    final double radius = math.max(220, nodes.length * 24).toDouble();
    for (int index = 0; index < nodes.length; index++) {
      if (nodes[index].position != null) continue;
      final double angle = (2 * math.pi * index) / nodes.length;
      nodes[index] = nodes[index].copyWith(
        position: Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        ),
      );
    }
    return nodes;
  }

  static Map<String, dynamic> _extractRoot(Map<String, dynamic> decoded) {
    for (final key in const ['graph', 'map']) {
      final value = decoded[key];
      if (value is Map<String, dynamic>) return value;
    }
    return decoded;
  }

  static List<dynamic> _extractCollection(Map<String, dynamic> decoded,
      {required List<String> keys}) {
    for (final key in keys) {
      final value = decoded[key];
      if (value is List<dynamic>) return value;
    }
    return const [];
  }
}

class NodeGraphNode {
  NodeGraphNode({
    required this.node,
    this.position,
  });

  final NodeModel node;
  final Offset? position;

  factory NodeGraphNode.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> nodeJson = json['node'] is Map<String, dynamic>
        ? json['node'] as Map<String, dynamic>
        : json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    return NodeGraphNode(
      node: NodeModel.fromJson(nodeJson),
      position: _parseOffset(json),
    );
  }

  NodeGraphNode copyWith({
    NodeModel? node,
    Offset? position,
  }) {
    return NodeGraphNode(
      node: node ?? this.node,
      position: position ?? this.position,
    );
  }

  static Offset? _parseOffset(Map<String, dynamic> json) {
    final Map<String, dynamic>? position =
        json['position'] is Map<String, dynamic>
            ? json['position'] as Map<String, dynamic>
            : null;
    final dynamic xRaw =
        json['x'] ?? json['position_x'] ?? json['px'] ?? position?['x'];
    final dynamic yRaw =
        json['y'] ?? json['position_y'] ?? json['py'] ?? position?['y'];
    final double? x = _parseDouble(xRaw);
    final double? y = _parseDouble(yRaw);
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

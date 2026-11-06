import 'dart:convert';

import 'package:unisinos_usp_app/models/biome_model.dart';

class TerritoryModel {
  final int id;
  final String name;
  final String type;
  final String? description;
  final int biomeId;
  final double? centerLat;
  final double? centerLng;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final BiomeModel? biome;

  const TerritoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.biomeId,
    this.centerLat,
    this.centerLng,
    this.metadata,
    this.isActive = true,
    this.biome,
  });

  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    return TerritoryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      biomeId: json['biome_id'] is int
          ? json['biome_id']
          : int.tryParse(json['biome_id']?.toString() ?? '') ?? 0,
      centerLat: json['center_lat'] == null
          ? null
          : double.tryParse(json['center_lat'].toString()),
      centerLng: json['center_lng'] == null
          ? null
          : double.tryParse(json['center_lng'].toString()),
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata']),
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
      biome: json['biome'] != null ? BiomeModel.fromJson(json['biome']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'description': description,
    'biome_id': biomeId,
    'center_lat': centerLat,
    'center_lng': centerLng,
    'metadata': metadata,
    'is_active': isActive,
  };

  static List<TerritoryModel> fromJsonArray(List<dynamic> json) =>
      json.map((item) => TerritoryModel.fromJson(item)).toList();

  static List<TerritoryModel> fromJsonString(String str) =>
      fromJsonArray(jsonDecode(str));
}

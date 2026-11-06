import 'dart:convert';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'clue_observation.dart';

import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/territory_model.dart';

class LivingClueModel {
  EnvironmentalSnapshot? environmentalContext;
  List<ClueReading> sensorReadings = [];
  int id;
  String name;
  int? biomeId;
  int? territoryId;
  int categoryId;
  String? description;
  String? descriptionDelta;
  bool removeLocation;
  double? latitude;
  double? longitude;
  String? imageUrl;
  final List<FileModel> files;
  Map<String, dynamic>? metadata;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  CategoryModel? category;
  BiomeModel? biome;
  TerritoryModel? territory;

  LivingClueModel({
    required this.id,
    required this.name,
    this.biomeId,
    this.territoryId,
    required this.categoryId,
    this.latitude,
    this.longitude,
    this.description,
    this.descriptionDelta,
    this.removeLocation = false,
    this.imageUrl,
    this.files = const [],
    this.metadata,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.biome,
    this.territory,
  });

  LivingClueModel.fromJson(Map<String, dynamic> json)
      : environmentalContext = json['environmental_context'] is Map
            ? EnvironmentalSnapshot(json['environmental_context'])
            : null,
        sensorReadings = (json['sensor_readings'] is List
            ? (json['sensor_readings'] as List)
                .whereType<Map>()
                .map(ClueReading.fromJson)
                .toList()
            : <ClueReading>[]),
        id = json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name = json['name'] ?? '',
        biomeId = int.tryParse(json['biome_id']?.toString() ?? ''),
        territoryId = json['territory_id'] == null
            ? null
            : (json['territory_id'] is int
                ? json['territory_id']
                : int.tryParse(json['territory_id'].toString())),
        categoryId = json['category_id'] is int
            ? json['category_id']
            : int.parse(json['category_id'].toString()),
        description = json['description'],
        descriptionDelta = json['description_delta'] as String?,
        removeLocation = false,
        latitude = double.tryParse(json['latitude']?.toString() ?? ''),
        longitude = double.tryParse(json['longitude']?.toString() ?? ''),
        imageUrl = json['image_url'],
        files = (json['files'] as List? ?? const [])
            .whereType<Map>()
            .map((file) => FileModel.fromJson(Map<String, dynamic>.from(file)))
            .toList(),
        metadata = json['metadata'] == null
            ? null
            : Map<String, dynamic>.from(json['metadata']),
        isActive = json['is_active'] == null ? true : json['is_active'] == true,
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt = json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        category = json['category'] != null
            ? CategoryModel.fromJson(json['category'])
            : null,
        biome =
            json['biome'] != null ? BiomeModel.fromJson(json['biome']) : null,
        territory = json['territory'] != null
            ? TerritoryModel.fromJson(json['territory'])
            : null;

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'description': description ?? '',
        if (descriptionDelta != null) 'description_delta': descriptionDelta,
        if (descriptionDelta != null) 'description_format_version': 1,
        if (removeLocation) 'remove_location': true,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'metadata': metadata,
        'is_active': isActive,
      };

  static List<LivingClueModel> fromJsonArray(String str) {
    return List<LivingClueModel>.from(
      (jsonDecode(str) as List<dynamic>? ?? const [])
          .map((map) => LivingClueModel.fromJson(map)),
    );
  }
}

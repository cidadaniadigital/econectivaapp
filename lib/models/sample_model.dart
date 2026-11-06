import 'dart:convert';

import 'package:unisinos_usp_app/models/sample_detail_model.dart';

class SampleModel {
  int id;
  String name;
  String sampleString;
  String sampleUnique;
  int sampleDetailId;
  String? nullableString;
  double sampleDouble;
  DateTime sampleDate;
  int orderNumber;
  SampleDetailModel? sampleDetail;
  DateTime? createdAt;
  DateTime? updatedAt;

  SampleModel({
    required this.id,
    required this.name,
    required this.sampleString,
    required this.sampleUnique,
    required this.sampleDetailId,
    required this.sampleDouble,
    required this.sampleDate,
    this.orderNumber = 1,
    this.sampleDetail,
    this.createdAt,
    this.updatedAt,
    this.nullableString,
  });

  SampleModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name = json['name'] ?? '',
        sampleString = json['sample_string'] ?? '',
        sampleUnique = json['sample_unique'] ?? '',
        sampleDetailId = json['sample_detail_id'] is int
            ? json['sample_detail_id']
            : int.parse(json['sample_detail_id'].toString()),
        sampleDetail = json['sample_detail'] != null
            ? SampleDetailModel.fromJson(json['sample_detail'])
            : null,
        nullableString = json['sample_nullable'],
        sampleDouble = double.parse(json['sample_double'].toString()),
        sampleDate = DateTime.parse(json['sample_date']),
        orderNumber = json['order_number'] ?? 0,
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt = json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sample_string': sampleString,
        'sample_unique': sampleUnique,
        'sample_detail_id': sampleDetailId,
        'sample_nullable': nullableString ?? '',
        'sample_double': sampleDouble,
        'sample_date': sampleDate.toUtc().toIso8601String(),
        'order_number': orderNumber > 0 ? orderNumber : 1,
      };

  static List<SampleModel> fromJsonArray(String str) {
    return List<SampleModel>.from(
      (jsonDecode(str) as List<dynamic>? ?? const []).map(
          (sampleModelMapedString) =>
              SampleModel.fromJson(sampleModelMapedString)),
    );
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}

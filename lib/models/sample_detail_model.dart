class SampleDetailModel {
  int id;
  String sampleString;
  DateTime? createdAt;
  DateTime? updatedAt;

  SampleDetailModel({
    required this.id,
    required this.sampleString,
    this.createdAt,
    this.updatedAt,
  });

  SampleDetailModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        sampleString = json['sample_string'] ?? '',
        createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt = json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';

void main() {
  test('handles null collections returned by empty Go slices', () {
    expect(CategoryModel.fromJsonArray(null), isEmpty);
    expect(FileModel.fromJsonArray('null'), isEmpty);
    expect(ConnectionTypeModel.fromJsonArray('null'), isEmpty);
    expect(ClueConnectionModel.fromJsonArray('null'), isEmpty);
    expect(SampleModel.fromJsonArray('null'), isEmpty);
  });
}

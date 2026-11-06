import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'package:unisinos_usp_app/widgets/clue_cover_art.dart';

LivingClueModel clue(
        {String? url,
        Map<String, dynamic>? metadata,
        List<FileModel> files = const []}) =>
    LivingClueModel(
        id: 8,
        name: 'Uma pista',
        categoryId: 1,
        imageUrl: url,
        metadata: metadata,
        files: files);

void main() {
  late http.Client original;
  setUp(() {
    original = WebClient.instance.client;
  });
  tearDown(() {
    WebClient.instance.client = original;
  });

  test('API attachment images are retained and unrelated files are excluded',
      () {
    final model = LivingClueModel.fromJson({
      'id': 8,
      'name': 'Teste',
      'category_id': 1,
      'files': [
        {'id': 3, 'living_clue_id': 8, 'extension': 'JPG'},
        {'id': 2, 'living_clue_id': 8, 'extension': 'pdf'},
        {'id': 1, 'living_clue_id': 99, 'extension': 'png'},
      ],
    });
    expect(ClueCover.imageFiles(model).map((file) => file.id), [3]);
    expect(model.toJson().containsKey('files'), isFalse);
  });

  test('video thumbnails accept only real YouTube hosts and valid IDs', () {
    for (final source in [
      'https://www.youtube.com/watch?v=lyp83uYdtbk',
      'https://youtu.be/lyp83uYdtbk',
      'https://youtube.com/shorts/lyp83uYdtbk'
    ]) {
      expect(
          ClueCover.videoThumbnail(clue(metadata: {'recurso_original': source}))
              .toString(),
          'https://i.ytimg.com/vi/lyp83uYdtbk/hqdefault.jpg');
    }
    for (final source in [
      'https://youtube.com.evil.test/watch?v=lyp83uYdtbk',
      'https://youtube.com/watch?v=bad',
      'javascript:alert(1)'
    ]) {
      expect(ClueCover.videoThumbnail(clue(metadata: {'url': source})), isNull);
    }
  });

  testWidgets('missing covers render category artwork at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ClueCover(clue: clue(), height: 150))));
    await tester.pumpAndSettle();
    expect(find.byType(ClueCoverArt), findsOneWidget);
    expect(find.text('Pista viva'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic attachment uses fresh access and honors removal',
      (tester) async {
    final requests = <String>[];
    WebClient.instance.client = MockClient((request) async {
      requests.add(request.url.path);
      return http.Response(
          jsonEncode({'url': 'https://images.test/cover.png'}), 200);
    });
    final model =
        clue(files: [FileModel(id: 3, extension: 'png', livingClueId: 8)]);
    Widget view() => MaterialApp(home: Scaffold(body: ClueCover(clue: model)));
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(requests.any((path) => path.endsWith('/files/3/access')), isTrue);
    final count = requests.length;
    model.metadata = {ClueCover.automaticDisabledKey: true};
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(find.byType(ClueCoverArt), findsOneWidget);
    expect(requests.length, count);
  });

  testWidgets('explicit cover cannot borrow an attachment from another clue',
      (tester) async {
    WebClient.instance.client = MockClient((request) async {
      expect(request.url.path.endsWith('/files'), isTrue);
      return http.Response(
          jsonEncode([
            {'id': 3, 'extension': 'png', 'living_clue_id': 99}
          ]),
          200);
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ClueCover(
                clue: clue(metadata: {'imagem_capa_arquivo_id': 3})))));
    await tester.pumpAndSettle();
    expect(find.byType(ClueCoverArt), findsOneWidget);
  });

  testWidgets('collection without a cover builds a mosaic of member images',
      (tester) async {
    final collection = clue();
    collection.category = const CategoryModel(
        id: 1,
        name: 'Coleção temática',
        type: CategoryType.online,
        colorHex: '#43D4C2',
        metadataTags: '');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ClueCover(clue: collection, collectionItems: [
      clue(url: 'https://images.test/one.jpg'),
      clue(url: 'https://images.test/two.jpg'),
      clue(),
    ]))));
    await tester.pump();
    expect(find.byType(Image), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('category artwork uses configured colors and meaningful icons', () {
    final model = clue();
    model.category = const CategoryModel(
        id: 1,
        name: 'Doutorando',
        type: CategoryType.living,
        colorHex: '#43D4C2',
        metadataTags: '');
    expect(ClueCoverArt.categoryColor(model), const Color(0xFF43D4C2));
    expect(ClueCoverArt.categoryIcon(model), Icons.person_outline);
  });
}

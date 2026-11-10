import 'dart:convert';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

/// Conventions use stable names; database IDs are discovered in each environment.
class CollectionService {
  static const categoryName = 'Coleção temática';
  static const relationName = 'Coleção contém item';
  static const orderKey = 'colecao_ordem_itens_v1';
  static bool isCollection(LivingClueModel clue) =>
      clue.category?.name == categoryName;

  /// Episode text belongs to a series, while the video clue remains independent.
  static Map? cdigEpisode(LivingClueModel collection, LivingClueModel item) {
    final source = collection.metadata?['cdig'];
    final video = item.metadata?['cdig'];
    if (source is! Map ||
        video is! Map ||
        video['type'] != 'video' ||
        source['source'] != video['source']) {
      return null;
    }
    final episodes = source['episodes'];
    if (episodes is! List) {
      return null;
    }
    for (final entry in episodes.whereType<Map>()) {
      final episodeId = (entry['ID'] ?? entry['id'])?.toString();
      if (episodeId == video['id']?.toString()) {
        final episode = entry['Episode'] ?? entry['episode'];
        return episode is Map ? episode : null;
      }
    }
    return null;
  }

  static String itemTitle(LivingClueModel collection, LivingClueModel item) {
    final episode = cdigEpisode(collection, item);
    final title = episode?['Title'] ?? episode?['title'];
    return title is String && title.trim().isNotEmpty ? title : item.name;
  }

  static String itemSubtitle(LivingClueModel collection, LivingClueModel item) {
    final episode = cdigEpisode(collection, item);
    final description = episode?['Description'] ?? episode?['description'];
    return description is String && description.trim().isNotEmpty
        ? description
        : item.category?.name ?? '';
  }

  final clues = LivingClueWebclient();
  Future<CategoryModel?> category({bool create = false}) async {
    final categories = await CategoryWebclient().fetch();
    final matches = categories.where((c) => c.name == categoryName).toList();
    if (matches.length > 1)
      throw StateError(
          'Há categorias de coleção duplicadas. Revise o cadastro.');
    if (matches.isNotEmpty) return matches.single;
    if (!create) return null;
    return CategoryWebclient().create(const CategoryModel(
        id: 0,
        name: categoryName,
        type: CategoryType.online,
        colorHex: '#43D4C2',
        metadataTags: 'tema',
        description: 'Coleção curada de pistas e conteúdos relacionados.'));
  }

  Future<ConnectionTypeModel?> relation({bool create = false}) async {
    final types = await ConnectionTypeWebclient().fetch();
    final matches = types.where((t) => t.name == relationName).toList();
    if (matches.length > 1)
      throw StateError(
          'Há tipos de pertencimento duplicados. Revise o cadastro.');
    if (matches.isNotEmpty) {
      if (!matches.single.isDirectional)
        throw StateError('A relação de coleção deve ser dirigida.');
      return matches.single;
    }
    if (!create) return null;
    return ConnectionTypeWebclient()
        .create(ConnectionTypeModel(id: 0, name: relationName));
  }

  Future<List<Map<String, dynamic>>> connections(int id) async {
    final response = await WebClient.instance.get(
        '/living_clues/$id/connections',
        [ApiInterceptor(), TokenInterceptor()],
        {});
    return (jsonDecode(response.body) as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static List<int> orderedIds(
      LivingClueModel collection, Iterable<int> memberIds) {
    final members = memberIds.toSet();
    final raw = collection.metadata?[orderKey];
    final explicit = raw is List
        ? raw
            .map((id) => int.tryParse('$id'))
            .whereType<int>()
            .where(members.contains)
            .toSet()
            .toList()
        : <int>[];
    final remaining = members.difference(explicit.toSet()).toList()..sort();
    return [...explicit, ...remaining];
  }

  Future<List<LivingClueModel>> items(LivingClueModel collection) async {
    final type = await relation();
    if (type == null) return [];
    final links = await connections(collection.id);
    final byId = <int, LivingClueModel>{};
    for (final link in links) {
      if (link['source_clue_id'] == collection.id &&
          link['connection_type_id'] == type.id &&
          link['target_clue'] is Map) {
        final item = LivingClueModel.fromJson(
            Map<String, dynamic>.from(link['target_clue']));
        byId[item.id] = item;
      }
    }
    return orderedIds(collection, byId.keys).map((id) => byId[id]!).toList();
  }

  Future<void> add(LivingClueModel collection, int itemId) async {
    if (itemId == collection.id || itemId <= 0)
      throw ArgumentError('Escolha outra pista');
    final type = (await relation(create: true))!;
    final links = await connections(collection.id);
    if (!links.any((link) =>
        link['source_clue_id'] == collection.id &&
        link['target_clue_id'] == itemId &&
        link['connection_type_id'] == type.id)) {
      await ClueConnectionWebclient().create(ClueConnectionModel(
          id: 0,
          sourceClueId: collection.id,
          targetClueId: itemId,
          connectionTypeId: type.id));
    }
  }

  Future<void> remove(LivingClueModel collection, int itemId) async {
    final type = await relation();
    if (type == null) return;
    for (final link in await connections(collection.id)) {
      if (link['source_clue_id'] == collection.id &&
          link['target_clue_id'] == itemId &&
          link['connection_type_id'] == type.id) {
        await ClueConnectionWebclient().delete(link['id']);
      }
    }
  }

  Future<LivingClueModel> saveOrder(int collectionId, List<int> ids) async {
    // Fetch a fresh model to preserve unrelated document and typed metadata.
    final current = await clues.fetchById(collectionId);
    current.metadata = {...?current.metadata, orderKey: ids.toSet().toList()};
    return clues.update(current);
  }
}

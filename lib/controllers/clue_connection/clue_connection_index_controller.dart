import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ClueConnectionIndexController extends GetxController {
  final ClueConnectionWebclient _webclient = ClueConnectionWebclient();
  final LivingClueWebclient _livingClueWebclient = LivingClueWebclient();
  final ConnectionTypeWebclient _connectionTypeWebclient = ConnectionTypeWebclient();

  final RxList<ClueConnectionModel> connections = <ClueConnectionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<int, String> clueNamesById = <int, String>{}.obs;
  final RxMap<int, String> connectionTypeNamesById = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadConnections();
  }

  Future<void> loadConnections() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _webclient.fetch(),
        _livingClueWebclient.fetch(),
        _connectionTypeWebclient.fetch(),
      ]);

      connections.assignAll(results[0] as List<ClueConnectionModel>);
      clueNamesById.assignAll({
        for (final LivingClueModel clue in results[1] as List<LivingClueModel>) clue.id: clue.name,
      });
      connectionTypeNamesById.assignAll({
        for (final ConnectionTypeModel type in results[2] as List<ConnectionTypeModel>) type.id: type.name,
      });
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar conexões. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteConnection(ClueConnectionModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      connections.removeWhere((item) => item.id == model.id);
      Get.successSnackbar('Conexão removida com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover conexão. $error');
    } finally {
      isLoading.value = false;
    }
  }

  String clueLabel(int clueId) => clueNamesById[clueId] ?? 'Pista #$clueId';

  String connectionTypeLabel(int connectionTypeId) =>
      connectionTypeNamesById[connectionTypeId] ?? 'Tipo #$connectionTypeId';
}

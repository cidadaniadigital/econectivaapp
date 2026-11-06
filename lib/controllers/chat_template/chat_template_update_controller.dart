import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/chat_template_file_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateUpdateController extends GetxController {
  final ChatTemplateWebclient _webclient = ChatTemplateWebclient();
  final ChatTemplateFileWebclient _fileWebclient = ChatTemplateFileWebclient();

  final Rxn<ChatTemplateModel> template = Rxn<ChatTemplateModel>();
  final RxBool isLoading = false.obs;

  int? templateId;

  @override
  void onInit() {
    super.onInit();
    final dynamic args = Get.arguments;
    if (args is ChatTemplateModel) {
      template.value = args;
    }

    templateId = int.tryParse(Get.parameters['id'] ?? '');
    if (templateId != null && template.value == null) {
      loadTemplate(templateId!);
    }
  }

  Future<void> loadTemplate(int id) async {
    try {
      isLoading.value = true;
      final ChatTemplateModel loaded = await _webclient.fetchById(id);
      final List<ChatTemplateFileModel> sources =
          await _fileWebclient.fetch(chatTemplateId: id);
      loaded.files = sources;
      template.value = loaded;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar template. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteSource(int sourceId) async {
    final int? id = template.value?.id ?? templateId;
    if (id == null) return false;

    try {
      isLoading.value = true;
      await _fileWebclient.delete(sourceId);
      await loadTemplate(id);
      Get.successSnackbar('Fonte removida com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível remover a fonte. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAllMessages() async {
    final int? id = template.value?.id ?? templateId;
    if (id == null) return false;

    try {
      isLoading.value = true;
      await _webclient.deleteAllMessages(id);
      Get.successSnackbar('Todas as mensagens foram excluídas com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar(
          'Erro', 'Não foi possível excluir as mensagens. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(ChatTemplateModel model) async {
    final int? id = model.id == 0 ? template.value?.id ?? templateId : model.id;
    if (id == null) return false;

    model.id = id;
    try {
      isLoading.value = true;
      await _webclient.update(model);
      Get.successSnackbar('Template salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar o template. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

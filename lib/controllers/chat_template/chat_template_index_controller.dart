import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateIndexController extends GetxController {
  final ChatTemplateWebclient _webclient = ChatTemplateWebclient();

  final RxList<ChatTemplateModel> templates = <ChatTemplateModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  static const int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    try {
      isLoading.value = true;
      final List<ChatTemplateModel> items = await _webclient.fetch(limit: pageSize, offset: 0);
      templates.assignAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Falha ao buscar templates. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      final List<ChatTemplateModel> items = await _webclient.fetch(
        limit: pageSize,
        offset: templates.length,
      );
      templates.addAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Falha ao carregar mais templates. $error');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> deleteTemplate(ChatTemplateModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      templates.removeWhere((item) => item.id == model.id);
      SafeGetSnackbar.success('Template excluído com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      final message = error.toString().toLowerCase();
      if (message.contains('404') || message.contains('page not found')) {
        SafeGetSnackbar.error(
          'Ação indisponível',
          'A API atual não possui endpoint para excluir agentes.',
        );
      } else {
        SafeGetSnackbar.error('Erro', 'Não foi possível excluir o template.');
      }
    } finally {
      isLoading.value = false;
    }
  }
}

import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateCreateController extends GetxController {
  final ChatTemplateWebclient _webclient = ChatTemplateWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(ChatTemplateModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
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

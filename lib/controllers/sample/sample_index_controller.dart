import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/webclients/sample_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class SampleIndexController extends GetxController {
  final SampleWebclient _webclient = SampleWebclient();

  final RxList<SampleModel> samples = <SampleModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSamples();
  }

  Future<void> loadSamples() async {
    try {
      isLoading.value = true;
      samples.assignAll(await _webclient.fetch());
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar samples. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSample(SampleModel sample) async {
    try {
      isLoading.value = true;
      await _webclient.delete(sample.id);
      samples.removeWhere((item) => item.id == sample.id);
      Get.successSnackbar('Sample removido com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover sample. $error');
    } finally {
      isLoading.value = false;
    }
  }
}

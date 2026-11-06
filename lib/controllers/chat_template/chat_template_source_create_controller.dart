import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/webclients/chat_template_file_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateSourceCreateController extends GetxController {
  final ChatTemplateFileWebclient _webclient = ChatTemplateFileWebclient();

  final RxBool isLoading = false.obs;

  int? templateId;

  @override
  void onInit() {
    super.onInit();
    templateId = int.tryParse(Get.parameters['id'] ?? '');
  }

  Future<bool> save({
    required String name,
    required String type,
    String? source,
    String? content,
    Uint8List? fileBytes,
    String? fileName,
    String? extension,
  }) async {
    final int? id = templateId;
    if (id == null) return false;

    try {
      isLoading.value = true;
      final String normalizedType = type.trim().toLowerCase();

      if (normalizedType == 'file') {
        if (fileBytes == null ||
            (fileName ?? '').trim().isEmpty ||
            (extension ?? '').trim().isEmpty) {
          throw Exception('Arquivo inválido para upload.');
        }
        if (fileBytes.isEmpty || fileBytes.length > 12 * 1024 * 1024) {
          throw Exception('Escolha um arquivo não vazio de até 12 MB.');
        }

        await _webclient.upload(
          chatTemplateId: id,
          name: name,
          mimeType:
              _mimeTypeFromExtension(extension!) ?? 'application/octet-stream',
          file: FileModel(
              id: 0,
              name: fileName!.trim(),
              extension: extension.trim().toLowerCase(),
              bytes: fileBytes),
        );
      } else {
        await _webclient.create(
          ChatTemplateFileModel(
            chatTemplateId: id,
            name: name,
            type: normalizedType,
            url: source?.trim(),
            content: content,
          ),
        );
      }
      Get.successSnackbar('Fonte adicionada com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível adicionar a fonte. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String? _mimeTypeFromExtension(String value) {
    final String ext = value.trim().toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_source_create_controller.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateSourceCreateScreen extends StatefulWidget {
  const ChatTemplateSourceCreateScreen({super.key});

  @override
  State<ChatTemplateSourceCreateScreen> createState() =>
      _ChatTemplateSourceCreateScreenState();
}

class _ChatTemplateSourceCreateScreenState
    extends State<ChatTemplateSourceCreateScreen> {
  static const int _maxFileBytes = 12 * 1024 * 1024;
  static const List<String> _allowedFileExtensions = <String>[
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'docx',
    'txt',
    'md',
    'csv',
    'json',
  ];

  final ChatTemplateSourceCreateController _controller =
      Get.find<ChatTemplateSourceCreateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _type = 'url';
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileExtension;

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Adicionar fonte'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Form(
              key: _formKey,
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Tipo da fonte',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'url', child: Text('Link')),
                        DropdownMenuItem(value: 'file', child: Text('Arquivo')),
                        DropdownMenuItem(value: 'text', child: Text('Texto')),
                      ],
                      onChanged: _controller.isLoading.value
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _type = value;
                                if (_type != 'file') {
                                  _fileBytes = null;
                                  _fileName = null;
                                  _fileExtension = null;
                                }
                              });
                            },
                    ),
                    Insets.large.height,
                    InputText(
                      hintText: 'Nome da fonte',
                      controller: _nameController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                        PRuleMaxString(
                          value,
                          255,
                          message: 'Máximo de 255 caracteres',
                        ),
                      ]).val(),
                    ),
                    Insets.large.height,
                    if (_type == 'url') _buildUrlField(),
                    if (_type == 'text') _buildTextField(),
                    if (_type == 'file') _buildFileField(),
                    Insets.extraLarge.height,
                    SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                        theme: ActionButtonTheme.blue,
                        title: _controller.isLoading.value
                            ? 'Salvando...'
                            : 'Salvar fonte',
                        onPressed:
                            _controller.isLoading.value ? null : _handleSubmit,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _sourceController,
      decoration: const InputDecoration(
        hintText: 'https://exemplo.com',
        border: OutlineInputBorder(),
        labelText: 'URL',
      ),
      validator: _validateUrl,
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _contentController,
      minLines: 6,
      maxLines: 10,
      decoration: const InputDecoration(
        hintText: 'Cole o conteúdo da fonte...',
        border: OutlineInputBorder(),
        labelText: 'Conteúdo',
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return 'Obrigatório';
        return null;
      },
    );
  }

  Widget _buildFileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _controller.isLoading.value ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Selecionar arquivo'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _fileName == null
              ? 'Nenhum arquivo selecionado.'
              : 'Arquivo: $_fileName',
        ),
        const Text('Tamanho máximo: 12 MB.'),
      ],
    );
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: _allowedFileExtensions,
    );
    if (result == null || result.files.isEmpty) return;
    final PlatformFile picked = result.files.single;
    if (picked.size > _maxFileBytes) {
      Get.customSnackbar(
          'Arquivo muito grande', 'Escolha um arquivo de até 12 MB.');
      return;
    }
    final Uint8List? bytes = picked.bytes;
    if (bytes == null) {
      Get.customSnackbar('Erro', 'Não foi possível ler o arquivo selecionado.');
      return;
    }

    final String extension = ((picked.extension ?? '').trim().isNotEmpty)
        ? picked.extension!.trim().toLowerCase()
        : _extensionFromName(picked.name);
    if (extension.isEmpty) {
      Get.customSnackbar(
        'Erro',
        'Não foi possível identificar a extensão do arquivo.',
      );
      return;
    }
    if (!_allowedFileExtensions.contains(extension)) {
      Get.customSnackbar(
        'Formato não suportado',
        'Extensão .$extension não é suportada para fonte.',
      );
      return;
    }

    setState(() {
      _fileBytes = bytes;
      _fileName = picked.name;
      _fileExtension = extension;
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_type == 'file' &&
        (_fileBytes == null ||
            (_fileName ?? '').trim().isEmpty ||
            (_fileExtension ?? '').trim().isEmpty)) {
      Get.customSnackbar('Erro', 'Selecione um arquivo para continuar.');
      return;
    }

    final bool saved = await _controller.save(
      name: _nameController.text.trim(),
      type: _type,
      source: _type == 'url' ? _sourceController.text.trim() : null,
      content: _type == 'text' ? _contentController.text : null,
      fileBytes: _type == 'file' ? _fileBytes : null,
      fileName: _type == 'file' ? _fileName : null,
      extension: _type == 'file' ? _fileExtension : null,
    );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _extensionFromName(String name) {
    final int dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  String? _validateUrl(String? value) {
    final String candidate = (value ?? '').trim();
    if (candidate.isEmpty) return 'Obrigatório';
    final Uri? uri = Uri.tryParse(candidate);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) ||
        uri.host.isEmpty) {
      return 'Informe uma URL válida';
    }
    return null;
  }
}

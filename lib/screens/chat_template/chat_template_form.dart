import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateFormValue {
  ChatTemplateFormValue({
    required this.name,
    this.description,
    this.systemInstruction,
    required this.files,
  });

  final String name;
  final String? description;
  final String? systemInstruction;
  final List<ChatTemplateFileModel> files;
}

class ChatTemplateForm extends StatefulWidget {
  const ChatTemplateForm({
    super.key,
    required this.submitLabel,
    required this.isLoading,
    required this.onSubmit,
    this.initialValue,
    this.showSources = true,
  });

  final String submitLabel;
  final bool isLoading;
  final ChatTemplateModel? initialValue;
  final bool showSources;
  final Future<void> Function(ChatTemplateFormValue value) onSubmit;

  @override
  State<ChatTemplateForm> createState() => _ChatTemplateFormState();
}

class _ChatTemplateFormState extends State<ChatTemplateForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FileWebclient _fileWebclient = FileWebclient();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _systemInstructionController;
  late List<_ChatTemplateSourceDraft> _sources;
  bool _isUploading = false;

  bool get _isBusy => widget.isLoading || _isUploading;

  @override
  void initState() {
    super.initState();
    final ChatTemplateModel? initialValue = widget.initialValue;
    _nameController = TextEditingController(text: initialValue?.name ?? '');
    _descriptionController =
        TextEditingController(text: initialValue?.description ?? '');
    _systemInstructionController =
        TextEditingController(text: initialValue?.systemInstruction ?? '');
    _sources = (initialValue?.files ?? const <ChatTemplateFileModel>[])
        .map(_ChatTemplateSourceDraft.fromModel)
        .toList();
  }

  @override
  void didUpdateWidget(covariant ChatTemplateForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue == widget.initialValue ||
        widget.initialValue == null) {
      return;
    }

    final ChatTemplateModel initialValue = widget.initialValue!;
    _nameController.text = initialValue.name;
    _descriptionController.text = initialValue.description ?? '';
    _systemInstructionController.text = initialValue.systemInstruction ?? '';
    for (final source in _sources) {
      source.dispose();
    }
    _sources =
        initialValue.files.map(_ChatTemplateSourceDraft.fromModel).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemInstructionController.dispose();
    for (final source in _sources) {
      source.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputText(
            hintText: 'Nome',
            controller: _nameController,
            validator: (value) => PValidator([
              PRuleRequired(value, message: 'Obrigatório'),
              PRuleMaxString(value, 255, message: 'Máximo de 255 caracteres'),
            ]).val(),
          ),
          Insets.large.height,
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Descrição',
              border: OutlineInputBorder(),
            ),
            validator: (value) => PValidator([
              PRuleMaxString(value, 2000, message: 'Máximo de 2000 caracteres'),
            ]).val(),
          ),
          Insets.large.height,
          TextFormField(
            controller: _systemInstructionController,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'System instruction',
              border: OutlineInputBorder(),
            ),
            validator: (value) => PValidator([
              PRuleRequired(value, message: 'Obrigatório'),
              PRuleMaxString(value, 10000,
                  message: 'Máximo de 10000 caracteres'),
            ]).val(),
          ),
          if (widget.showSources) ...[
            Insets.extraLarge.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fontes de contexto',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !_isBusy,
                  onSelected: (value) {
                    switch (value) {
                      case 'text':
                        _addSource(
                            _ChatTemplateSourceDraft.empty(type: 'text'));
                        break;
                      case 'url':
                        _addSource(_ChatTemplateSourceDraft.empty(type: 'url'));
                        break;
                      case 'file':
                        _pickAndUploadFile();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                        value: 'text', child: Text('Adicionar texto')),
                    PopupMenuItem<String>(
                        value: 'url', child: Text('Adicionar link')),
                    PopupMenuItem<String>(
                        value: 'file',
                        child: Text('Adicionar arquivo ou imagem')),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 4),
                        Text('Adicionar'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_sources.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Nenhuma fonte informada.'),
              ),
            for (int index = 0; index < _sources.length; index++) ...[
              _buildSourceCard(index),
              const SizedBox(height: 12),
            ],
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
          ],
          Insets.extraLarge.height,
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              theme: ActionButtonTheme.blue,
              title: _isBusy ? '${widget.submitLabel}...' : widget.submitLabel,
              onPressed: _isBusy ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(int index) {
    final _ChatTemplateSourceDraft source = _sources[index];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fonte ${index + 1} • ${_labelForType(source.type)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _isBusy ? null : () => _removeSource(index),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover fonte',
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputText(
              hintText: 'Nome da fonte',
              controller: source.nameController,
              validator: (value) => PValidator([
                if (source.type != 'file')
                  PRuleRequired(value, message: 'Obrigatório'),
                PRuleMaxString(value, 255, message: 'Máximo de 255 caracteres'),
              ]).val(),
            ),
            Insets.medium.height,
            if (source.type == 'text')
              TextFormField(
                controller: source.contentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Conteúdo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => PValidator([
                  PRuleRequired(value, message: 'Obrigatório'),
                  PRuleMaxString(value, 80000,
                      message: 'Máximo de 80000 caracteres'),
                ]).val(),
              ),
            if (source.type == 'url')
              TextFormField(
                controller: source.urlController,
                decoration: const InputDecoration(
                  hintText: 'https://exemplo.com',
                  border: OutlineInputBorder(),
                ),
                validator: _validateUrl,
              ),
            if (source.type == 'file') ...[
              Text(
                source.fileId != null
                    ? 'Arquivo enviado com sucesso. ID: ${source.fileId}'
                    : 'Arquivo ainda não enviado.',
              ),
              if ((source.fileName ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Arquivo: ${source.fileName}'),
              ],
              if ((source.mimeType ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Tipo: ${source.mimeType}'),
              ],
            ],
            if ((source.status ?? '').isNotEmpty) ...[
              Insets.small.height,
              Text('Status: ${source.status}'),
            ],
            if ((source.errorMessage ?? '').isNotEmpty) ...[
              Insets.small.height,
              Text(
                source.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addSource(_ChatTemplateSourceDraft draft) {
    setState(() {
      _sources = [..._sources, draft];
    });
  }

  void _removeSource(int index) {
    final source = _sources[index];
    setState(() {
      _sources = [..._sources]..removeAt(index);
    });
    source.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      setState(() => _isUploading = true);
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final PlatformFile picked = result.files.single;
      final Uint8List? bytes = picked.bytes;
      if (bytes == null) {
        Get.customSnackbar(
            'Erro', 'Não foi possível ler o arquivo selecionado.');
        return;
      }
      final String name = picked.name;
      final String extension = ((picked.extension ?? '').trim().isNotEmpty)
          ? picked.extension!.trim().toLowerCase()
          : _extensionFromName(name);
      if (extension.isEmpty) {
        Get.customSnackbar(
            'Erro', 'Não foi possível identificar a extensão do arquivo.');
        return;
      }

      final uploaded = await _fileWebclient.uploadBase64(
        base64: base64Encode(bytes),
        extension: extension,
        name: name,
        path: 'chat_templates/$name',
      );

      _addSource(
        _ChatTemplateSourceDraft.file(
          name: name,
          fileId: uploaded.id,
          fileName: uploaded.name ?? name,
        ),
      );
      Get.successSnackbar('Arquivo enviado com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível enviar o arquivo. $error');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.showSources &&
        _sources
            .any((source) => source.type == 'file' && source.fileId == null)) {
      Get.customSnackbar('Erro', 'Há arquivo sem upload concluído.');
      return;
    }

    final List<ChatTemplateFileModel> files = widget.showSources
        ? _sources.map((source) => source.toModel()).where((file) {
            switch (file.resolvedType) {
              case 'text':
                return file.name.trim().isNotEmpty ||
                    (file.content ?? '').trim().isNotEmpty;
              case 'url':
                return file.name.trim().isNotEmpty ||
                    (file.url ?? '').trim().isNotEmpty;
              case 'file':
                return file.fileId != null;
              default:
                return false;
            }
          }).toList()
        : (widget.initialValue?.files ?? const <ChatTemplateFileModel>[]);

    await widget.onSubmit(
      ChatTemplateFormValue(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        systemInstruction: _systemInstructionController.text.trim().isEmpty
            ? null
            : _systemInstructionController.text.trim(),
        files: files,
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'url':
        return 'Link';
      case 'file':
        return 'Arquivo';
      default:
        return 'Texto';
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

class _ChatTemplateSourceDraft {
  _ChatTemplateSourceDraft({
    required this.type,
    required this.nameController,
    required this.contentController,
    required this.urlController,
    this.id,
    this.fileId,
    this.mimeType,
    this.fileName,
    this.status,
    this.errorMessage,
  });

  final int? id;
  final String type;
  final TextEditingController nameController;
  final TextEditingController contentController;
  final TextEditingController urlController;
  int? fileId;
  String? mimeType;
  String? fileName;
  String? status;
  String? errorMessage;

  factory _ChatTemplateSourceDraft.empty({required String type}) {
    return _ChatTemplateSourceDraft(
      type: type,
      nameController: TextEditingController(),
      contentController: TextEditingController(),
      urlController: TextEditingController(),
    );
  }

  factory _ChatTemplateSourceDraft.file({
    required String name,
    required int fileId,
    String? mimeType,
    String? fileName,
  }) {
    return _ChatTemplateSourceDraft(
      type: 'file',
      nameController: TextEditingController(text: name),
      contentController: TextEditingController(),
      urlController: TextEditingController(),
      fileId: fileId,
      mimeType: mimeType,
      fileName: fileName,
      status: 'uploaded',
    );
  }

  factory _ChatTemplateSourceDraft.fromModel(ChatTemplateFileModel model) {
    final String type = model.resolvedType;
    return _ChatTemplateSourceDraft(
      id: model.id,
      type: type,
      nameController: TextEditingController(text: model.name),
      contentController: TextEditingController(
          text: type == 'text'
              ? (model.originalContent ?? model.content ?? '')
              : ''),
      urlController: TextEditingController(
          text: type == 'url' ? (model.sourceUrl ?? model.url ?? '') : ''),
      fileId: model.fileId,
      mimeType: model.mimeType,
      fileName: model.name,
      status: model.status,
      errorMessage: model.errorMessage,
    );
  }

  ChatTemplateFileModel toModel() {
    return ChatTemplateFileModel(
      id: id,
      name: nameController.text.trim(),
      mimeType: mimeType,
      content: type == 'text' ? contentController.text : null,
      type: type,
      url: type == 'url' ? urlController.text.trim() : null,
      fileId: type == 'file' ? fileId : null,
      status: status,
      errorMessage: errorMessage,
    );
  }

  void dispose() {
    nameController.dispose();
    contentController.dispose();
    urlController.dispose();
  }
}

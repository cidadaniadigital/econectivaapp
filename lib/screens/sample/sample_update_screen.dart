import 'package:unisinos_usp_app/widgets/cidig_date_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/sample/sample_update_controller.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/webclients/sample_detail_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:widgets_spo/widgets_spo.dart';

class SampleUpdateScreen extends StatefulWidget {
  const SampleUpdateScreen({super.key});

  @override
  State<SampleUpdateScreen> createState() => _SampleUpdateScreenState();
}

class _SampleUpdateScreenState extends State<SampleUpdateScreen> {
  final SampleUpdateController _controller = Get.find<SampleUpdateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sampleStringController = TextEditingController();
  final TextEditingController _sampleUniqueController = TextEditingController();
  final TextEditingController _nullableStringController =
      TextEditingController();
  final TextEditingController _sampleDoubleController = TextEditingController();
  final DateTimeController _sampleDateController = DateTimeController();
  final TextEditingController _orderNumberController =
      TextEditingController(text: '1');
  final ItemSelectController _sampleDetailSelectController =
      ItemSelectController();

  bool _filledControllers = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sampleStringController.dispose();
    _sampleUniqueController.dispose();
    _nullableStringController.dispose();
    _sampleDoubleController.dispose();
    _sampleDateController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Editar sample'),
      ),
      body: Obx(() {
        if (_controller.sampleId == null) {
          return const Center(child: Text('Sample não informado.'));
        }

        if (_controller.isLoading.value && _controller.sample.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.sample.value == null) {
          return const Center(child: Text('Sample não encontrado.'));
        }

        if (!_filledControllers && _controller.sample.value != null) {
          final sample = _controller.sample.value!;
          _nameController.text = sample.name;
          _sampleStringController.text = sample.sampleString;
          _sampleUniqueController.text = sample.sampleUnique;
          _nullableStringController.text = sample.nullableString ?? '';
          _sampleDetailSelectController.selectedItem = ItemSelect(
            id: sample.sampleDetailId,
            name: sample.sampleDetail?.sampleString ?? '',
          );
          _sampleDoubleController.text = sample.sampleDouble.toString();
          _sampleDateController.value = sample.sampleDate;
          _orderNumberController.text = (sample.orderNumber > 0 ? sample.orderNumber : 1).toString();
          _filledControllers = true;
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputText(
                      hintText: 'Nome',
                      controller: _nameController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                        PRuleMaxString(value, 255,
                            message: 'Máximo de 255 caracteres'),
                      ]).val(),
                    ),
                    Insets.large.height,
                    InputText(
                      hintText: 'Sample string',
                      controller: _sampleStringController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                        PRuleMaxString(value, 255,
                            message: 'Máximo de 255 caracteres'),
                      ]).val(),
                    ),
                    Insets.large.height,
                    InputText(
                      hintText: 'Sample unique',
                      controller: _sampleUniqueController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                        PRuleMaxString(value, 255,
                            message: 'Máximo de 255 caracteres'),
                      ]).val(),
                    ),
                    Insets.large.height,
                    InputText(
                      hintText: 'Nullable string (opcional)',
                      controller: _nullableStringController,
                      validator: (value) => PValidator([
                        PRuleMaxString(value, 255,
                            message: 'Máximo de 255 caracteres'),
                      ]).val(),
                    ),
                    Insets.large.height,
                    InputSelectApi(
                      label: 'Sample detail',
                      controller: _sampleDetailSelectController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                      ]).val(),
                      onFind: SampleDetailWebclient().select,
                    ),
                    Insets.large.height,
                    InputNumber(
                      label: 'Sample double',
                      controller: _sampleDoubleController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                        PRuleNumeric(value, message: 'Use um número válido'),
                      ]).val(),
                    ),
                    Insets.large.height,
                    CidigDateFormField(
                      label: 'Sample date',
                      controller: _sampleDateController,
                      validator: (value) => PValidator([
                        PRuleRequiredDate(value,
                            message: 'Use uma data válida'),
                      ]).val(),
                    ),
                    Insets.large.height,
                    InputNumber(
                      label: 'Ordem',
                      controller: _orderNumberController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                        PRuleInteger(value, message: 'Use um número inteiro'),
                      ]).val(),
                    ),
                    Insets.extraLarge.height,
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() {
                        final bool loading = _controller.isLoading.value;
                        final String buttonTitle =
                            loading ? 'Atualizando...' : 'Atualizar';
                        return ActionButton(
                          theme: ActionButtonTheme.blue,
                          title: buttonTitle,
                          onPressed: loading ? null : _save,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            if (_controller.isLoading.value)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final double parsedDouble =
        double.parse(_sampleDoubleController.text.trim());
    final int parsedOrder = int.parse(_orderNumberController.text.trim());

    final model = SampleModel(
      id: _controller.sample.value?.id ?? _controller.sampleId ?? 0,
      name: _nameController.text.trim(),
      sampleString: _sampleStringController.text.trim(),
      sampleUnique: _sampleUniqueController.text.trim(),
      nullableString: _nullableStringController.text.trim().isEmpty
          ? null
          : _nullableStringController.text.trim(),
      sampleDetailId: _sampleDetailSelectController.selectedItem!.id,
      sampleDouble: parsedDouble,
      sampleDate: _sampleDateController.value!,
      orderNumber: parsedOrder,
    );

    final bool saved = await _controller.save(model);
    if (saved) {
      Get.secureBack(result: true);
    }
  }
}

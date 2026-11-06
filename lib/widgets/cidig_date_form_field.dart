import 'package:flutter/material.dart';
import 'package:widgets_spo/widgets/input_form_date.dart'
    show DateTimeController;

/// A themed date input that retains the current value when the picker is closed.
class CidigDateFormField extends FormField<DateTime?> {
  CidigDateFormField(
      {super.key,
      required this.controller,
      required this.label,
      super.validator})
      : super(
            initialValue: controller.value,
            builder: (state) => (state as _CidigDateFormFieldState)._input());

  final DateTimeController controller;
  final String label;

  @override
  FormFieldState<DateTime?> createState() => _CidigDateFormFieldState();
}

class _CidigDateFormFieldState extends FormFieldState<DateTime?> {
  @override
  CidigDateFormField get widget => super.widget as CidigDateFormField;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_synchronize);
  }

  @override
  void didUpdateWidget(CidigDateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_synchronize);
      widget.controller.addListener(_synchronize);
      setValue(widget.controller.value);
    }
  }

  void _synchronize() => didChange(widget.controller.value);

  @override
  void dispose() {
    widget.controller.removeListener(_synchronize);
    super.dispose();
  }

  @override
  void reset() {
    super.reset();
    widget.controller.value = widget.initialValue;
  }

  Future<void> _choose() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final first = DateTime(1900);
    final last = DateTime(2101);
    var initial = value ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        locale: const Locale('pt', 'BR'),
        cancelText: 'Cancelar',
        confirmText: 'Selecionar');
    if (mounted && picked != null) widget.controller.value = picked;
  }

  Widget _input() => Semantics(
      button: true,
      child: InkWell(
        onTap: _choose,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
              labelText: widget.label,
              errorText: errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined,
                  semanticLabel: 'Escolher data')),
          child: Text(
              value == null
                  ? 'dd/mm/aaaa'
                  : MaterialLocalizations.of(context).formatCompactDate(value!),
              style: Theme.of(context).textTheme.bodyLarge),
        ),
      ));
}

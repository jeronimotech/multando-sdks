import 'package:flutter/material.dart';

import '../core/multando_client.dart';
import '../models/enums.dart';
import '../models/infraction.dart';
import '../models/report.dart';

/// A Material Design widget that guides the user through a 3-step report
/// creation flow:
///
/// 1. **Select infraction** from a list fetched via [MultandoClient.infractions].
/// 2. **Fill details** -- vehicle plate, location (text), date/time.
/// 3. **Review & submit** -- shows a summary then creates the report.
class ReportForm extends StatefulWidget {
  const ReportForm({
    super.key,
    required this.client,
    required this.onReportCreated,
    this.locale = 'en',
  });

  /// The initialized [MultandoClient] used to fetch infractions and create
  /// reports.
  final MultandoClient client;

  /// Callback invoked after a report has been successfully created.
  final void Function(ReportDetail) onReportCreated;

  /// Locale string used for i18n labels. Currently supports `'en'` and `'es'`.
  final String locale;

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  int _currentStep = 0;

  // Step 1 state
  List<InfractionResponse> _infractions = [];
  bool _loadingInfractions = true;
  String? _loadError;
  InfractionResponse? _selectedInfraction;

  // Step 2 state
  final _plateController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  // Step 3 state
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _fetchInfractions();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchInfractions() async {
    try {
      final infractions = await widget.client.infractions.list();
      if (mounted) {
        setState(() {
          _infractions = infractions;
          _loadingInfractions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loadingInfractions = false;
        });
      }
    }
  }

  Future<void> _submitReport() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final report = ReportCreate(
        infractionId: _selectedInfraction!.id,
        plateNumber: _plateController.text.trim(),
        location: LocationData(
          latitude: 0,
          longitude: 0,
          address: _locationController.text.trim(),
        ),
        occurredAt: _occurredAt,
        source: ReportSource.sdk,
      );

      final detail = await widget.client.reports.create(report);
      if (mounted && detail != null) {
        widget.onReportCreated(detail);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e.toString();
          _submitting = false;
        });
      }
    }
  }

  String _t(String key) {
    const en = {
      'step1_title': 'Select Infraction',
      'step2_title': 'Report Details',
      'step3_title': 'Review & Submit',
      'plate_label': 'Vehicle Plate',
      'plate_hint': 'e.g. ABC-1234',
      'plate_required': 'Plate number is required',
      'location_label': 'Location',
      'location_hint': 'Street address or description',
      'location_required': 'Location is required',
      'datetime_label': 'Date & Time',
      'change': 'Change',
      'next': 'Next',
      'back': 'Back',
      'submit': 'Submit Report',
      'submitting': 'Submitting...',
      'select_infraction': 'Please select an infraction',
      'infraction': 'Infraction',
      'plate': 'Plate',
      'location': 'Location',
      'date': 'Date',
      'severity': 'Severity',
      'loading': 'Loading infractions...',
      'error_load': 'Failed to load infractions',
      'retry': 'Retry',
      'error_submit': 'Submission failed',
    };
    const es = {
      'step1_title': 'Seleccionar Infraccion',
      'step2_title': 'Detalles del Reporte',
      'step3_title': 'Revisar y Enviar',
      'plate_label': 'Placa del Vehiculo',
      'plate_hint': 'ej. ABC-1234',
      'plate_required': 'La placa es requerida',
      'location_label': 'Ubicacion',
      'location_hint': 'Direccion o descripcion',
      'location_required': 'La ubicacion es requerida',
      'datetime_label': 'Fecha y Hora',
      'change': 'Cambiar',
      'next': 'Siguiente',
      'back': 'Atras',
      'submit': 'Enviar Reporte',
      'submitting': 'Enviando...',
      'select_infraction': 'Seleccione una infraccion',
      'infraction': 'Infraccion',
      'plate': 'Placa',
      'location': 'Ubicacion',
      'date': 'Fecha',
      'severity': 'Gravedad',
      'loading': 'Cargando infracciones...',
      'error_load': 'Error al cargar infracciones',
      'retry': 'Reintentar',
      'error_submit': 'Error al enviar',
    };
    final strings = widget.locale == 'es' ? es : en;
    return strings[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _onStepContinue,
      onStepCancel: _onStepCancel,
      controlsBuilder: _buildControls,
      steps: [
        Step(
          title: Text(_t('step1_title')),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          content: _buildStep1(),
        ),
        Step(
          title: Text(_t('step2_title')),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          content: _buildStep2(),
        ),
        Step(
          title: Text(_t('step3_title')),
          isActive: _currentStep >= 2,
          state: _submitting ? StepState.loading : StepState.indexed,
          content: _buildStep3(),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedInfraction == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('select_infraction'))),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      _submitReport();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final isLastStep = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _submitting ? null : details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B5EEF),
              foregroundColor: Colors.white,
            ),
            child: Text(
              isLastStep
                  ? (_submitting ? _t('submitting') : _t('submit'))
                  : _t('next'),
            ),
          ),
          const SizedBox(width: 12),
          if (_currentStep > 0)
            TextButton(
              onPressed: _submitting ? null : details.onStepCancel,
              child: Text(_t('back')),
            ),
        ],
      ),
    );
  }

  // -- Step 1: Select Infraction --

  Widget _buildStep1() {
    if (_loadingInfractions) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_t('loading')),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Column(
        children: [
          Text(
            _t('error_load'),
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _loadingInfractions = true;
                _loadError = null;
              });
              _fetchInfractions();
            },
            child: Text(_t('retry')),
          ),
        ],
      );
    }

    return Column(
      children: _infractions.map((infraction) {
        final selected = _selectedInfraction?.id == infraction.id;
        return Card(
          elevation: selected ? 4 : 1,
          color: selected ? const Color(0xFFE8EDFD) : null,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF3B5EEF) : Colors.grey,
            ),
            title: Text(
              infraction.name,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              infraction.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _SeverityChip(severity: infraction.severity),
            onTap: () => setState(() => _selectedInfraction = infraction),
          ),
        );
      }).toList(),
    );
  }

  // -- Step 2: Fill Details --

  Widget _buildStep2() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: _t('plate_label'),
              hintText: _t('plate_hint'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.directions_car),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _t('plate_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: _t('location_label'),
              hintText: _t('location_hint'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _t('location_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _t('datetime_label'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_occurredAt.year}-'
                    '${_occurredAt.month.toString().padLeft(2, '0')}-'
                    '${_occurredAt.day.toString().padLeft(2, '0')} '
                    '${_occurredAt.hour.toString().padLeft(2, '0')}:'
                    '${_occurredAt.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _pickDateTime,
                child: Text(_t('change')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // -- Step 3: Review & Submit --

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(
          label: _t('infraction'),
          value: _selectedInfraction?.name ?? '',
        ),
        _ReviewRow(
          label: _t('severity'),
          value: _selectedInfraction?.severity.value ?? '',
        ),
        _ReviewRow(
          label: _t('plate'),
          value: _plateController.text,
        ),
        _ReviewRow(
          label: _t('location'),
          value: _locationController.text,
        ),
        _ReviewRow(
          label: _t('date'),
          value: '${_occurredAt.year}-'
              '${_occurredAt.month.toString().padLeft(2, '0')}-'
              '${_occurredAt.day.toString().padLeft(2, '0')} '
              '${_occurredAt.hour.toString().padLeft(2, '0')}:'
              '${_occurredAt.minute.toString().padLeft(2, '0')}',
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            '${_t('error_submit')}: $_submitError',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});

  final InfractionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _meta(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  static (String, Color) _meta(InfractionSeverity s) {
    switch (s) {
      case InfractionSeverity.low:
        return ('Low', const Color(0xFF10B981));
      case InfractionSeverity.medium:
        return ('Medium', const Color(0xFFF59E0B));
      case InfractionSeverity.high:
        return ('High', const Color(0xFFEF4444));
      case InfractionSeverity.critical:
        return ('Critical', const Color(0xFF7C3AED));
    }
  }
}

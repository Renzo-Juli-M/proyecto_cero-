import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/period_model.dart';
import '../../data/models/event_model.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isImporting = false;
  bool _isLoadingPeriods = false;
  bool _isLoadingEvents = false;

  String? _selectedFileName;
  String? _selectedFilePath;
  String _importType = 'students';

  // NUEVO: Periodos y eventos
  List<PeriodModel> _periods = [];
  List<EventModel> _events = [];
  PeriodModel? _selectedPeriod;
  EventModel? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadPeriods(); // Cargar periodos al iniciar
  }

  // ========== MÉTODOS NUEVOS ==========

  Future<void> _loadPeriods() async {
    setState(() => _isLoadingPeriods = true);

    try {
      print('🔄 Intentando cargar periodos...');
      final dataSource = AdminRemoteDataSourceImpl(sl<DioClient>());
      final periods = await dataSource.getPeriods();

      print('✅ Periodos cargados: ${periods.length}');

      setState(() {
        _periods = periods;
        _isLoadingPeriods = false;

        // Seleccionar automáticamente el periodo activo si existe
        if (periods.isNotEmpty) {
          final activePeriod = periods.firstWhere(
                (p) => p.isActive,
            orElse: () => periods.first,
          );
          _selectedPeriod = activePeriod;
          print('✅ Periodo seleccionado: ${activePeriod.name}');

          // Cargar eventos del periodo seleccionado
          if (_selectedPeriod != null) {
            _loadEvents(_selectedPeriod!.id);
          }
        } else {
          print('⚠️ No hay periodos disponibles');
          _showMessage('No hay periodos disponibles. Por favor crea un periodo primero.', isError: true);
        }
      });
    } catch (e) {
      print('❌ Error al cargar periodos: $e');
      setState(() => _isLoadingPeriods = false);
      _showMessage('Error al cargar periodos: $e', isError: true);
    }
  }

  Future<void> _loadEvents(int periodId) async {
    setState(() => _isLoadingEvents = true);

    try {
      final dataSource = AdminRemoteDataSourceImpl(sl<DioClient>());
      final events = await dataSource.getEventsByPeriod(periodId);

      setState(() {
        _events = events;
        _isLoadingEvents = false;
        _selectedEvent = null; // Resetear evento seleccionado
      });
    } catch (e) {
      setState(() => _isLoadingEvents = false);
      _showMessage('Error al cargar eventos: $e', isError: true);
    }
  }

  // ========== MÉTODOS EXISTENTES ACTUALIZADOS ==========

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      _showMessage('Error al seleccionar archivo: $e', isError: true);
    }
  }

  Future<void> _importFile() async {
    if (_selectedFilePath == null) {
      _showMessage('Por favor selecciona un archivo', isError: true);
      return;
    }

    // NUEVO: Validar periodo para estudiantes
    if (_importType == 'students' && _selectedPeriod == null) {
      _showMessage('Por favor selecciona un periodo', isError: true);
      return;
    }

    setState(() => _isImporting = true);

    try {
      final dataSource = AdminRemoteDataSourceImpl(sl<DioClient>());
      dynamic response;

      switch (_importType) {
        case 'students':
        // ACTUALIZADO: Enviar period_id y event_id
          response = await dataSource.importStudents(
            _selectedFilePath!,
            periodId: _selectedPeriod!.id,
            eventId: _selectedEvent?.id,
          );
          break;
        case 'jurors':
          response = await dataSource.importJurors(_selectedFilePath!);
          break;
        case 'articles':
          response = await dataSource.importArticles(_selectedFilePath!);
          break;
      }

      final data = response.data;
      final imported = data['summary']?['imported'] ?? data['imported'] ?? 0;
      final errors = data['errors'] as List? ?? [];

      if (errors.isEmpty) {
        _showMessage('✅ Se importaron $imported registros exitosamente');
        setState(() {
          _selectedFileName = null;
          _selectedFilePath = null;
        });
      } else {
        _showErrorDialog(imported, errors);
      }
    } catch (e) {
      _showMessage('Error al importar: $e', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showErrorDialog(int imported, List errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Importación con errores'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ Registros importados: $imported'),
              const SizedBox(height: 8),
              Text('❌ Errores encontrados: ${errors.length}'),
              const Divider(),
              const Text(
                'Errores:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• Fila ${error['row']}: ${error['errors'].join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Datos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Selector de tipo
            _buildTypeSelector(),

            const SizedBox(height: 32),

            // NUEVO: Selectores de Periodo y Evento (solo para estudiantes)
            if (_importType == 'students') ...[
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              _buildEventSelector(),
              const SizedBox(height: 32),
            ],

            // Información del formato
            _buildFormatInfo(),

            const SizedBox(height: 32),

            // Selector de archivo
            _buildFilePicker(),

            const SizedBox(height: 32),

            // Botón de importar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isImporting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Importar Datos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGETS NUEVOS ==========

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Periodo Académico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(color: AppColors.error, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedPeriod != null
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: _isLoadingPeriods
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
              : _periods.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay periodos disponibles',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<PeriodModel>(
              isExpanded: true,
              value: _selectedPeriod,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Seleccionar periodo'),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              period.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              period.dateRange,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (period.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                  _selectedEvent = null;
                  _events = [];
                });
                if (period != null) {
                  _loadEvents(period.id);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Evento (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedEvent != null
                  ? AppColors.accent
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: _isLoadingEvents
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
              : _selectedPeriod == null
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Primero selecciona un periodo',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
              : _events.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay eventos para este periodo',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<EventModel?>(
              isExpanded: true,
              value: _selectedEvent,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Seleccionar evento (opcional)'),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: [
                const DropdownMenuItem<EventModel?>(
                  value: null,
                  child: Text(
                    'Sin evento específico',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ..._events.map((event) {
                  return DropdownMenuItem(
                    value: event,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (event.location != null)
                          Text(
                            event.location!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (event) {
                setState(() => _selectedEvent = event);
              },
            ),
          ),
        ),
        if (_selectedEvent != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Fechas: ${_selectedEvent!.dateRange}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // ========== WIDGETS EXISTENTES ==========

  Widget _buildTypeSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Estudiantes'),
          subtitle: const Text('Importar alumnos ponentes y oyentes'),
          value: 'students',
          groupValue: _importType,
          onChanged: (value) => setState(() {
            _importType = value!;
            _selectedFileName = null;
            _selectedFilePath = null;
          }),
          activeColor: AppColors.primary,
        ),
        RadioListTile<String>(
          title: const Text('Jurados'),
          subtitle: const Text('Importar evaluadores'),
          value: 'jurors',
          groupValue: _importType,
          onChanged: (value) => setState(() {
            _importType = value!;
            _selectedFileName = null;
            _selectedFilePath = null;
          }),
          activeColor: AppColors.primary,
        ),
        RadioListTile<String>(
          title: const Text('Artículos'),
          subtitle: const Text('Importar artículos de investigación'),
          value: 'articles',
          groupValue: _importType,
          onChanged: (value) => setState(() {
            _importType = value!;
            _selectedFileName = null;
            _selectedFilePath = null;
          }),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildFormatInfo() {
    Map<String, List<String>> formats = {
      'students': [
        'dni',
        'codigo',
        'nombres',
        'apellidos',
        'tipo (ponente/oyente)',
        'email',
        'sede',  // NUEVO
        'escuela profesional',  // NUEVO
        'programa estudio',  // NUEVO
        'ciclo',  // NUEVO
        'grupo',  // NUEVO
        'usuario',  // NUEVO
        'foto (opcional)',  // NUEVO
      ],
      'jurors': [
        'dni',
        'usuario',
        'nombres',
        'apellidos',
        'email',
        'especialidad'
      ],
      'articles': [
        'dni_ponente',
        'titulo',
        'descripcion',
        'tipo (revision_sistematica/empirico/teorico/estudio_caso)',
        'fecha_presentacion',
        'hora_presentacion',
        'turno (mañana/tarde)'
      ],
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Formato del archivo Excel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'El archivo debe contener las siguientes columnas:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...formats[_importType]!.map(
                (col) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                '• $col',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archivo seleccionado',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _isImporting ? null : _pickFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedFileName != null
                    ? AppColors.primary
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _selectedFileName != null
                        ? Icons.insert_drive_file
                        : Icons.upload_file,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ?? 'Ningún archivo seleccionado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedFileName != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedFileName != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFileName != null
                            ? 'Toca para cambiar'
                            : 'Toca para seleccionar un archivo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFileName != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selectedFileName = null;
                      _selectedFilePath = null;
                    }),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
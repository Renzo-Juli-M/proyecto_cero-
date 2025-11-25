import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class ArticleFormPage extends StatefulWidget {
  final dynamic article;

  const ArticleFormPage({super.key, this.article});

  @override
  State<ArticleFormPage> createState() => _ArticleFormPageState();
}

class _ArticleFormPageState extends State<ArticleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<dynamic> _ponentes = [];
  int? _selectedStudentId;
  String _type = 'empirico';
  String? _shift;
  DateTime? _presentationDate;
  TimeOfDay? _presentationTime;
  bool _isLoading = false;
  bool _isLoadingPonentes = true;

  final Map<String, String> _articleTypes = {
    'revision_sistematica': 'Revisión Sistemática',
    'empirico': 'Empírico',
    'teorico': 'Teórico',
    'estudio_caso': 'Estudio de Caso',
  };

  bool get isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();

    // Cargar ponentes primero
    _loadPonentes();

    // Cargar datos del artículo si está editando
    if (isEditing) {
      _titleController.text = widget.article['title'] ?? '';
      _descriptionController.text = widget.article['description'] ?? '';
      _selectedStudentId = widget.article['student_id'];
      _type = widget.article['type'] ?? 'empirico';
      _shift = widget.article['shift'];

      // ✨ FIX: Parsear fecha correctamente
      if (widget.article['presentation_date'] != null) {
        try {
          final dateStr = widget.article['presentation_date'].toString();
          // Puede venir como "2025-11-24" o "2025-11-24T10:30:00"
          _presentationDate = DateTime.parse(dateStr.split('T')[0]);
        } catch (e) {
          print('Error parseando fecha: $e');
        }
      }

      // ✨ FIX: Parsear hora correctamente
      if (widget.article['presentation_time'] != null) {
        try {
          final timeStr = widget.article['presentation_time'].toString();

          // Puede venir en varios formatos:
          // 1. "10:30:00" (formato SQL TIME)
          // 2. "10:30" (formato corto)
          // 3. "2025-11-24T10:30:00" (formato ISO timestamp)

          String hourMin;
          if (timeStr.contains('T')) {
            // Formato ISO: extraer la parte de hora
            hourMin = timeStr.split('T')[1].substring(0, 5);
          } else if (timeStr.contains(':')) {
            // Formato "HH:MM:SS" o "HH:MM"
            final parts = timeStr.split(':');
            hourMin = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
          } else {
            // Fallback: asumir formato HH:MM
            hourMin = timeStr;
          }

          final timeParts = hourMin.split(':');
          _presentationTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } catch (e) {
          print('Error parseando hora: $e');
        }
      }
    }
  }

  Future<void> _loadPonentes() async {
    setState(() => _isLoadingPonentes = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.get(
        '/admin/students',
        queryParameters: {'type': 'ponente', 'per_page': 100},
      );

      if (mounted) {
        setState(() {
          _ponentes = response.data['data']['data'];
          _isLoadingPonentes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPonentes = false);
        // ✨ FIX: Usar WidgetsBinding para mostrar el mensaje después del build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMessage('Error al cargar ponentes: $e', isError: true);
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudentId == null) {
      _showMessage('Por favor selecciona un ponente', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final data = {
        'student_id': _selectedStudentId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'type': _type,
        'presentation_date': _presentationDate?.toIso8601String().split('T')[0],
        'presentation_time': _presentationTime != null
            ? '${_presentationTime!.hour.toString().padLeft(2, '0')}:${_presentationTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'shift': _shift,
      };

      if (isEditing) {
        await dioClient.put('/admin/articles/${widget.article['id']}', data: data);
      } else {
        await dioClient.post('/admin/articles', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Artículo actualizado exitosamente'
                : 'Artículo creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _presentationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _presentationDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _presentationTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _presentationTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Artículo' : 'Nuevo Artículo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingPonentes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ponente
              const Text(
                'Ponente *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedStudentId,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                hint: const Text('Selecciona un ponente'),
                items: _ponentes.map<DropdownMenuItem<int>>((student) {
                  return DropdownMenuItem<int>(
                    value: student['id'],
                    child: Text(
                      '${student['first_name']} ${student['last_name']} (${student['dni']})',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStudentId = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _titleController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Título del Artículo *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de artículo
              const Text(
                'Tipo de Artículo *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ..._articleTypes.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: _type,
                  onChanged: (value) => setState(() => _type = value!),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Fecha de presentación
              const Text(
                'Fecha de Presentación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _presentationDate != null
                            ? DateFormat('dd/MM/yyyy')
                            .format(_presentationDate!)
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _presentationDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_presentationDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() => _presentationDate = null);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hora de presentación
              const Text(
                'Hora de Presentación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 12),
                      Text(
                        _presentationTime != null
                            ? _presentationTime!.format(context)
                            : 'Seleccionar hora',
                        style: TextStyle(
                          color: _presentationTime != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_presentationTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() => _presentationTime = null);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Turno
              const Text(
                'Turno',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String?>(
                      title: const Text('Sin turno'),
                      value: null,
                      groupValue: _shift,
                      onChanged: (value) => setState(() => _shift = value),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _shift == null
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String?>(
                      title: const Text('Mañana'),
                      value: 'mañana',
                      groupValue: _shift,
                      onChanged: (value) => setState(() => _shift = value),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _shift == 'mañana'
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RadioListTile<String?>(
                      title: const Text('Tarde'),
                      value: 'tarde',
                      groupValue: _shift,
                      onChanged: (value) => setState(() => _shift = value),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _shift == 'tarde'
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEditing ? 'Actualizar' : 'Guardar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
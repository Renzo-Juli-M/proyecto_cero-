import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/period_model.dart';
import 'student_form_page.dart';

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  State<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  List<dynamic> _students = [];
  List<PeriodModel> _periods = [];
  List<String> _escuelas = []; // ✅ NUEVO
  bool _isLoading = true;
  bool _isLoadingPeriods = false;

  String _searchQuery = '';
  String? _filterType;
  String? _filterEscuela; // ✅ NUEVO
  PeriodModel? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
    _loadEscuelas(); // ✅ NUEVO
  }

  // ========== CARGAR ESCUELAS ========== ✅ NUEVO

  Future<void> _loadEscuelas() async {
    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.get('/admin/students');

      // Extraer escuelas únicas de los estudiantes
      final students = response.data['data']['data'] as List;
      final escuelasSet = <String>{};

      for (var student in students) {
        if (student['escuela_profesional'] != null &&
            student['escuela_profesional'].toString().isNotEmpty) {
          escuelasSet.add(student['escuela_profesional']);
        }
      }

      setState(() {
        _escuelas = escuelasSet.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error al cargar escuelas: $e');
    }
  }

  // ========== CARGAR PERIODOS ==========

  Future<void> _loadPeriods() async {
    setState(() => _isLoadingPeriods = true);

    try {
      final dataSource = AdminRemoteDataSourceImpl(sl<DioClient>());
      final periods = await dataSource.getPeriods();

      setState(() {
        _periods = periods;
        _isLoadingPeriods = false;

        // Seleccionar automáticamente el periodo activo si existe
        if (periods.isNotEmpty) {
          _selectedPeriod = periods.firstWhere(
                (p) => p.isActive,
            orElse: () => periods.first,
          );
        }
      });

      // Cargar estudiantes después de cargar periodos
      _loadStudents();
    } catch (e) {
      setState(() => _isLoadingPeriods = false);
      _showMessage('Error al cargar periodos: $e', isError: true);
      // Cargar estudiantes sin filtro de periodo
      _loadStudents();
    }
  }

  // ========== CARGAR ESTUDIANTES ==========

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final params = <String, dynamic>{};

      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      if (_filterType != null) {
        params['type'] = _filterType;
      }

      // Filtro por periodo
      if (_selectedPeriod != null) {
        params['period_id'] = _selectedPeriod!.id;
      }

      // ✅ NUEVO: Filtro por escuela
      if (_filterEscuela != null) {
        params['escuela_profesional'] = _filterEscuela;
      }

      final response = await dioClient.get(
        '/admin/students',
        queryParameters: params,
      );

      setState(() {
        _students = response.data['data']['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error al cargar estudiantes: $e', isError: true);
    }
  }

  Future<void> _deleteStudent(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar a $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dioClient = sl<DioClient>();
      await dioClient.delete('/admin/students/$id');
      _showMessage('Estudiante eliminado exitosamente');
      _loadStudents();
    } catch (e) {
      _showMessage('Error al eliminar: $e', isError: true);
    }
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
        title: const Text('Estudiantes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // ✅ BOTÓN DE FILTRO POR TIPO

          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Filtrar por tipo',
            onPressed: _showFilterTypeDialog,
          ),
          // ✅ NUEVO: BOTÓN DE FILTRO POR ESCUELA
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'Filtrar por escuela',
            onPressed: _showFilterEscuelaDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ========== FILTROS ==========
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por DNI, código o nombre...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadStudents();
                  },
                ),

                const SizedBox(height: 12),

                // Selector de Periodo
                _buildPeriodSelector(),

                const SizedBox(height: 8),

                // Chips de filtros activos
                _buildFilterChips(),
              ],
            ),
          ),

          // ========== LISTA ==========
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay estudiantes registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_selectedPeriod != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'en el periodo ${_selectedPeriod!.name}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            )
                : Column(
              children: [
                // Contador de resultados
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: AppColors.primary.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_students.length} estudiantes',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_selectedPeriod != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${_selectedPeriod!.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Lista de estudiantes
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadStudents,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return _StudentCard(
                          student: student,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentFormPage(
                                  student: student,
                                ),
                              ),
                            ).then((_) => _loadStudents());
                          },
                          onDelete: () => _deleteStudent(
                            student['id'],
                            '${student['first_name']} ${student['last_name']}',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentFormPage(),
            ),
          ).then((_) => _loadStudents());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ========== SELECTOR DE PERIODO ==========

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPeriod != null
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: _isLoadingPeriods
          ? const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      )
          : _periods.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No hay periodos disponibles',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      )
          : DropdownButtonHideUnderline(
        child: DropdownButton<PeriodModel?>(
          isExpanded: true,
          value: _selectedPeriod,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Seleccionar periodo'),
              ],
            ),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          items: [
            // Opción "Todos"
            const DropdownMenuItem<PeriodModel?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.all_inclusive,
                      size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Todos los periodos',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de periodos
            ..._periods.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: period.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
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
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (period.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (period) {
            setState(() => _selectedPeriod = period);
            _loadStudents();
          },
        ),
      ),
    );
  }

  // ========== CHIPS DE FILTROS ==========

  Widget _buildFilterChips() {
    final chips = <Widget>[];

    // Chip de tipo
    if (_filterType != null) {
      chips.add(
        Chip(
          avatar: Icon(
            _filterType == 'ponente' ? Icons.person : Icons.people,
            size: 16,
          ),
          label: Text(_filterType == "ponente" ? "Ponentes" : "Oyentes"),
          onDeleted: () {
            setState(() => _filterType = null);
            _loadStudents();
          },
          deleteIcon: const Icon(Icons.close, size: 16),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          labelStyle: const TextStyle(fontSize: 12),
        ),
      );
    }

    // ✅ NUEVO: Chip de escuela
    if (_filterEscuela != null) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.school, size: 16),
          label: Text(_filterEscuela!),
          onDeleted: () {
            setState(() => _filterEscuela = null);
            _loadStudents();
          },
          deleteIcon: const Icon(Icons.close, size: 16),
          backgroundColor: Colors.purple.withOpacity(0.1),
          labelStyle: const TextStyle(fontSize: 12),
        ),
      );
    }

    // Chip de búsqueda
    if (_searchQuery.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.search, size: 16),
          label: Text('Buscar: "$_searchQuery"'),
          onDeleted: () {
            setState(() => _searchQuery = '');
            _loadStudents();
          },
          deleteIcon: const Icon(Icons.close, size: 16),
          backgroundColor: AppColors.accent.withOpacity(0.1),
          labelStyle: const TextStyle(fontSize: 12),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: chips,
    );
  }

  // ========== DIÁLOGO: FILTRO POR TIPO ==========

  void _showFilterTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por tipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('Todos'),
              value: null,
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value);
                Navigator.pop(context);
                _loadStudents();
              },
            ),
            RadioListTile<String?>(
              title: const Text('Ponentes'),
              value: 'ponente',
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value);
                Navigator.pop(context);
                _loadStudents();
              },
            ),
            RadioListTile<String?>(
              title: const Text('Oyentes'),
              value: 'oyente',
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value);
                Navigator.pop(context);
                _loadStudents();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== ✅ NUEVO: DIÁLOGO FILTRO POR ESCUELA ==========

  void _showFilterEscuelaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por escuela'),
        content: SizedBox(
          width: double.maxFinite,
          child: _escuelas.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay escuelas disponibles'),
          )
              : ListView(
            shrinkWrap: true,
            children: [
              // Opción "Todas"
              RadioListTile<String?>(
                title: const Text('Todas las escuelas'),
                value: null,
                groupValue: _filterEscuela,
                onChanged: (value) {
                  setState(() => _filterEscuela = value);
                  Navigator.pop(context);
                  _loadStudents();
                },
              ),
              const Divider(),
              // Lista de escuelas
              ..._escuelas.map((escuela) {
                return RadioListTile<String?>(
                  title: Text(escuela),
                  value: escuela,
                  groupValue: _filterEscuela,
                  onChanged: (value) {
                    setState(() => _filterEscuela = value);
                    Navigator.pop(context);
                    _loadStudents();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== CARD DE ESTUDIANTE ==========

class _StudentCard extends StatelessWidget {
  final dynamic student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPonente = student['type'] == 'ponente';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isPonente
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.1),
                    child: Icon(
                      isPonente ? Icons.person : Icons.people,
                      color: isPonente ? AppColors.primary : AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info básica
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${student['first_name']} ${student['last_name']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                student['dni'] ?? 'N/A',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.school, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                student['student_code'] ?? 'N/A',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Badge de tipo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPonente
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPonente ? 'PONENTE' : 'OYENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPonente ? AppColors.primary : AppColors.accent,
                      ),
                    ),
                  ),

                  // Menú de acciones
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: onEdit,
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: onDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Información académica
              if (student['sede'] != null ||
                  student['escuela_profesional'] != null ||
                  student['programa_estudio'] != null ||
                  student['ciclo'] != null ||
                  student['grupo'] != null) ...[
                const Divider(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Sede
                    if (student['sede'] != null)
                      _InfoChip(
                        icon: Icons.location_on,
                        label: student['sede'],
                        color: Colors.blue,
                      ),

                    // Escuela
                    if (student['escuela_profesional'] != null)
                      _InfoChip(
                        icon: Icons.school,
                        label: student['escuela_profesional'],
                        color: Colors.purple,
                      ),

                    // Ciclo
                    if (student['ciclo'] != null)
                      _InfoChip(
                        icon: Icons.numbers,
                        label: 'Ciclo ${student['ciclo']}',
                        color: Colors.orange,
                      ),

                    // Grupo
                    if (student['grupo'] != null)
                      _InfoChip(
                        icon: Icons.group,
                        label: 'Grupo ${student['grupo']}',
                        color: Colors.green,
                      ),
                  ],
                ),
              ],

              // Periodo y Evento
              if (student['period'] != null || student['event'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Periodo
                    if (student['period'] != null) ...[
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        student['period']['name'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    // Evento
                    if (student['event'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.event, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          student['event']['name'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ========== WIDGET DE INFO CHIP ==========

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Color.fromARGB(
                  255,
                  (color.red * 0.7).toInt(),
                  (color.green * 0.7).toInt(),
                  (color.blue * 0.7).toInt(),
                ),

                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
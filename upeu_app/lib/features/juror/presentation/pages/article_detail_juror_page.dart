import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart'; // 🔧 IMPORTANTE
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class ArticleDetailJurorPage extends StatefulWidget {
  final int articleId;

  const ArticleDetailJurorPage({super.key, required this.articleId});

  @override
  State<ArticleDetailJurorPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailJurorPage> {
  dynamic _article;
  dynamic _statistics;
  List<dynamic> _availableJurors = [];
  List<int> _selectedJurorIds = [];
  bool _isLoading = true;
  bool _isLoadingJurors = false;
  bool _isAssigning = false;

  final Map<String, String> _articleTypes = {
    'revision_sistematica': 'Revisión Sistemática',
    'empirico': 'Empírico',
    'teorico': 'Teórico',
    'estudio_caso': 'Estudio de Caso',
  };

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadArticleDetails();
  }

  Future<void> _loadArticleDetails() async {
    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();

      final articleResponse = await dioClient.get(
        ApiConstants.articleDetail(widget.articleId),
      );

      final statsResponse = await dioClient.get(
        ApiConstants.articleStatistics(widget.articleId),
      );

      setState(() {
        _article = articleResponse.data['data'];
        _statistics = statsResponse.data['data'];
        _selectedJurorIds = (_article['jurors'] as List)
            .map<int>((j) => j['id'] as int)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showMessage('Error al cargar detalles: $e', isError: true);
      }
    }
  }

  Future<void> _loadAvailableJurors() async {
    setState(() => _isLoadingJurors = true);

    try {
      final dioClient = sl<DioClient>();

      // 🔧 USAR LA CONSTANTE
      final response = await dioClient.get(ApiConstants.availableJurors);

      print('✅ Response: ${response.data}');

      setState(() {
        final responseData = response.data['data'];

        if (responseData is List) {
          _availableJurors = responseData;
        } else {
          _availableJurors = [];
        }

        _isLoadingJurors = false;
        print('✅ Jurados cargados: ${_availableJurors.length}');
      });
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      setState(() => _isLoadingJurors = false);

      if (mounted) {
        _showMessage('Error al cargar jurados: $e', isError: true);
      }
    }
  }

  Future<void> _assignJurors() async {
    if (_selectedJurorIds.length < 2) {
      _showMessage('Debe seleccionar al menos 2 jurados', isError: true);
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final dioClient = sl<DioClient>();
      await dioClient.post(
        ApiConstants.assignJurors(widget.articleId),
        data: {'juror_ids': _selectedJurorIds},
      );

      if (mounted) {
        _showMessage('Jurados asignados exitosamente');
        Navigator.pop(context);
        _loadArticleDetails();
      }
    } catch (e) {
      setState(() => _isAssigning = false);
      if (mounted) {
        _showMessage('Error al asignar jurados: $e', isError: true);
      }
    }
  }

  void _showAssignJurorsDialog() {
    _loadAvailableJurors();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Asignar Jurados'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingJurors
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando jurados...'),
                ],
              ),
            )
                : _availableJurors.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: AppColors.warning, size: 48),
                  SizedBox(height: 8),
                  Text('No hay jurados disponibles'),
                ],
              ),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecciona al menos 2 jurados:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableJurors.length,
                    itemBuilder: (context, index) {
                      final juror = _availableJurors[index];
                      final isSelected =
                      _selectedJurorIds.contains(juror['id']);

                      return CheckboxListTile(
                        title: Text(
                          '${juror['first_name']} ${juror['last_name']}',
                        ),
                        subtitle: Text(
                            juror['specialty'] ?? 'Sin especialidad'),
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedJurorIds.add(juror['id']);
                            } else {
                              _selectedJurorIds.remove(juror['id']);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleccionados: ${_selectedJurorIds.length}',
                  style: TextStyle(
                    color: _selectedJurorIds.length >= 2
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isAssigning ? null : _assignJurors,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isAssigning
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Artículo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [

        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadArticleDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _article['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _articleTypes[_article['type']] ?? _article['type'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                'Ponente',
                Icons.person,
                '${_article['student']['first_name']} ${_article['student']['last_name']}',
                'DNI: ${_article['student']['dni']}',
              ),
              const SizedBox(height: 16),
              if (_article['description'] != null) ...[
                _buildInfoSection(
                  'Descripción',
                  Icons.description,
                  _article['description'],
                  null,
                ),
                const SizedBox(height: 16),
              ],
              if (_article['presentation_date'] != null) ...[
                _buildInfoSection(
                  'Fecha de Presentación',
                  Icons.calendar_today,
                  DateFormat('dd/MM/yyyy').format(
                    DateTime.parse(_article['presentation_date']),
                  ),
                  _article['presentation_time'] != null
                      ? 'Hora: ${_article['presentation_time']}'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              if (_article['shift'] != null) ...[
                _buildInfoSection(
                  'Turno',
                  Icons.wb_sunny,
                  _article['shift'] == 'mañana' ? 'Mañana' : 'Tarde',
                  null,
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              const Text(
                'Jurados Asignados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildJurorsList(),
              const SizedBox(height: 24),
              if (_article['evaluations'] != null &&
                  (_article['evaluations'] as List).isNotEmpty) ...[
                const Text(
                  'Evaluaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEvaluationsList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, IconData icon, String value, String? subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final avgScore = _toDouble(_statistics['average_score']);
    final totalEvaluations = _statistics['total_evaluations'] ?? 0;
    final totalAttendances = _statistics['total_attendances'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
          'Evaluaciones',
          '$totalEvaluations',
          Icons.star,
          AppColors.warning,
        ),
        _buildStatCard(
          'Promedio',
          avgScore > 0 ? avgScore.toStringAsFixed(2) : 'N/A',
          Icons.trending_up,
          AppColors.info,
        ),
        _buildStatCard(
          'Asistencias',
          '$totalAttendances',
          Icons.people,
          AppColors.accent,
        ),
        _buildStatCard(
          'Jurados',
          '${(_article['jurors'] as List).length}',
          Icons.gavel,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurorsList() {
    if (_article['jurors'] == null || (_article['jurors'] as List).isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.warning, color: AppColors.warning, size: 48),
              SizedBox(height: 8),
              Text(
                'No hay jurados asignados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Toca el ícono de personas arriba para asignar',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: (_article['jurors'] as List).map<Widget>((juror) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withOpacity(0.1),
              child: const Icon(Icons.gavel, color: AppColors.success),
            ),
            title: Text('${juror['first_name']} ${juror['last_name']}'),
            subtitle: Text(juror['specialty'] ?? 'Sin especialidad'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEvaluationsList() {
    return Column(
      children: (_article['evaluations'] as List).map<Widget>((eval) {
        final promedio = _toDouble(eval['promedio']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withOpacity(0.1),
              child: Text(
                promedio.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ),
            title: Text(
              '${eval['juror']['first_name']} ${eval['juror']['last_name']}',
            ),
            subtitle: Text('Promedio: ${promedio.toStringAsFixed(2)}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCriteriaRow(
                        'Introducción', _toDouble(eval['introduccion'])),
                    _buildCriteriaRow(
                        'Metodología', _toDouble(eval['metodologia'])),
                    _buildCriteriaRow(
                        'Desarrollo', _toDouble(eval['desarrollo'])),
                    _buildCriteriaRow(
                        'Conclusiones', _toDouble(eval['conclusiones'])),
                    _buildCriteriaRow(
                        'Presentación', _toDouble(eval['presentacion'])),
                    if (eval['comentarios'] != null &&
                        eval['comentarios'].toString().isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Comentarios:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(eval['comentarios']),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCriteriaRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
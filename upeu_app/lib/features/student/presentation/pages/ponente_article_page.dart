import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import '../../data/models/my_article_model.dart';

class PonenteArticlePage extends StatefulWidget {
  const PonenteArticlePage({super.key});

  @override
  State<PonenteArticlePage> createState() => _PonenteArticlePageState();
}

class _PonenteArticlePageState extends State<PonenteArticlePage> {
  MyArticleModel? _article;
  bool _isLoading = true;

  final Map<String, String> _articleTypes = {
    'revision_sistematica': 'Revisión Sistemática',
    'empirico': 'Empírico',
    'teorico': 'Teórico',
    'estudio_caso': 'Estudio de Caso',
  };

  final Map<String, String> _criteriaLabels = {
    'introduccion': 'Introducción',
    'metodologia': 'Metodología',
    'desarrollo': 'Desarrollo',
    'conclusiones': 'Conclusiones',
    'presentacion': 'Presentación',
  };

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.get(ApiConstants.studentMyArticle);

      setState(() {
        _article = MyArticleModel.fromJson(response.data['data']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score < 11) return AppColors.error;
    if (score < 14) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Artículo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadArticle,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y tipo
              Text(
                _article!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _articleTypes[_article!.type] ?? _article!.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              if (_article!.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  _article!.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              // Fecha y hora
              if (_article!.presentationDate != null) ...[
                const SizedBox(height: 16),
                //
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(
                      DateFormat('dd/MM/yyyy').format(
                        DateTime.parse(_article!.presentationDate!),
                      ),

                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                        ),
                    ),
                    if (_article!.presentationTime != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                       Flexible(
                         child: Text(
                        _article!.presentationTime!,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                           ),

                      ),
                    ],
                  ],
                ),
              ],
//
              const SizedBox(height: 24),

              // Estadísticas
              _buildStatsGrid(),

              const SizedBox(height: 24),

              // Promedios por criterio
              const Text(
                'Promedios por Criterio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildCriteriaAverages(),

              const SizedBox(height: 24),

              // Jurados asignados
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

              // Evaluaciones
              if (_article!.evaluations.isNotEmpty) ...[
                const Text(
                  'Evaluaciones Recibidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEvaluationsList(),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aún no has recibido evaluaciones',
                          style: TextStyle(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final scoreColor = _getScoreColor(_article!.averageScore);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _StatCard(
          icon: Icons.star,
          label: 'Promedio',
          value: _article!.averageScore.toStringAsFixed(2),
          color: scoreColor,
        ),
        _StatCard(
          icon: Icons.gavel,
          label: 'Evaluaciones',
          value: '${_article!.totalEvaluations}',
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.people,
          label: 'Jurados',
          value: '${_article!.jurors.length}',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.check_circle,
          label: 'Asistencias',
          value: '${_article!.totalAttendances}',
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildCriteriaAverages() {
    return Column(
      children: [
        _buildCriteriaBar(
          'Introducción',
          _article!.criteriaAverages.introduccion,
        ),
        _buildCriteriaBar(
          'Metodología',
          _article!.criteriaAverages.metodologia,
        ),
        _buildCriteriaBar(
          'Desarrollo',
          _article!.criteriaAverages.desarrollo,
        ),
        _buildCriteriaBar(
          'Conclusiones',
          _article!.criteriaAverages.conclusiones,
        ),
        _buildCriteriaBar(
          'Presentación',
          _article!.criteriaAverages.presentacion,
        ),
      ],
    );
  }

  Widget _buildCriteriaBar(String label, double value) {
    final percentage = (value / 20) * 100;
    final color = _getScoreColor(value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurorsList() {
    if (_article!.jurors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_outlined, color: AppColors.warning),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aún no se han asignado jurados',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _article!.jurors.map((juror) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withOpacity(0.1),
              child: const Icon(Icons.gavel, color: AppColors.success),
            ),
            title: Text(juror.fullName),
            subtitle: Text(juror.specialty ?? 'Sin especialidad'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEvaluationsList() {
    return Column(
      children: _article!.evaluations.map((eval) {
        final scoreColor = _getScoreColor(eval.promedio);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: scoreColor.withOpacity(0.2),
              child: Text(
                eval.promedio.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
            title: Text(eval.juror),
            subtitle: Text(eval.jurorSpecialty ?? 'Sin especialidad'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildEvalCriteria('Introducción', eval.introduccion),
                    _buildEvalCriteria('Metodología', eval.metodologia),
                    _buildEvalCriteria('Desarrollo', eval.desarrollo),
                    _buildEvalCriteria('Conclusiones', eval.conclusiones),
                    _buildEvalCriteria('Presentación', eval.presentacion),
                    const Divider(),
                    _buildEvalCriteria('PROMEDIO', eval.promedio, isTotal: true),
                    if (eval.comentarios != null &&
                        eval.comentarios!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comentarios:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(eval.comentarios!),
                          ],
                        ),
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

  Widget _buildEvalCriteria(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isTotal
                  ? _getScoreColor(value).withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? _getScoreColor(value) : AppColors.primary,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                    fontSize: 10,
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
}
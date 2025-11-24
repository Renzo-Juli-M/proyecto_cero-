import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import 'article_detail_juror_page.dart';
import 'article_detail_juror_page.dart';

class MyEvaluationsPage extends StatefulWidget {
  const MyEvaluationsPage({super.key});

  @override
  State<MyEvaluationsPage> createState() => _MyEvaluationsPageState();
}

class _MyEvaluationsPageState extends State<MyEvaluationsPage> {
  List<dynamic> _evaluations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // 🔧 FUNCIÓN HELPER PARA CONVERTIR A DOUBLE DE FORMA SEGURA
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
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final params = <String, dynamic>{};

      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final response = await dioClient.get(
        '/juror/my-evaluations',
        queryParameters: params,
      );

      setState(() {
        _evaluations = response.data['data']['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error al cargar evaluaciones: $e', isError: true);
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

  Color _getScoreColor(double score) {
    if (score >= 16) return AppColors.success;
    if (score >= 11) return AppColors.info;
    if (score >= 6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Evaluaciones'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por título o ponente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadEvaluations();
              },
            ),
          ),

          // Lista de evaluaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _evaluations.isEmpty
                ? const Center(
              child: Text('No has realizado evaluaciones aún'),
            )
                : RefreshIndicator(
              onRefresh: _loadEvaluations,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _evaluations.length,
                itemBuilder: (context, index) {
                  final evaluation = _evaluations[index];
                  return _EvaluationCard(
                    evaluation: evaluation,
                    getScoreColor: _getScoreColor,
                    toDouble: _toDouble, // 🔧 PASAR LA FUNCIÓN
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArticleDetailJurorPage(
                                articleId: evaluation['article']['id'],
                              ),
                        ),
                      ).then((_) => _loadEvaluations());
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final dynamic evaluation;
  final Color Function(double) getScoreColor;
  final double Function(dynamic) toDouble; // 🔧 AGREGAR FUNCIÓN
  final VoidCallback onTap;

  const _EvaluationCard({
    required this.evaluation,
    required this.getScoreColor,
    required this.toDouble, // 🔧 AGREGAR PARÁMETRO
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🔧 USAR toDouble AQUÍ
    final promedio = toDouble(evaluation['promedio']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Promedio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: getScoreColor(promedio).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          color: getScoreColor(promedio),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promedio.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: getScoreColor(promedio),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evaluation['article']['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ponente: ${evaluation['article']['student']['first_name']} ${evaluation['article']['student']['last_name']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evaluado: ${DateTime.parse(evaluation['created_at']).toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Criterios
              _buildCriteriaGrid(evaluation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaGrid(dynamic eval) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: [
        _buildCriteriaChip('Int', eval['introduccion']),
        _buildCriteriaChip('Met', eval['metodologia']),
        _buildCriteriaChip('Des', eval['desarrollo']),
        _buildCriteriaChip('Con', eval['conclusiones']),
        _buildCriteriaChip('Pre', eval['presentacion']),
      ],
    );
  }

  Widget _buildCriteriaChip(String label, dynamic value) {
    // 🔧 USAR toDouble AQUÍ TAMBIÉN
    final score = toDouble(value);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: getScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: getScoreColor(score).withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: getScoreColor(score),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: getScoreColor(score),
            ),
          ),
        ],
      ),
    );
  }
}
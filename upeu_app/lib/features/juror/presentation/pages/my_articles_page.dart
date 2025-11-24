import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import 'article_detail_juror_page.dart';
import 'evaluation_form_page.dart';

class MyArticlesPage extends StatefulWidget {
  const MyArticlesPage({super.key});

  @override
  State<MyArticlesPage> createState() => _MyArticlesPageState();
}

class _MyArticlesPageState extends State<MyArticlesPage> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterType;
  String? _filterStatus;

  final Map<String, String> _articleTypes = {
    'revision_sistematica': 'Revisión Sistemática',
    'empirico': 'Empírico',
    'teorico': 'Teórico',
    'estudio_caso': 'Estudio de Caso',
  };

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
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

      if (_filterStatus != null) {
        params['status'] = _filterStatus;
      }

      final response = await dioClient.get(
        '/juror/my-articles',
        queryParameters: params,
      );

      setState(() {
        _articles = response.data['data']['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error al cargar artículos: $e', isError: true);
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
        title: const Text('Mis Artículos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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
                _loadArticles();
              },
            ),
          ),

          // Filtros activos
          if (_filterType != null || _filterStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterType != null)
                    Chip(
                      label: Text('Tipo: ${_articleTypes[_filterType]}'),
                      onDeleted: () {
                        setState(() => _filterType = null);
                        _loadArticles();
                      },
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  if (_filterStatus != null)
                    Chip(
                      label: Text(
                          'Estado: ${_filterStatus == "pending" ? "Pendiente" : "Evaluado"}'),
                      onDeleted: () {
                        setState(() => _filterStatus = null);
                        _loadArticles();
                      },
                      backgroundColor: AppColors.warning.withOpacity(0.1),
                    ),
                ],
              ),
            ),

          // Lista de artículos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _articles.isEmpty
                ? const Center(
              child: Text('No hay artículos asignados'),
            )
                : RefreshIndicator(
              onRefresh: _loadArticles,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return _ArticleCard(
                    article: article,
                    articleTypes: _articleTypes,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArticleDetailJurorPage(
                                articleId: article['id'],
                              ),
                        ),
                      ).then((_) => _loadArticles());
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar artículos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Por tipo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('Todos'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _filterType,
                  onChanged: (value) {
                    setState(() => _filterType = value);
                    Navigator.pop(context);
                    _loadArticles();
                  },
                ),
              ),
              ..._articleTypes.entries.map((entry) => ListTile(
                title: Text(entry.value),
                leading: Radio<String?>(
                  value: entry.key,
                  groupValue: _filterType,
                  onChanged: (value) {
                    setState(() => _filterType = value);
                    Navigator.pop(context);
                    _loadArticles();
                  },
                ),
              )),
              const Divider(),
              const Text(
                'Por estado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('Todos'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _filterStatus,
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                    Navigator.pop(context);
                    _loadArticles();
                  },
                ),
              ),
              ListTile(
                title: const Text('Pendientes'),
                leading: Radio<String?>(
                  value: 'pending',
                  groupValue: _filterStatus,
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                    Navigator.pop(context);
                    _loadArticles();
                  },
                ),
              ),
              ListTile(
                title: const Text('Evaluados'),
                leading: Radio<String?>(
                  value: 'evaluated',
                  groupValue: _filterStatus,
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                    Navigator.pop(context);
                    _loadArticles();
                  },
                ),
              ),
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
}

class _ArticleCard extends StatelessWidget {
  final dynamic article;
  final Map<String, String> articleTypes;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.articleTypes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEvaluated = article['my_evaluation'] != null;

    Color typeColor;
    switch (article['type']) {
      case 'revision_sistematica':
        typeColor = AppColors.info;
        break;
      case 'empirico':
        typeColor = AppColors.success;
        break;
      case 'teorico':
        typeColor = AppColors.warning;
        break;
      case 'estudio_caso':
        typeColor = AppColors.accent;
        break;
      default:
        typeColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEvaluated ? AppColors.success : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap, // ← Este sigue siendo para ver detalles
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEvaluated ? Icons.check_circle : Icons.article,
                      color: isEvaluated ? AppColors.success : typeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Título y tipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            articleTypes[article['type']] ?? article['type'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estado
                  if (isEvaluated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            article['my_evaluation']['promedio'].toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.pending,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pendiente',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Ponente
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ponente: ${article['student']['first_name']} ${article['student']['last_name']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Fecha y hora
              if (article['presentation_date'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        article['presentation_date'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (article['presentation_time'] != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article['presentation_time'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Botón de acción - ✨ AQUÍ ESTÁ EL CAMBIO PRINCIPAL
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // ✨ NUEVA LÓGICA DE NAVEGACIÓN
                    if (isEvaluated) {
                      // Si ya está evaluado, ir al formulario en modo edición
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EvaluationFormPage(
                            article: article,
                            evaluation: article['my_evaluation'],
                          ),
                        ),
                      ).then((_) {
                        // Recargar la lista después de editar
                        final state = context.findAncestorStateOfType<_MyArticlesPageState>();
                        state?._loadArticles();
                      });
                    } else {
                      // Si no está evaluado, ir al formulario en modo creación
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EvaluationFormPage(
                            article: article,
                          ),
                        ),
                      ).then((_) {
                        // Recargar la lista después de evaluar
                        final state = context.findAncestorStateOfType<_MyArticlesPageState>();
                        state?._loadArticles();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEvaluated
                        ? AppColors.info
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(isEvaluated ? Icons.edit : Icons.rate_review),
                  label: Text(
                    isEvaluated ? 'Editar Evaluación' : 'Evaluar Ahora',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
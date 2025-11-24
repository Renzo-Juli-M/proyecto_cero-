import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import 'qr_scanner_page.dart';

class AvailableArticlesPage extends StatefulWidget {
  const AvailableArticlesPage({super.key});

  @override
  State<AvailableArticlesPage> createState() => _AvailableArticlesPageState();
}

class _AvailableArticlesPageState extends State<AvailableArticlesPage> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, attended, not_attended

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
      final response = await dioClient.get(ApiConstants.studentAvailableArticles);

      setState(() {
        _articles = response.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error al cargar artículos: $e', isError: true);
    }
  }

  List<dynamic> get _filteredArticles {
    switch (_filter) {
      case 'attended':
        return _articles.where((a) => a['has_attended'] == true).toList();
      case 'not_attended':
        return _articles.where((a) => a['has_attended'] == false).toList();
      default:
        return _articles;
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
        title: const Text('Artículos Disponibles'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'not_attended',
                child: Text('No asistidos'),
              ),
              const PopupMenuItem(
                value: 'attended',
                child: Text('Ya asistidos'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Mensaje informativo
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Usa el botón "Escanear QR" para registrar tu asistencia',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtro activo
          if (_filter != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.accent.withOpacity(0.1),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      _filter == 'attended' ? 'Ya asistidos' : 'No asistidos',
                    ),
                    onDeleted: () {
                      setState(() => _filter = 'all');
                    },
                    backgroundColor: AppColors.accent.withOpacity(0.2),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredArticles.length} artículos',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredArticles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filter == 'attended'
                        ? Icons.check_circle_outline
                        : Icons.article_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 'attended'
                        ? 'No has asistido a ningún artículo'
                        : _filter == 'not_attended'
                        ? 'Ya asististe a todos los artículos'
                        : 'No hay artículos disponibles',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadArticles,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredArticles.length,
                itemBuilder: (context, index) {
                  final article = _filteredArticles[index];
                  return _ArticleCard(
                    article: article,
                    articleTypes: _articleTypes,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // ✅ SOLO BOTÓN DE ESCANEAR QR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerPage(),
            ),
          ).then((result) {
            if (result == true) {
              // QR escaneado exitosamente, recargar artículos
              _loadArticles();
            }
          });
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner, size: 28),
        label: const Text(
          'Escanear QR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final dynamic article;
  final Map<String, String> articleTypes;

  const _ArticleCard({
    required this.article,
    required this.articleTypes,
  });

  Color _getTypeColor(String type) {
    switch (type) {
      case 'revision_sistematica':
        return AppColors.info;
      case 'empirico':
        return AppColors.primary;
      case 'teorico':
        return AppColors.warning;
      case 'estudio_caso':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(article['type']);
    final hasAttended = article['has_attended'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasAttended
            ? const BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono de estado
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasAttended
                        ? AppColors.success.withOpacity(0.1)
                        : typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasAttended ? Icons.check_circle : Icons.article,
                    color: hasAttended ? AppColors.success : typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Título
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
                    'Ponente: ${article['ponente']['full_name']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            // Fecha y hora
            if (article['presentation_date'] != null) ...[
              const SizedBox(height: 8),
              //
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(
                    DateFormat('dd/MM/yyyy').format(
                      DateTime.parse(article['presentation_date']),

                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
                  if (article['presentation_time'] != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                       child: Text(
                      article['presentation_time'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                         overflow: TextOverflow.ellipsis,
                       ),
                    ),
                  ],
                  if (article['shift'] != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article['shift'] == 'mañana' ? 'Mañana' : 'Tarde',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
//
            // Estado de asistencia
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasAttended
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasAttended ? Icons.check_circle : Icons.qr_code_scanner,
                    color: hasAttended ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasAttended
                        ? 'Ya asististe a este artículo'
                        : 'Escanea el QR para registrar asistencia',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: hasAttended ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
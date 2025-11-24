import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/local_storage.dart';
import '../../../../injection_container.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isExporting = false;
  String? _exportingType;

  Future<void> _exportReport(String type, String title, String endpoint) async {
    setState(() {
      _isExporting = true;
      _exportingType = type;
    });

    try {
      final localStorage = sl<LocalStorage>();
      final token = localStorage.getToken();

      if (token == null) {
        _showMessage('No hay sesión activa', isError: true);
        return;
      }

      final url = '${ApiConstants.baseUrl}$endpoint';
      final uri = Uri.parse(url);

      // Abrir URL con el token en los headers (el navegador manejará la descarga)
      if (await canLaunchUrl(uri)) {
        // Para web, abrimos en una nueva pestaña con el token
        final downloadUrl = '$url?token=$token';
        await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);

        _showMessage('Descarga iniciada: $title');
      } else {
        _showMessage('No se pudo iniciar la descarga', isError: true);
      }
    } catch (e) {
      _showMessage('Error al exportar: $e', isError: true);
    } finally {
      setState(() {
        _isExporting = false;
        _exportingType = null;
      });
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
        title: const Text('Reportes y Exportación'),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            const Row(
              children: [
                Icon(Icons.download, size: 32, color: AppColors.info),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exportar Datos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Descarga reportes en formato Excel',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Reporte completo
            _buildReportCard(
              title: 'Reporte Completo',
              description: 'Todas las tablas en un solo archivo Excel',
              icon: Icons.folder_special,
              color: AppColors.primary,
              onTap: () => _exportReport(
                'full',
                'Reporte Completo',
                '/admin/export/full-report',
              ),
              isExporting: _isExporting && _exportingType == 'full',
            ),
            const SizedBox(height: 16),

            // Sección: Datos Básicos
            const Text(
              'Datos Básicos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildReportCard(
              title: 'Estudiantes',
              description: 'Lista completa de ponentes y oyentes',
              icon: Icons.school,
              color: AppColors.accent,
              onTap: () => _exportReport(
                'students',
                'Estudiantes',
                '/admin/export/students',
              ),
              isExporting: _isExporting && _exportingType == 'students',
            ),
            const SizedBox(height: 12),

            _buildReportCard(
              title: 'Jurados',
              description: 'Lista de evaluadores con especialidades',
              icon: Icons.gavel,
              color: AppColors.success,
              onTap: () => _exportReport(
                'jurors',
                'Jurados',
                '/admin/export/jurors',
              ),
              isExporting: _isExporting && _exportingType == 'jurors',
            ),
            const SizedBox(height: 12),

            _buildReportCard(
              title: 'Artículos',
              description: 'Lista de artículos con ponentes y estadísticas',
              icon: Icons.article,
              color: AppColors.primary,
              onTap: () => _exportReport(
                'articles',
                'Artículos',
                '/admin/export/articles',
              ),
              isExporting: _isExporting && _exportingType == 'articles',
            ),
            const SizedBox(height: 24),

            // Sección: Resultados
            const Text(
              'Resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildReportCard(
              title: 'Evaluaciones',
              description: 'Calificaciones detalladas por criterio',
              icon: Icons.star,
              color: AppColors.warning,
              onTap: () => _exportReport(
                'evaluations',
                'Evaluaciones',
                '/admin/export/evaluations',
              ),
              isExporting: _isExporting && _exportingType == 'evaluations',
            ),
            const SizedBox(height: 12),

            _buildReportCard(
              title: 'Asistencias',
              description: 'Registro de asistencias de oyentes',
              icon: Icons.check_circle,
              color: AppColors.info,
              onTap: () => _exportReport(
                'attendances',
                'Asistencias',
                '/admin/export/attendances',
              ),
              isExporting: _isExporting && _exportingType == 'attendances',
            ),
            const SizedBox(height: 32),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      SizedBox(width: 8),
                      Text(
                        'Información',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Los archivos se descargan en formato Excel (.xlsx)',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Cada reporte incluye todos los datos actualizados',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• El reporte completo incluye todas las tablas',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Los archivos tienen formato profesional con encabezados',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isExporting,
  }) {
    return InkWell(
      onTap: isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isExporting)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.download,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}
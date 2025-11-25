import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/local_storage.dart';
import '../../../../injection_container.dart';
import 'package:dio/dio.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isExporting = false;
  String? _exportingType;
  double _downloadProgress = 0.0;

  Future<void> _exportReport(String type, String title, String endpoint) async {
    setState(() {
      _isExporting = true;
      _exportingType = type;
      _downloadProgress = 0.0;
    });

    try {
      // 1. Obtener token
      final localStorage = sl<LocalStorage>();
      final token = localStorage.getToken();

      if (token == null) {
        _showMessage('No hay sesión activa', isError: true);
        return;
      }

      // 2. Obtener directorio - NO REQUIERE PERMISOS
      Directory directory;

      if (Platform.isAndroid) {
        // Usar getExternalStorageDirectory() que no requiere permisos
        final tempDir = await getExternalStorageDirectory();
        directory = Directory('${tempDir!.path}/Download');

        // Crear carpeta si no existe
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // 3. Crear nombre de archivo con timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${title.toLowerCase().replaceAll(' ', '_')}_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      print('📥 Descargando a: $filePath');

      // 4. Descargar archivo con Dio
      final dioClient = sl<DioClient>();
      await dioClient.dio.download(
        '${ApiConstants.baseUrl}$endpoint',
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
            print('📊 Progreso: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      setState(() {
        _isExporting = false;
        _exportingType = null;
      });

      // 5. Mostrar diálogo de éxito
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Descarga completa')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archivo guardado exitosamente:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 20, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ubicación: ${directory.path}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Abrir archivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );

        // 6. Abrir archivo si el usuario acepta
        if (result == true) {
          try {
            final openResult = await OpenFilex.open(filePath);
            if (openResult.type != ResultType.done) {
              _showMessage('Archivo descargado en: ${directory.path}');
            }
          } catch (e) {
            _showMessage('Archivo guardado en: ${directory.path}');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportingType = null;
      });
      print('❌ Error: $e');
      _showMessage('Error al exportar: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
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

            // Barra de progreso
            if (_isExporting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Descargando... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

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
                    '• Se guardan en el almacenamiento de la app',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Puedes abrirlos directamente desde la notificación',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Cada archivo tiene formato profesional con encabezados',
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
      onTap: _isExporting ? null : onTap,
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
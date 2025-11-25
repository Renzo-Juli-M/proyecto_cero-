import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import '../../data/models/dashboard_stats_model.dart';
import 'import_page.dart';
import 'students_list_page.dart';
import 'jurors_list_page.dart';
import 'articles_list_page.dart';
import 'reports_page.dart';
import 'winners_page.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  DashboardStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.get(ApiConstants.adminDashboard);

      setState(() {
        _stats = DashboardStatsModel.fromJson(response.data['data']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido, Administrador',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Estadísticas
              if (_stats != null) _buildStatsGrid(_stats!),

              const SizedBox(height: 32),

              // Acciones rápidas
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStatsModel stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3, // Más espacio vertical
      children: [
        _StatCard(
          icon: Icons.school,
          title: 'Estudiantes',
          value: '${stats.totalStudents}',
          subtitle: 'Ponente: ${stats.totalPonentes} | Oyentes: ${stats.totalOyentes}',
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.gavel,
          title: 'Jurados',
          value: '${stats.totalJurors}',
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.article,
          title: 'Artículos',
          value: '${stats.totalArticles}',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.check_circle,
          title: 'Asistencias',
          value: '${stats.totalAttendances}',
          color: AppColors.warning,
        ),
        _StatCard(
          icon: Icons.star,
          title: 'Evaluaciones',
          value: '${stats.totalEvaluations}',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: Icons.upload_file,
          title: 'Importar Datos',
          subtitle: 'Cargar desde Excel',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ImportPage()),
            ).then((_) => _loadStats());
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.people,
          title: 'Gestionar Estudiantes',
          subtitle: 'Ver, crear, editar y eliminar',
          color: AppColors.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentsListPage()),
            ).then((_) => _loadStats());
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.gavel,
          title: 'Gestionar Jurados',
          subtitle: 'Ver, crear, editar y eliminar',
          color: AppColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JurorsListPage()),
            ).then((_) => _loadStats());
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.article,
          title: 'Gestionar Artículos',
          subtitle: 'Ver, crear y asignar jurados',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ArticlesListPage()),
            ).then((_) => _loadStats());
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.emoji_events,
          title: 'Ganadores',
          subtitle: 'Ver ganadores por categoría',
          color: const Color(0xFFFFD700), // Color dorado
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WinnersPage(),
              ),
            );
          },
        ),
        _ActionButton(
          icon: Icons.assessment,
          title: 'Reportes y Exportación',
          subtitle: 'Descargar datos en Excel',
          color: AppColors.info,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsPage()),
            );
          },
        ),
      ],
    );
  }
}

// ✅ StatCard optimizado sin overflow
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ ActionButton limpio
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
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
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
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
      ),
    );
  }
}
  import 'package:flutter/material.dart';
  import '../../../../core/constants/app_colors.dart';
  import '../../../../core/network/dio_client.dart';
  import '../../../../injection_container.dart';
  import 'juror_form_page.dart';

  class JurorsListPage extends StatefulWidget {
    const JurorsListPage({super.key});

    @override
    State<JurorsListPage> createState() => _JurorsListPageState();
  }

  class _JurorsListPageState extends State<JurorsListPage> {
    List<dynamic> _jurors = [];
    bool _isLoading = true;
    String _searchQuery = '';

    @override
    void initState() {
      super.initState();
      _loadJurors();
    }
    //
    Future<void> _loadJurors() async {
      setState(() => _isLoading = true);

      try {
        final dioClient = sl<DioClient>();
        final params = <String, dynamic>{
          'per_page': 100,
        };

        if (_searchQuery.isNotEmpty) {
          params['search'] = _searchQuery;
        }

        print('📡 Haciendo_petición a: /admin/jurors');
        print('📊 Con parámetros: $params');

        final response = await dioClient.get(
          '/admin/jurors',
          queryParameters: params,
        );

        print('✅ Respuesta_-recibida: ${response.statusCode}');
        print('📦 Data : ${response.data}');

        // ✅ VALIDACIÓN SEGURA DE LA ESTRUCTURA
        if (response.data != null &&
            response.data['data'] != null &&
            response.data['data']['data'] != null) {

          final jurorsList = response.data['data']['data'] as List;
          print('👥 Total de jurados: ${jurorsList.length}');

          setState(() {
            _jurors = jurorsList;
            _isLoading = false;
          });

          print('✨ Estado actualizado_exitosamente con ${_jurors.length} jurados');
        } else {
          print('⚠️ Estructura de respuesta inesperada');
          print('⚠️ response.data: ${response.data}');

          setState(() {
            _jurors = [];
            _isLoading = false;
          });

          _showMessage('Respuesta del servidor con formato inesperado', isError: true);
        }
      } catch (e, stackTrace) {
        print('❌ ERROR COMPLETO: $e');
        print('📍 Stack trace: $stackTrace');

        setState(() {
          _jurors = [];
          _isLoading = false;
        });

        _showMessage('Error al cargar jurados: $e', isError: true);
      }
    }

    //
    Future<void> _deleteJuror(int id, String name) async {
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
        await dioClient.delete('/admin/jurors/$id');
        _showMessage('Jurado eliminado exitosamente');
        _loadJurors();
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
          title: const Text('Jurados'),
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
                  hintText: 'Buscar por DNI, usuario o nombre...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadJurors();
                },
              ),
            ),

            // Lista
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _jurors.isEmpty
                  ? const Center(
                child: Text('No hay jurados registrados'),
              )
                  : RefreshIndicator(
                onRefresh: _loadJurors,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jurors.length,
                  itemBuilder: (context, index) {
                    final juror = _jurors[index];
                    return _JurorCard(
                      juror: juror,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JurorFormPage(
                              juror: juror,
                            ),
                          ),
                        ).then((_) => _loadJurors());
                      },
                      onDelete: () => _deleteJuror(
                        juror['id'],
                        '${juror['first_name']} ${juror['last_name']}',
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const JurorFormPage(),
              ),
            ).then((_) => _loadJurors());
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  class _JurorCard extends StatelessWidget {
    final dynamic juror;
    final VoidCallback onEdit;
    final VoidCallback onDelete;

    const _JurorCard({
      required this.juror,
      required this.onEdit,
      required this.onDelete,
    });

    @override
    Widget build(BuildContext context) {
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
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  child: const Icon(
                    Icons.gavel,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${juror['first_name']} ${juror['last_name']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usuario: ${juror['username']} • DNI: ${juror['dni']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (juror['specialty'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.school,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                juror['specialty'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Acciones
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
                          Text('Eliminar', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class EvaluationFormPage extends StatefulWidget {
  final dynamic article;
  final dynamic evaluation;

  const EvaluationFormPage({
    super.key,
    required this.article,
    this.evaluation,
  });

  @override
  State<EvaluationFormPage> createState() => _EvaluationFormPageState();
}

class _EvaluationFormPageState extends State<EvaluationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _comentariosController = TextEditingController();

  double _introduccion = 10;
  double _metodologia = 10;
  double _desarrollo = 10;
  double _conclusiones = 10;
  double _presentacion = 10;

  bool _isLoading = false;
  bool get isEditing => widget.evaluation != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _introduccion = widget.evaluation['introduccion'].toDouble();
      _metodologia = widget.evaluation['metodologia'].toDouble();
      _desarrollo = widget.evaluation['desarrollo'].toDouble();
      _conclusiones = widget.evaluation['conclusiones'].toDouble();
      _presentacion = widget.evaluation['presentacion'].toDouble();
      _comentariosController.text = widget.evaluation['comentarios'] ?? '';
    }
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  double get promedio {
    return (_introduccion + _metodologia + _desarrollo + _conclusiones + _presentacion) / 5;
  }

  Color _getScoreColor(double score) {
    if (score >= 16) return AppColors.success;
    if (score >= 11) return AppColors.info;
    if (score >= 6) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _saveEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Confirmar Actualización' : 'Confirmar Evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing
                  ? '¿Estás seguro de actualizar esta evaluación?'
                  : '¿Estás seguro de enviar esta evaluación?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getScoreColor(promedio).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Promedio Final: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      promedio.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(promedio),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(isEditing ? 'Actualizar' : 'Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final data = {
        'article_id': widget.article['id'],
        'introduccion': _introduccion,
        'metodologia': _metodologia,
        'desarrollo': _desarrollo,
        'conclusiones': _conclusiones,
        'presentacion': _presentacion,
        'comentarios': _comentariosController.text.trim().isEmpty
            ? null
            : _comentariosController.text.trim(),
      };

      if (isEditing) {
        await dioClient.put(
          '/juror/evaluations/${widget.evaluation['id']}',
          data: data,
        );
      } else {
        await dioClient.post('/juror/evaluations', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Evaluación actualizada exitosamente'
                : 'Evaluación registrada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteEvaluation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de eliminar esta evaluación? Esta acción no se puede deshacer.',
        ),
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

    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      await dioClient.delete('/juror/evaluations/${widget.evaluation['id']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación eliminada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Evaluación' : 'Nueva Evaluación'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteEvaluation,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del artículo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Artículo a Evaluar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.article['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ponente: ${widget.article['student']['first_name']} ${widget.article['student']['last_name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Promedio en tiempo real
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor(promedio).withOpacity(0.2),
                      _getScoreColor(promedio).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getScoreColor(promedio),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Promedio: ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      promedio.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(promedio),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Criterios de evaluación
              const Text(
                'Criterios de Evaluación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Califica cada criterio del 0 al 20',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              _buildCriteriaSlider(
                'Introducción',
                'Claridad y relevancia de la introducción',
                Icons.article,
                _introduccion,
                    (value) => setState(() => _introduccion = value),
              ),
              const SizedBox(height: 24),

              _buildCriteriaSlider(
                'Metodología',
                'Solidez y adecuación de la metodología',
                Icons.science,
                _metodologia,
                    (value) => setState(() => _metodologia = value),
              ),
              const SizedBox(height: 24),

              _buildCriteriaSlider(
                'Desarrollo',
                'Coherencia y profundidad del desarrollo',
                Icons.format_list_bulleted,
                _desarrollo,
                    (value) => setState(() => _desarrollo = value),
              ),
              const SizedBox(height: 24),

              _buildCriteriaSlider(
                'Conclusiones',
                'Pertinencia y claridad de las conclusiones',
                Icons.check_circle,
                _conclusiones,
                    (value) => setState(() => _conclusiones = value),
              ),
              const SizedBox(height: 24),

              _buildCriteriaSlider(
                'Presentación',
                'Calidad de la presentación y exposición',
                Icons.present_to_all,
                _presentacion,
                    (value) => setState(() => _presentacion = value),
              ),
              const SizedBox(height: 32),

              // Comentarios
              const Text(
                'Comentarios (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _comentariosController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Escribe tus observaciones y comentarios...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 32),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEvaluation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEditing ? 'Actualizar Evaluación' : 'Enviar Evaluación',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaSlider(
      String title,
      String subtitle,
      IconData icon,
      double value,
      ValueChanged<double> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getScoreColor(value).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _getScoreColor(value),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(value),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getScoreColor(value),
              inactiveTrackColor: _getScoreColor(value).withOpacity(0.2),
              thumbColor: _getScoreColor(value),
              overlayColor: _getScoreColor(value).withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
              ),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 20,
              divisions: 40,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '10',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '20',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
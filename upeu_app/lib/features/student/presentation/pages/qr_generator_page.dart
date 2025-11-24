import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({super.key});

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  String? _qrCode;
  String? _articleTitle;
  DateTime? _expiresAt;
  bool _isLoading = false;
  bool _isGenerating = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingQR();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingQR() async {
    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.get(ApiConstants.studentQRStatus);

      print('🔍 Check QR Status Response: ${response.data}');

      final data = response.data['data'];
      final hasActiveQR = data['has_active_qr'] ?? false;

      print('✅ Has Active QR: $hasActiveQR');

      if (hasActiveQR) {
        final qrToken = data['qr_token'] as String;
        final articleTitle = data['article_title'] as String;
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        final remainingMinutes = (data['remaining_minutes'] as num).toDouble();

        setState(() {
          _qrCode = qrToken;
          _articleTitle = articleTitle;
          _expiresAt = expiresAt;
          _remainingSeconds = (remainingMinutes * 60).toInt();
        });

        print('📱 QR activo cargado: ${_qrCode?.substring(0, 20)}...');
        _startCountdown();
      }

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ Error en checkExistingQR: $e');
      print('Stack: $stackTrace');
      setState(() => _isLoading = false);
      _showMessage('Error al verificar QR: $e', isError: true);
    }
  }

  Future<void> _generateQR() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar QR de Asistencia'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El QR generado será válido por 30 minutos.'),
            SizedBox(height: 12),
            Text(
              'Los oyentes podrán escanear este QR para registrar su asistencia a tu presentación.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solo puedes generar un QR activo a la vez',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
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
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isGenerating = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.post(ApiConstants.studentGenerateQR);

      print('🔍 Generate QR Response completo: ${response.data}');

      final data = response.data['data'];

      print('📦 Data extraído: $data');
      print('🎫 QR Token: ${data['qr_token']}');
      print('📝 Article Title: ${data['article_title']}');
      print('⏰ Expires At: ${data['expires_at']}');
      print('⏱️ Remaining Minutes: ${data['remaining_minutes']}');

      final qrToken = data['qr_token'] as String;
      final articleTitle = data['article_title'] as String;
      final expiresAt = DateTime.parse(data['expires_at'] as String);
      final remainingMinutes = (data['remaining_minutes'] as num).toDouble();
      final remainingSeconds = (remainingMinutes * 60).toInt();

      print('🔧 Valores calculados:');
      print('   QR Token length: ${qrToken.length}');
      print('   Remaining seconds: $remainingSeconds');

      setState(() {
        _qrCode = qrToken;
        _articleTitle = articleTitle;
        _expiresAt = expiresAt;
        _remainingSeconds = remainingSeconds;
        _isGenerating = false;
      });

      print('✅ Estado actualizado:');
      print('   _qrCode: ${_qrCode?.substring(0, 20)}...');
      print('   _articleTitle: $_articleTitle');
      print('   _remainingSeconds: $_remainingSeconds');
      print('   _qrCode es null?: ${_qrCode == null}');

      _startCountdown();
      _showMessage('✅ QR generado exitosamente');

      // Forzar rebuild
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });

    } catch (e, stackTrace) {
      print('❌ ERROR al generar QR: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() => _isGenerating = false);
      _showMessage('Error al generar QR: $e', isError: true);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() {
          _qrCode = null;
          _expiresAt = null;
        });
        _showMessage('El QR ha expirado', isError: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimeColor(int seconds) {
    if (seconds > 600) return AppColors.success; // > 10 min
    if (seconds > 300) return AppColors.warning; // > 5 min
    return AppColors.error; // < 5 min
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 Build llamado - _qrCode: ${_qrCode == null ? "NULL" : "PRESENTE (${_qrCode!.length} chars)"}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar QR de Asistencia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_qrCode == null) ...[
              // DEBUG
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text('🔴 DEBUG: Mostrando NO QR SECTION'),
              ),
              SizedBox(height: 16),
              _buildNoQRSection(),
            ] else ...[
              // DEBUG
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.green.shade100,
                child: Text('🟢 DEBUG: Mostrando QR SECTION\nQR Length: ${_qrCode!.length}'),
              ),
              SizedBox(height: 16),
              _buildQRSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoQRSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.qr_code_2,
            size: 120,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Genera tu QR de Asistencia',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Genera un código QR para que los oyentes puedan registrar su asistencia a tu presentación.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.info, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El QR será válido por 30 minutos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lock_clock, color: AppColors.info, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Solo puedes tener un QR activo a la vez',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateQR,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isGenerating
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.qr_code_scanner),
            label: Text(
              _isGenerating ? 'Generando...' : 'Generar QR',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRSection() {
    final timeColor = _getTimeColor(_remainingSeconds);

    return Column(
      children: [
        // Countdown timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: timeColor.withOpacity(0.3), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: timeColor, size: 28),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text(
                    'Tiempo restante',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: timeColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // QR Code
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: _qrCode!,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
              const SizedBox(height: 16),
              const Text(
                'QR de Asistencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_articleTitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  _articleTitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Instrucciones
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success),
                  SizedBox(width: 12),
                  Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '1. Muestra este QR a los oyentes\n'
                    '2. Ellos deben escanearlo con su app\n'
                    '3. Su asistencia se registrará automáticamente\n'
                    '4. El QR expirará en 30 minutos',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botón de refrescar
        TextButton.icon(
          onPressed: _checkExistingQR,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar estado'),
        ),
      ],
    );
  }
}
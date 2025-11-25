import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';

class DownloadService {
  final Dio dio;

  DownloadService(this.dio);

  /// Descargar archivo Excel
  Future<String?> downloadFile({
    required String url,
    required String fileName,
    required String token,
    Function(int, int)? onProgress,
  }) async {
    try {
      // 1. Pedir permisos
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Permiso de almacenamiento denegado');
          }
        }
      }

      // 2. Obtener directorio de descargas
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory!.path}/$fileName';

      // 3. Descargar archivo
      await dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: onProgress,
      );

      return filePath;
    } catch (e) {
      print('Error descargando: $e');
      rethrow;
    }
  }

  /// Abrir archivo descargado
  Future<void> openFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      print('Error abriendo archivo: $e');
      rethrow;
    }
  }
}
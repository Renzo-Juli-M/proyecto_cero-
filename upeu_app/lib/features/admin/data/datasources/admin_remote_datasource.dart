import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/dashboard_stats_model.dart';
import '../models/period_model.dart';
import '../models/event_model.dart';

abstract class AdminRemoteDataSource {
  // Dashboard
  Future<DashboardStatsModel> getDashboardStats();

  // Importación
  Future<Response> importStudents(String filePath, {int? periodId, int? eventId});
  Future<Response> importJurors(String filePath);
  Future<Response> importArticles(String filePath);

  // Exportación
  Future<String> exportStudents();
  Future<String> exportJurors();
  Future<String> exportArticles();
  Future<String> exportFullReport();

  // Periodos
  Future<List<PeriodModel>> getPeriods({bool? isActive});
  Future<PeriodModel> getPeriod(int id);
  Future<PeriodModel> createPeriod(Map<String, dynamic> data);
  Future<PeriodModel> updatePeriod(int id, Map<String, dynamic> data);
  Future<void> deletePeriod(int id);
  Future<PeriodModel?> getActivePeriod();
  Future<PeriodModel> activatePeriod(int id);

  // Eventos
  Future<List<EventModel>> getEvents({int? periodId, bool? isActive});
  Future<EventModel> getEvent(int id);
  Future<EventModel> createEvent(Map<String, dynamic> data);
  Future<EventModel> updateEvent(int id, Map<String, dynamic> data);
  Future<void> deleteEvent(int id);
  Future<List<EventModel>> getEventsByPeriod(int periodId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final DioClient dioClient;

  AdminRemoteDataSourceImpl(this.dioClient);

  // ======================================================
  //                     DASHBOARD
  // ======================================================

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await dioClient.get(ApiConstants.adminDashboard);
      return DashboardStatsModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // ======================================================
  //                     IMPORTACIÓN
  // ======================================================

  @override
  Future<Response> importStudents(
      String filePath, {
        int? periodId,
        int? eventId,
      }) async {
    try {
      final dataMap = <String, dynamic>{
        'file': await MultipartFile.fromFile(filePath),
      };

      if (periodId != null) dataMap['period_id'] = periodId;
      if (eventId != null) dataMap['event_id'] = eventId;

      final formData = FormData.fromMap(dataMap);

      return await dioClient.post(
        ApiConstants.importStudents,
        data: formData,
      );
    } catch (e) {
      throw Exception('Error al importar estudiantes: $e');
    }
  }

  @override
  Future<Response> importJurors(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      return await dioClient.post(
        ApiConstants.importJurors,
        data: formData,
      );
    } catch (e) {
      throw Exception('Error al importar jurados: $e');
    }
  }

  @override
  Future<Response> importArticles(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      return await dioClient.post(
        ApiConstants.importArticles,
        data: formData,
      );
    } catch (e) {
      throw Exception('Error al importar artículos: $e');
    }
  }

  // ======================================================
  //                     EXPORTACIÓN
  // ======================================================

  @override
  Future<String> exportStudents() async {
    return '${ApiConstants.baseUrl}/admin/export/students';
  }

  @override
  Future<String> exportJurors() async {
    return '${ApiConstants.baseUrl}/admin/export/jurors';
  }

  @override
  Future<String> exportArticles() async {
    return '${ApiConstants.baseUrl}/admin/export/articles';
  }

  @override
  Future<String> exportFullReport() async {
    return '${ApiConstants.baseUrl}/admin/export/full-report';
  }

  // ======================================================
  //                     PERIODOS
  // ======================================================

  @override
  Future<List<PeriodModel>> getPeriods({bool? isActive}) async {
    try {
      final params = <String, dynamic>{};
      if (isActive != null) params['is_active'] = isActive ? 1 : 0;

      final response = await dioClient.get(
        ApiConstants.periods,
        queryParameters: params,
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => PeriodModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener periodos: $e');
    }
  }

  @override
  Future<PeriodModel> getPeriod(int id) async {
    try {
      final response = await dioClient.get('${ApiConstants.periods}/$id');
      return PeriodModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al obtener periodo: $e');
    }
  }

  @override
  Future<PeriodModel> createPeriod(Map<String, dynamic> data) async {
    try {
      final response = await dioClient.post(
        ApiConstants.periods,
        data: data,
      );
      return PeriodModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al crear periodo: $e');
    }
  }

  @override
  Future<PeriodModel> updatePeriod(int id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.put(
        '${ApiConstants.periods}/$id',
        data: data,
      );
      return PeriodModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al actualizar periodo: $e');
    }
  }

  @override
  Future<void> deletePeriod(int id) async {
    try {
      await dioClient.delete('${ApiConstants.periods}/$id');
    } catch (e) {
      throw Exception('Error al eliminar periodo: $e');
    }
  }

  @override
  Future<PeriodModel?> getActivePeriod() async {
    try {
      final response = await dioClient.get('${ApiConstants.periods}/active');
      return PeriodModel.fromJson(response.data['data']);
    } catch (_) {
      return null; // Si no hay periodo activo, retorna null
    }
  }

  @override
  Future<PeriodModel> activatePeriod(int id) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.periods}/$id/activate',
      );
      return PeriodModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al activar periodo: $e');
    }
  }

  // ======================================================
  //                     EVENTOS
  // ======================================================

  @override
  Future<List<EventModel>> getEvents({int? periodId, bool? isActive}) async {
    try {
      final params = <String, dynamic>{};
      if (periodId != null) params['period_id'] = periodId;
      if (isActive != null) params['is_active'] = isActive ? 1 : 0;

      final response = await dioClient.get(
        ApiConstants.events,
        queryParameters: params,
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos: $e');
    }
  }

  @override
  Future<EventModel> getEvent(int id) async {
    try {
      final response = await dioClient.get('${ApiConstants.events}/$id');
      return EventModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al obtener evento: $e');
    }
  }

  @override
  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await dioClient.post(
        ApiConstants.events,
        data: data,
      );
      return EventModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al crear evento: $e');
    }
  }

  @override
  Future<EventModel> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.put(
        '${ApiConstants.events}/$id',
        data: data,
      );
      return EventModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Error al actualizar evento: $e');
    }
  }

  @override
  Future<void> deleteEvent(int id) async {
    try {
      await dioClient.delete('${ApiConstants.events}/$id');
    } catch (e) {
      throw Exception('Error al eliminar evento: $e');
    }
  }

  @override
  Future<List<EventModel>> getEventsByPeriod(int periodId) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.events}/period/$periodId',
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos del periodo: $e');
    }
  }
}

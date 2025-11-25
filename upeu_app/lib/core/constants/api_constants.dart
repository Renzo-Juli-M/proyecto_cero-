class ApiConstants {
  // Cambia esta URL según tu configuración
  //static const String baseUrl = 'http://10.0.2.2:8000/api';
  // Si usas dispositivo físico: http://TU_IP_LOCAL:8000
  static const String baseUrl = 'http://172.20.10.5:8000/api';




  // static const String jghfbaseUrl = '_http://localhost:8000/api';

  // ✅ NUEVAS CONSTANTES PARA GANADORES
  static const String adminWinners = '/admin/winners';
  static const String adminAbsoluteWinner = '/admin/absolute-winner';

  // ========== AUTENTICACIÓN ==========
  static const String loginAdmin = '/login/admin';
  static const String loginStudent = '/login/student';
  static const String loginJuror = '/login/juror';
  static const String logout = '/logout';
  static const String me = '/me';

  // ========== ADMIN ==========
  // Dashboard
  static const String adminDashboard = '/admin/dashboard';
  static const String adminDetailedStatistics = '/admin/statistics/detailed';
  static const String adminArticlesByType = '/admin/statistics/articles-by-type';
  static const String adminArticlesRanking = '/admin/statistics/articles-ranking';

  // Importación
  static const String importStudents = '/admin/import/students';
  static const String importJurors = '/admin/import/jurors';
  static const String importArticles = '/admin/import/articles';

  // Exportación
  static const String exportStudents = '/admin/export/students';
  static const String exportJurors = '/admin/export/jurors';
  static const String exportArticles = '/admin/export/articles';
  static const String exportEvaluations = '/admin/export/evaluations';
  static const String exportAttendances = '/admin/export/attendances';
  static const String exportFullReport = '/admin/export/full-report';

  // Periods
  static const String periods = '/admin/periods';
  static const String activePeriod = '/admin/periods/active';

  // Events
  static const String events = '/admin/events';

  // CRUD Estudiantes
  static const String students = '/admin/students';
  static String studentDetail(int id) => '/admin/students/$id';
  static String studentUpdate(int id) => '/admin/students/$id';
  static String studentDelete(int id) => '/admin/students/$id';

  // CRUD Jurados
  static const String jurors = '/admin/jurors';
  static String jurorDetail(int id) => '/admin/jurors/$id';
  static String jurorUpdate(int id) => '/admin/jurors/$id';
  static String jurorDelete(int id) => '/admin/jurors/$id';

  // CRUD Artículos
  static const String articles = '/admin/articles';
  static String articleDetail(int id) => '/admin/articles/$id';
  static String articleUpdate(int id) => '/admin/articles/$id';
  static String articleDelete(int id) => '/admin/articles/$id';
  static String assignJurors(int articleId) => '/admin/articles/$articleId/assign-jurors';
  static String articleStatistics(int articleId) => '/admin/articles/$articleId/statistics';

  // ✅ CORRECCIÓN CRÍTICA: Cambiar de '/admin/jurors/available' a '/admin/jurors'
  // Porque tu backend no tiene la ruta /available, usa la misma ruta con parámetros
  static const String availableJurors = '/admin/jurors';  // ← CAMBIO AQUÍ

  // ========== JURADO ==========
  // Dashboard
  static const String jurorDashboard = '/juror/dashboard';

  // Artículos
  static const String jurorMyArticles = '/juror/my-articles';
  static String jurorArticleDetail(int articleId) => '/juror/articles/$articleId';

  // Evaluaciones
  static const String jurorEvaluations = '/juror/evaluations';
  static const String jurorMyEvaluations = '/juror/my-evaluations';
  static String jurorUpdateEvaluation(int evaluationId) => '/juror/evaluations/$evaluationId';
  static String jurorDeleteEvaluation(int evaluationId) => '/juror/evaluations/$evaluationId';

  // ========== ESTUDIANTE ==========
  // Dashboard
  static const String studentDashboard = '/student/dashboard';

  // Artículos (Ponente)
  static const String studentMyArticle = '/student/my-article';

  // Artículos Disponibles (Oyente)
  static const String studentAvailableArticles = '/student/available-articles';
  static String studentRegisterAttendance(int articleId) => '/student/articles/$articleId/attend';

  // Asistencias (Oyente)
  static const String studentMyAttendances = '/student/my-attendances';

  // Estadísticas (Oyente)
  static const String studentOyenteStatistics = '/student/statistics';

  // ========== QR - NUEVAS CONSTANTES ==========
  // Ponentes - Generar QR
  static const String studentGenerateQR = '/student/generate-qr';
  static const String studentQRStatus = '/student/qr-status';
  static const String studentMyAttendees = '/student/my-attendees';

  // Oyentes - Escanear QR
  static const String studentScanQR = '/student/scan-qr';
}
<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\StudentController;
use App\Http\Controllers\Api\JurorController;
use App\Http\Controllers\Api\ArticleController;
use App\Http\Controllers\Api\JurorDashboardController;

// Nuevos controladores
use App\Http\Controllers\Api\PeriodController;
use App\Http\Controllers\Api\EventController;

// ===================================
//        RUTAS PÚBLICAS
// ===================================
Route::prefix('login')->group(function () {
    Route::post('/admin', [AuthController::class, 'loginAdmin']);
    Route::post('/student', [AuthController::class, 'loginStudent']);
    Route::post('/juror', [AuthController::class, 'loginJuror']);
});


// ===================================
//        RUTAS PROTEGIDAS
// ===================================
Route::middleware('auth:sanctum')->group(function () {

    // ---------- AUTH ----------
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);


    // =====================================================================
    //                           ADMINISTRADOR
    // =====================================================================
    Route::prefix('admin')->group(function () {

        // ---------- DASHBOARD + ESTADÍSTICAS ----------
        Route::get('/dashboard', [AdminController::class, 'dashboard']);
        Route::get('/statistics/detailed', [AdminController::class, 'detailedStatistics']);
        Route::get('/statistics/articles-by-type', [AdminController::class, 'articlesByType']);
        Route::get('/statistics/articles-ranking', [AdminController::class, 'articlesRanking']);

        // ---------- IMPORTACIONES ----------
        Route::post('/import/students', [AdminController::class, 'importStudents']);
        Route::post('/import/jurors', [AdminController::class, 'importJurors']);
        Route::post('/import/articles', [AdminController::class, 'importArticles']);

        // ---------- EXPORTACIONES ----------
        Route::get('/export/students', [AdminController::class, 'exportStudents']);
        Route::get('/export/jurors', [AdminController::class, 'exportJurors']);
        Route::get('/export/articles', [AdminController::class, 'exportArticles']);
        Route::get('/export/evaluations', [AdminController::class, 'exportEvaluations']);
        Route::get('/export/attendances', [AdminController::class, 'exportAttendances']);
        Route::get('/export/full-report', [AdminController::class, 'exportFullReport']);

        // ---------- JURADOS DISPONIBLES ----------
        Route::get('/jurors/available', [ArticleController::class, 'availableJurors']);

        // =====================================================================
        //                         NUEVO: PERIODOS
        // =====================================================================
        Route::prefix('periods')->group(function () {
            Route::get('/', [PeriodController::class, 'index']);          // listar periodos
            Route::post('/', [PeriodController::class, 'store']);         // crear periodo
            Route::get('/active', [PeriodController::class, 'getActive']); // periodo activo
            Route::get('/{id}', [PeriodController::class, 'show']);       // mostrar
            Route::put('/{id}', [PeriodController::class, 'update']);     // actualizar
            Route::delete('/{id}', [PeriodController::class, 'destroy']); // eliminar
            Route::post('/{id}/activate', [PeriodController::class, 'activate']); // activar periodo
        });

        // =====================================================================
        //                          NUEVO: EVENTOS
        // =====================================================================
        Route::prefix('events')->group(function () {
            Route::get('/', [EventController::class, 'index']);           // listar eventos
            Route::post('/', [EventController::class, 'store']);          // crear evento
            Route::get('/period/{periodId}', [EventController::class, 'getByPeriod']); // eventos por periodo
            Route::get('/{id}', [EventController::class, 'show']);        // mostrar evento
            Route::put('/{id}', [EventController::class, 'update']);      // actualizar evento
            Route::delete('/{id}', [EventController::class, 'destroy']);  // eliminar evento
        });


        // =====================================================================
        //                           CRUD EXISTENTES
        // =====================================================================

        // CRUD Estudiantes
        Route::apiResource('students', StudentController::class);

        // CRUD Jurados
        Route::apiResource('jurors', JurorController::class);

        // CRUD Artículos
        Route::apiResource('articles', ArticleController::class);

        // Asignación de jurados
        Route::post('/articles/{id}/assign-jurors', [ArticleController::class, 'assignJurors']);

        // Estadísticas de artículos
        Route::get('/articles/{id}/statistics', [ArticleController::class, 'statistics']);
    });




    // =====================================================================
    //                             JURADO
    // =====================================================================
    Route::prefix('juror')->group(function () {
        Route::get('/dashboard', [JurorDashboardController::class, 'dashboard']);

        Route::get('/my-articles', [JurorDashboardController::class, 'myArticles']);
        Route::get('/articles/{id}', [JurorDashboardController::class, 'articleDetail']);

        Route::post('/evaluations', [JurorDashboardController::class, 'storeEvaluation']);
        Route::put('/evaluations/{id}', [JurorDashboardController::class, 'updateEvaluation']);
        Route::get('/my-evaluations', [JurorDashboardController::class, 'myEvaluations']);
        Route::delete('/evaluations/{id}', [JurorDashboardController::class, 'deleteEvaluation']);
    });



    // =====================================================================
    //                             ESTUDIANTE
    // =====================================================================
    Route::prefix('student')->group(function () {

        Route::get('/dashboard', [StudentController::class, 'dashboard']);

        Route::get('/my-article', [StudentController::class, 'myArticle']);
        Route::get('/available-articles', [StudentController::class, 'availableArticles']);

        Route::post('/articles/{id}/attend', [StudentController::class, 'registerAttendance']);
        Route::get('/my-attendances', [StudentController::class, 'myAttendances']);

        Route::get('/statistics', [StudentController::class, 'oyenteStatistics']);

        // -------- QR --------
        Route::post('/generate-qr', [StudentController::class, 'generateQR']);
        Route::get('/qr-status', [StudentController::class, 'checkQRStatus']);
        Route::get('/my-attendees', [StudentController::class, 'myAttendees']);

        Route::post('/scan-qr', [StudentController::class, 'scanQR']);
    });

});

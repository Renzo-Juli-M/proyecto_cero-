<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Imports\StudentsImport;
use App\Imports\JurorsImport;
use App\Imports\ArticlesImport;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\StudentsExport;
use App\Exports\JurorsExport;
use App\Exports\ArticlesExport;
use App\Exports\EvaluationsExport;
use App\Exports\AttendancesExport;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AdminController extends Controller
{
    /**
     * ============================
     *  IMPORTAR ESTUDIANTES (NUEVO)
     * ============================
     * Este método reemplaza al método original importStudents()
     */
    public function importStudents(Request $request)
    {
        try {
            // Validar request
            $validator = Validator::make($request->all(), [
                'file' => [
                    'required',
                    'file',
                    'mimes:xlsx,xls,csv',
                    'max:10240', // 10MB
                ],
                'period_id' => 'required|exists:periods,id',
                'event_id' => 'nullable|exists:events,id',
            ], [
                'file.required' => 'Debe seleccionar un archivo',
                'file.mimes' => 'El archivo debe ser Excel (.xlsx, .xls) o CSV',
                'file.max' => 'El archivo no debe superar los 10MB',
                'period_id.required' => 'Debe seleccionar un periodo',
                'period_id.exists' => 'El periodo seleccionado no existe',
                'event_id.exists' => 'El evento seleccionado no existe',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Error de validación',
                    'errors' => $validator->errors(),
                ], 422);
            }

            // Verificar que evento pertenezca al periodo
            if ($request->event_id) {
                $event = \App\Models\Event::findOrFail($request->event_id);
                if ($event->period_id != $request->period_id) {
                    return response()->json([
                        'success' => false,
                        'message' => 'El evento seleccionado no pertenece al periodo',
                    ], 422);
                }
            }

            $file = $request->file('file');

            Log::info('Iniciando importación de estudiantes', [
                'filename' => $file->getClientOriginalName(),
                'size' => $file->getSize(),
                'mime' => $file->getMimeType(),
                'period_id' => $request->period_id,
                'event_id' => $request->event_id,
            ]);

            // Ejecutar importación con periodo y evento
            $import = new \App\Imports\StudentsImport($request->period_id, $request->event_id);

            try {
                Excel::import($import, $file);
            } catch (\Maatwebsite\Excel\Validators\ValidationException $e) {
                $failures = $e->failures();

                $errors = [];
                foreach ($failures as $failure) {
                    $errors[] = [
                        'row' => $failure->row(),
                        'attribute' => $failure->attribute(),
                        'errors' => $failure->errors(),
                        'values' => $failure->values(),
                    ];
                }

                return response()->json([
                    'success' => false,
                    'message' => 'Error de validación en el archivo Excel',
                    'errors' => $errors,
                ], 422);
            }

            // Resultados
            $summary = $import->getSummary();
            $errors = $import->getErrors();

            $period = \App\Models\Period::find($request->period_id);
            $event = $request->event_id ? \App\Models\Event::find($request->event_id) : null;

            Log::info('Importación completada', [
                'summary' => $summary,
                'period' => $period->name,
                'event' => $event ? $event->name : 'Sin evento',
            ]);

            // No importó nada → mostrar error
            if ($summary['imported'] === 0 && count($errors) > 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se pudo importar ningún estudiante',
                    'summary' => $summary,
                    'errors' => $errors,
                    'period' => [
                        'id' => $period->id,
                        'name' => $period->name,
                    ],
                    'event' => $event ? [
                        'id' => $event->id,
                        'name' => $event->name,
                    ] : null,
                ], 422);
            }

            // Importación sin errores
            if (count($errors) === 0) {
                return response()->json([
                    'success' => true,
                    'message' => "Se importaron {$summary['imported']} estudiantes exitosamente al periodo {$period->name}" .
                        ($event ? " - Evento: {$event->name}" : ""),
                    'summary' => $summary,
                    'period' => [
                        'id' => $period->id,
                        'name' => $period->name,
                    ],
                    'event' => $event ? [
                        'id' => $event->id,
                        'name' => $event->name,
                    ] : null,
                ], 200);
            }

            // Importación parcial
            return response()->json([
                'success' => true,
                'message' => "Se importaron {$summary['imported']} estudiantes. {$summary['errors']} registros tuvieron errores",
                'summary' => $summary,
                'errors' => $errors,
                'period' => [
                    'id' => $period->id,
                    'name' => $period->name,
                ],
                'event' => $event ? [
                    'id' => $event->id,
                    'name' => $event->name,
                ] : null,
            ], 200);

        } catch (\Exception $e) {
            Log::error('Error durante la importación', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error al procesar el archivo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }


    // ------------------------------
    // IMPORTACIONES ORIGINALES
    // ------------------------------

    public function importJurors(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,xls|max:2048',
        ]);

        try {
            $import = new JurorsImport();
            Excel::import($import, $request->file('file'));

            return response()->json([
                'success' => true,
                'message' => "Se importaron {$import->getImportedCount()} jurados",
                'imported' => $import->getImportedCount(),
                'errors' => $import->getErrors(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al importar jurados',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function importArticles(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,xls|max:2048',
        ]);

        try {
            $import = new ArticlesImport();
            Excel::import($import, $request->file('file'));

            return response()->json([
                'success' => true,
                'message' => "Se importaron {$import->getImportedCount()} artículos",
                'imported' => $import->getImportedCount(),
                'errors' => $import->getErrors(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al importar artículos',
                'error' => $e->getMessage(),
            ], 500);
        }
    }


    // =============================
    //           EXPORTS
    // =============================

    public function exportStudents()
    {
        return Excel::download(new StudentsExport(), 'estudiantes_' . date('Y-m-d') . '.xlsx');
    }

    public function exportJurors()
    {
        return Excel::download(new JurorsExport(), 'jurados_' . date('Y-m-d') . '.xlsx');
    }

    public function exportArticles()
    {
        return Excel::download(new ArticlesExport(), 'articulos_' . date('Y-m-d') . '.xlsx');
    }

    public function exportEvaluations()
    {
        return Excel::download(new EvaluationsExport(), 'evaluaciones_' . date('Y-m-d') . '.xlsx');
    }

    public function exportAttendances()
    {
        return Excel::download(new AttendancesExport(), 'asistencias_' . date('Y-m-d') . '.xlsx');
    }

    public function exportFullReport()
    {
        return Excel::download(new class implements \Maatwebsite\Excel\Concerns\WithMultipleSheets {
            public function sheets(): array
            {
                return [
                    'Estudiantes' => new StudentsExport(),
                    'Jurados' => new JurorsExport(),
                    'Artículos' => new ArticlesExport(),
                    'Evaluaciones' => new EvaluationsExport(),
                    'Asistencias' => new AttendancesExport(),
                ];
            }
        }, 'reporte_completo_' . date('Y-m-d') . '.xlsx');
    }


    // =============================
    //      ESTADÍSTICAS
    // =============================

    public function dashboard()
    {
        $stats = [
            'total_students' => \App\Models\Student::count(),
            'total_ponentes' => \App\Models\Student::where('type', 'ponente')->count(),
            'total_oyentes' => \App\Models\Student::where('type', 'oyente')->count(),
            'total_jurors' => \App\Models\Juror::count(),
            'total_articles' => \App\Models\Article::count(),
            'total_evaluations' => \App\Models\Evaluation::count(),
            'total_attendances' => \App\Models\Attendance::count(),
        ];

        return response()->json(['success' => true, 'data' => $stats]);
    }


    public function detailedStatistics()
    {
        $stats = [
            'students' => [
                'total' => \App\Models\Student::count(),
                'ponentes' => \App\Models\Student::where('type', 'ponente')->count(),
                'oyentes' => \App\Models\Student::where('type', 'oyente')->count(),
            ],
            'jurors' => [
                'total' => \App\Models\Juror::count(),
                'with_articles' => \App\Models\Juror::has('articles')->count(),
                'with_evaluations' => \App\Models\Juror::has('evaluations')->count(),
            ],
            'articles' => [
                'total' => \App\Models\Article::count(),
                'by_type' => \App\Models\Article::selectRaw('type, count(*) as count')
                    ->groupBy('type')
                    ->pluck('count', 'type'),
                'by_shift' => \App\Models\Article::selectRaw('shift, count(*) as count')
                    ->whereNotNull('shift')
                    ->groupBy('shift')
                    ->pluck('count', 'shift'),
                'with_jurors' => \App\Models\Article::has('jurors', '>=', 2)->count(),
                'evaluated' => \App\Models\Article::has('evaluations')->count(),
            ],
            'evaluations' => [
                'total' => \App\Models\Evaluation::count(),
                'average_score' => round(\App\Models\Evaluation::avg('promedio'), 2),
            ],
            'attendances' => [
                'total' => \App\Models\Attendance::count(),
                'by_article' => \App\Models\Attendance::selectRaw('article_id, count(*) as count')
                    ->groupBy('article_id')
                    ->with('article:id,title')
                    ->get()
                    ->map(fn($item) => [
                        'article' => $item->article->title ?? 'N/A',
                        'attendances' => $item->count,
                    ]),
            ],
        ];

        return response()->json(['success' => true, 'data' => $stats]);
    }


    public function articlesByType()
    {
        $articles = \App\Models\Article::with(['student', 'jurors', 'evaluations'])
            ->get()
            ->groupBy('type')
            ->map(function ($group) {
                return [
                    'count' => $group->count(),
                    'articles' => $group->map(function ($article) {
                        return [
                            'id' => $article->id,
                            'title' => $article->title,
                            'ponente' => $article->student->fullName(),
                            'jurors_count' => $article->jurors()->count(),
                            'average_score' => round($article->averageScore(), 2),
                            'attendances' => $article->totalAttendances(),
                        ];
                    }),
                ];
            });

        return response()->json(['success' => true, 'data' => $articles]);
    }


    public function articlesRanking()
    {
        $articles = \App\Models\Article::with(['student', 'evaluations'])
            ->has('evaluations')
            ->get()
            ->map(function ($article) {
                return [
                    'id' => $article->id,
                    'title' => $article->title,
                    'ponente' => $article->student->fullName(),
                    'type' => $article->type,
                    'average_score' => round($article->averageScore(), 2),
                    'evaluations_count' => $article->evaluations()->count(),
                ];
            })
            ->sortByDesc('average_score')
            ->values();

        return response()->json(['success' => true, 'data' => $articles]);
    }
}

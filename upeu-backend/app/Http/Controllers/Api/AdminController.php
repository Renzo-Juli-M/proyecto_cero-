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
use App\Models\Article;
use App\Models\Student;
use App\Models\Evaluation;
use App\Models\Juror;

class AdminController extends Controller
{
    /**
     * ============================
     *  IMPORTAR ESTUDIANTES (NUEVO)
     * ============================
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
            'total_students' => Student::count(),
            'total_ponentes' => Student::where('type', 'ponente')->count(),
            'total_oyentes' => Student::where('type', 'oyente')->count(),
            'total_jurors' => Juror::count(),
            'total_articles' => Article::count(),
            'total_evaluations' => Evaluation::count(),
            'total_attendances' => \App\Models\Attendance::count(),
        ];

        return response()->json(['success' => true, 'data' => $stats]);
    }


    public function detailedStatistics()
    {
        $stats = [
            'students' => [
                'total' => Student::count(),
                'ponentes' => Student::where('type', 'ponente')->count(),
                'oyentes' => Student::where('type', 'oyente')->count(),
            ],
            'jurors' => [
                'total' => Juror::count(),
                'with_articles' => Juror::has('articles')->count(),
                'with_evaluations' => Juror::has('evaluations')->count(),
            ],
            'articles' => [
                'total' => Article::count(),
                'by_type' => Article::selectRaw('type, count(*) as count')
                    ->groupBy('type')
                    ->pluck('count', 'type'),
                'by_shift' => Article::selectRaw('shift, count(*) as count')
                    ->whereNotNull('shift')
                    ->groupBy('shift')
                    ->pluck('count', 'shift'),
                'with_jurors' => Article::has('jurors', '>=', 2)->count(),
                'evaluated' => Article::has('evaluations')->count(),
            ],
            'evaluations' => [
                'total' => Evaluation::count(),
                'average_score' => round(Evaluation::avg('promedio'), 2),
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
        $articles = Article::with(['student', 'jurors', 'evaluations'])
            ->get()
            ->groupBy('type')
            ->map(function ($group) {
                return [
                    'count' => $group->count(),
                    'articles' => $group->map(function ($article) {
                        return [
                            'id' => $article->id,
                            'title' => $article->title,
                            'ponente' => $article->student->first_name . ' ' . $article->student->last_name,
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
        $articles = Article::with(['student', 'evaluations'])
            ->has('evaluations')
            ->get()
            ->map(function ($article) {
                return [
                    'id' => $article->id,
                    'title' => $article->title,
                    'ponente' => $article->student->first_name . ' ' . $article->student->last_name,
                    'type' => $article->type,
                    'average_score' => round($article->averageScore(), 2),
                    'evaluations_count' => $article->evaluations()->count(),
                ];
            })
            ->sortByDesc('average_score')
            ->values();

        return response()->json(['success' => true, 'data' => $articles]);
    }


    // =============================
    //    🏆 GANADORES (NUEVO)
    // =============================

    /**
     * Obtener ganadores por categoría de artículo
     * GET /api/admin/winners?limit=3
     */
    public function getWinners(Request $request)
    {
        try {
            // Obtener parámetros opcionales
            $limit = $request->query('limit', 3); // Top 3 por defecto
            $periodId = $request->query('period_id'); // Filtrar por periodo

            // Tipos de artículos (categorías)
            $articleTypes = [
                'revision_sistematica' => 'Revisión Sistemática',
                'empirico' => 'Empírico',
                'teorico' => 'Teórico',
                'estudio_caso' => 'Estudio de Caso',
            ];

            $winners = [];

            foreach ($articleTypes as $type => $typeName) {
                // Query base para artículos del tipo
                $query = Article::where('type', $type)
                    ->with(['student:id,first_name,last_name']) // ✅ Cargar nombres desde students
                    ->withCount('evaluations')
                    ->withAvg('evaluations', 'promedio');

                // Filtrar por periodo si se proporciona
                if ($periodId) {
                    $query->whereHas('student', function ($q) use ($periodId) {
                        $q->where('period_id', $periodId);
                    });
                }

                // Obtener top artículos con evaluaciones ordenados por promedio DESC
                $topArticles = $query
                    ->having('evaluations_count', '>', 0)
                    ->orderBy('evaluations_avg_promedio', 'desc')
                    ->limit($limit)
                    ->get();

                // Formatear datos
                $winners[$type] = [
                    'category' => $typeName,
                    'type_key' => $type,
                    'articles' => $topArticles->map(function ($article, $index) {
                        return [
                            'position' => $index + 1,
                            'article_id' => $article->id,
                            'title' => $article->title,
                            'description' => $article->description,
                            'ponente' => [
                                'id' => $article->student->id,
                                'full_name' => $article->student->first_name . ' ' .
                                              $article->student->last_name, // ✅ Desde students
                            ],
                            'average_score' => round($article->evaluations_avg_promedio, 2),
                            'total_evaluations' => $article->evaluations_count,
                            'presentation_date' => $article->presentation_date,
                            'presentation_time' => $article->presentation_time,
                        ];
                    })->values(),
                    'total_articles' => Article::where('type', $type)->count(),
                ];
            }

            // Estadísticas generales
            $generalStats = [
                'total_articles' => Article::count(),
                'total_evaluated' => Article::has('evaluations')->count(),
                'total_ponentes' => Student::where('type', 'ponente')->count(),
                'average_score_global' => round(
                    Evaluation::avg('promedio') ?? 0,
                    2
                ),
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'winners' => $winners,
                    'stats' => $generalStats,
                    'generated_at' => now()->format('Y-m-d H:i:s'),
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error al obtener ganadores: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Error al obtener ganadores',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener ganador absoluto (mejor promedio general)
     * GET /api/admin/absolute-winner
     */
    public function getAbsoluteWinner(Request $request)
    {
        try {
            $periodId = $request->query('period_id');

            $query = Article::with(['student:id,first_name,last_name']) // ✅ Cargar nombres desde students
                ->withCount('evaluations')
                ->withAvg('evaluations', 'promedio');

            // Filtrar por periodo si se proporciona
            if ($periodId) {
                $query->whereHas('student', function ($q) use ($periodId) {
                    $q->where('period_id', $periodId);
                });
            }

            // Obtener el mejor artículo (promedio más alto)
            $winner = $query
                ->having('evaluations_count', '>', 0)
                ->orderBy('evaluations_avg_promedio', 'desc')
                ->first();

            if (!$winner) {
                return response()->json([
                    'success' => true,
                    'data' => null,
                    'message' => 'No hay ganador aún'
                ]);
            }

            // Obtener detalles de evaluaciones con jurados
            $evaluations = Evaluation::where('article_id', $winner->id)
                ->with(['juror:id,first_name,last_name']) // ✅ Cargar nombres desde jurors
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'article' => [
                        'id' => $winner->id,
                        'title' => $winner->title,
                        'description' => $winner->description,
                        'type' => $winner->type,
                        'presentation_date' => $winner->presentation_date,
                        'presentation_time' => $winner->presentation_time,
                    ],
                    'ponente' => [
                        'id' => $winner->student->id,
                        'full_name' => $winner->student->first_name . ' ' .
                                      $winner->student->last_name, // ✅ Desde students
                    ],
                    'score' => [
                        'average' => round($winner->evaluations_avg_promedio, 2),
                        'total_evaluations' => $winner->evaluations_count,
                    ],
                    'evaluations' => $evaluations->map(function ($eval) {
                        return [
                            'juror' => $eval->juror->first_name . ' ' .
                                      $eval->juror->last_name, // ✅ Desde jurors
                            'score' => round($eval->promedio, 2),
                        ];
                    }),
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error al obtener ganador absoluto: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Error al obtener ganador absoluto',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Evaluation;
use App\Models\Juror;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JurorEvaluationController extends Controller
{
    // Dashboard del jurado
    public function dashboard(Request $request)
    {
        $user = $request->user();
        $juror = Juror::where('user_id', $user->id)->first();

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $stats = [
            'total_articles_assigned' => $juror->articles()->count(),
            'total_evaluations_done' => $juror->evaluations()->count(),
            'pending_evaluations' => $juror->articles()->count() - $juror->evaluations()->count(),
            'average_score_given' => round($juror->evaluations()->avg('promedio'), 2) ?? 0,
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
            'juror' => [
                'id' => $juror->id,
                'full_name' => $juror->fullName(),
                'specialty' => $juror->specialty,
            ],
        ]);
    }

    // Listar artículos asignados al jurado
    public function assignedArticles(Request $request)
    {
        $user = $request->user();
        $juror = Juror::where('user_id', $user->id)->first();

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $articles = $juror->articles()
            ->with(['student', 'evaluations' => function ($query) use ($juror) {
                $query->where('juror_id', $juror->id);
            }])
            ->get()
            ->map(function ($article) use ($juror) {
                $myEvaluation = $article->evaluations->first();

                return [
                    'id' => $article->id,
                    'title' => $article->title,
                    'description' => $article->description,
                    'type' => $article->type,
                    'presentation_date' => $article->presentation_date,
                    'presentation_time' => $article->presentation_time,
                    'shift' => $article->shift,
                    'student' => [
                        'id' => $article->student->id,
                        'full_name' => $article->student->fullName(),
                        'dni' => $article->student->dni,
                    ],
                    'is_evaluated' => $myEvaluation !== null,
                    'my_evaluation' => $myEvaluation ? [
                        'id' => $myEvaluation->id,
                        'introduccion' => $myEvaluation->introduccion,
                        'metodologia' => $myEvaluation->metodologia,
                        'desarrollo' => $myEvaluation->desarrollo,
                        'conclusiones' => $myEvaluation->conclusiones,
                        'presentacion' => $myEvaluation->presentacion,
                        'promedio' => $myEvaluation->promedio,
                        'comentarios' => $myEvaluation->comentarios,
                        'created_at' => $myEvaluation->created_at,
                    ] : null,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $articles,
        ]);
    }

    // Obtener detalle de un artículo asignado
    public function articleDetail(Request $request, $articleId)
    {
        $user = $request->user();
        $juror = Juror::where('user_id', $user->id)->first();

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        // Verificar que el artículo esté asignado a este jurado
        $article = $juror->articles()
            ->with(['student', 'evaluations.juror'])
            ->findOrFail($articleId);

        $myEvaluation = $article->evaluations()
            ->where('juror_id', $juror->id)
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $article->id,
                'title' => $article->title,
                'description' => $article->description,
                'type' => $article->type,
                'presentation_date' => $article->presentation_date,
                'presentation_time' => $article->presentation_time,
                'shift' => $article->shift,
                'student' => [
                    'full_name' => $article->student->fullName(),
                    'dni' => $article->student->dni,
                    'student_code' => $article->student->student_code,
                ],
                'is_evaluated' => $myEvaluation !== null,
                'my_evaluation' => $myEvaluation,
                'other_evaluations_count' => $article->evaluations()
                    ->where('juror_id', '!=', $juror->id)
                    ->count(),
                'average_score' => round($article->averageScore(), 2),
            ],
        ]);
    }

    // Crear evaluación
    public function storeEvaluation(Request $request, $articleId)
    {
        $user = $request->user();
        $juror = Juror::where('user_id', $user->id)->first();

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        // Verificar que el artículo esté asignado a este jurado
        $article = $juror->articles()->findOrFail($articleId);

        // Verificar que no haya evaluado ya
        $existingEvaluation = Evaluation::where('article_id', $articleId)
            ->where('juror_id', $juror->id)
            ->first();

        if ($existingEvaluation) {
            return response()->json([
                'success' => false,
                'message' => 'Ya has evaluado este artículo',
            ], 422);
        }

        $request->validate([
            'introduccion' => 'required|numeric|min:0|max:20',
            'metodologia' => 'required|numeric|min:0|max:20',
            'desarrollo' => 'required|numeric|min:0|max:20',
            'conclusiones' => 'required|numeric|min:0|max:20',
            'presentacion' => 'required|numeric|min:0|max:20',
            'comentarios' => 'nullable|string|max:1000',
        ]);

        try {
            DB::beginTransaction();

            $evaluation = new Evaluation([
                'article_id' => $articleId,
                'juror_id' => $juror->id,
                'introduccion' => $request->introduccion,
                'metodologia' => $request->metodologia,
                'desarrollo' => $request->desarrollo,
                'conclusiones' => $request->conclusiones,
                'presentacion' => $request->presentacion,
                'comentarios' => $request->comentarios,
            ]);

            // Calcular promedio
            $evaluation->calculateAverage();
            $evaluation->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Evaluación registrada exitosamente',
                'data' => $evaluation,
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar evaluación',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Listar mis evaluaciones realizadas
    public function myEvaluations(Request $request)
    {
        $user = $request->user();
        $juror = Juror::where('user_id', $user->id)->first();

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $evaluations = Evaluation::where('juror_id', $juror->id)
            ->with(['article.student'])
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($evaluation) {
                return [
                    'id' => $evaluation->id,
                    'article' => [
                        'id' => $evaluation->article->id,
                        'title' => $evaluation->article->title,
                        'type' => $evaluation->article->type,
                    ],
                    'student' => [
                        'full_name' => $evaluation->article->student->fullName(),
                    ],
                    'introduccion' => $evaluation->introduccion,
                    'metodologia' => $evaluation->metodologia,
                    'desarrollo' => $evaluation->desarrollo,
                    'conclusiones' => $evaluation->conclusiones,
                    'presentacion' => $evaluation->presentacion,
                    'promedio' => $evaluation->promedio,
                    'comentarios' => $evaluation->comentarios,
                    'created_at' => $evaluation->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $evaluations,
        ]);
    }

    // Estadísticas del jurado
    public function statistics(Request $request)
    {
        $user = $request->user();
        $juror = Juror::where('user_id', $user->id)->first();

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $evaluations = $juror->evaluations;

        $stats = [
            'total_evaluations' => $evaluations->count(),
            'average_score_given' => round($evaluations->avg('promedio'), 2) ?? 0,
            'highest_score' => round($evaluations->max('promedio'), 2) ?? 0,
            'lowest_score' => round($evaluations->min('promedio'), 2) ?? 0,
            'criteria_averages' => [
                'introduccion' => round($evaluations->avg('introduccion'), 2) ?? 0,
                'metodologia' => round($evaluations->avg('metodologia'), 2) ?? 0,
                'desarrollo' => round($evaluations->avg('desarrollo'), 2) ?? 0,
                'conclusiones' => round($evaluations->avg('conclusiones'), 2) ?? 0,
                'presentacion' => round($evaluations->avg('presentacion'), 2) ?? 0,
            ],
            'evaluations_by_article_type' => $evaluations
                ->groupBy(function ($eval) {
                    return $eval->article->type;
                })
                ->map(function ($group) {
                    return [
                        'count' => $group->count(),
                        'average' => round($group->avg('promedio'), 2),
                    ];
                }),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}

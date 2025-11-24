<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Evaluation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class JurorDashboardController extends Controller
{
    public function dashboard()
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $stats = [
            'juror_info' => [
                'id' => $juror->id,
                'name' => $juror->fullName(),
                'specialty' => $juror->specialty,
                'dni' => $juror->dni,
            ],
            'total_articles_assigned' => $juror->articles()->count(),
            'total_evaluations' => $juror->evaluations()->count(),
            'pending_evaluations' => $juror->articles()->count() - $juror->evaluations()->count(),
            'average_score_given' => round($juror->evaluations()->avg('promedio') ?? 0, 2),
            'evaluations_by_type' => $juror->evaluations()
                ->join('articles', 'evaluations.article_id', '=', 'articles.id')
                ->selectRaw('articles.type, count(*) as count')
                ->groupBy('articles.type')
                ->get()
                ->pluck('count', 'type'),
            'recent_evaluations' => $juror->evaluations()
                ->with('article.student')
                ->orderBy('created_at', 'desc')
                ->limit(5)
                ->get()
                ->map(function ($evaluation) {
                    return [
                        'id' => $evaluation->id,
                        'article_title' => $evaluation->article->title,
                        'ponente' => $evaluation->article->student->fullName(),
                        'promedio' => $evaluation->promedio,
                        'date' => $evaluation->created_at->format('Y-m-d H:i'),
                    ];
                }),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    public function myArticles(Request $request)
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $query = $juror->articles()->with(['student', 'jurors', 'evaluations']);

        // Filtro por tipo
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Filtro por estado de evaluación
        if ($request->has('status')) {
            if ($request->status === 'pending') {
                $query->whereDoesntHave('evaluations', function ($q) use ($juror) {
                    $q->where('juror_id', $juror->id);
                });
            } elseif ($request->status === 'evaluated') {
                $query->whereHas('evaluations', function ($q) use ($juror) {
                    $q->where('juror_id', $juror->id);
                });
            }
        }

        // Búsqueda por título o ponente
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhereHas('student', function ($sq) use ($search) {
                        $sq->where('first_name', 'like', "%{$search}%")
                            ->orWhere('last_name', 'like', "%{$search}%");
                    });
            });
        }

        $articles = $query->paginate($request->per_page ?? 15);

        // Agregar si ya fue evaluado por este jurado
        $articles->getCollection()->transform(function ($article) use ($juror) {
            $evaluation = $article->evaluations()
                ->where('juror_id', $juror->id)
                ->first();

            $article->my_evaluation = $evaluation ? [
                'id' => $evaluation->id,
                'promedio' => $evaluation->promedio,
                'evaluated_at' => $evaluation->created_at->format('Y-m-d H:i'),
            ] : null;

            return $article;
        });

        return response()->json([
            'success' => true,
            'data' => $articles,
        ]);
    }

    public function articleDetail($id)
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        // Verificar que el artículo esté asignado a este jurado
        $article = $juror->articles()
            ->with(['student', 'jurors', 'evaluations.juror', 'attendances'])
            ->find($id);

        if (!$article) {
            return response()->json([
                'success' => false,
                'message' => 'Artículo no encontrado o no asignado',
            ], 404);
        }

        // Agregar evaluación de este jurado
        $myEvaluation = $article->evaluations()
            ->where('juror_id', $juror->id)
            ->first();

        $article->my_evaluation = $myEvaluation;
        $article->average_score = $article->averageScore();
        $article->total_attendances = $article->totalAttendances();

        return response()->json([
            'success' => true,
            'data' => $article,
        ]);
    }

    public function storeEvaluation(Request $request)
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $request->validate([
            'article_id' => 'required|exists:articles,id',
            'introduccion' => 'required|numeric|min:0|max:20',
            'metodologia' => 'required|numeric|min:0|max:20',
            'desarrollo' => 'required|numeric|min:0|max:20',
            'conclusiones' => 'required|numeric|min:0|max:20',
            'presentacion' => 'required|numeric|min:0|max:20',
            'comentarios' => 'nullable|string',
        ]);

        try {
            // Verificar que el artículo esté asignado a este jurado
            $article = $juror->articles()->find($request->article_id);

            if (!$article) {
                return response()->json([
                    'success' => false,
                    'message' => 'No tienes permiso para evaluar este artículo',
                ], 403);
            }

            // Verificar si ya evaluó este artículo
            $existingEvaluation = Evaluation::where('article_id', $request->article_id)
                ->where('juror_id', $juror->id)
                ->first();

            if ($existingEvaluation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ya evaluaste este artículo. Usa la opción de editar.',
                ], 422);
            }

            // Calcular promedio
            $promedio = round(
                ($request->introduccion +
                    $request->metodologia +
                    $request->desarrollo +
                    $request->conclusiones +
                    $request->presentacion) / 5,
                2
            );

            // Crear evaluación
            $evaluation = Evaluation::create([
                'article_id' => $request->article_id,
                'juror_id' => $juror->id,
                'introduccion' => $request->introduccion,
                'metodologia' => $request->metodologia,
                'desarrollo' => $request->desarrollo,
                'conclusiones' => $request->conclusiones,
                'presentacion' => $request->presentacion,
                'promedio' => $promedio,
                'comentarios' => $request->comentarios,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Evaluación registrada exitosamente',
                'data' => $evaluation->load('article.student'),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar evaluación',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function updateEvaluation(Request $request, $id)
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $evaluation = Evaluation::find($id);

        if (!$evaluation) {
            return response()->json([
                'success' => false,
                'message' => 'Evaluación no encontrada',
            ], 404);
        }

        // Verificar que sea la evaluación de este jurado
        if ($evaluation->juror_id !== $juror->id) {
            return response()->json([
                'success' => false,
                'message' => 'No tienes permiso para editar esta evaluación',
            ], 403);
        }

        $request->validate([
            'introduccion' => 'required|numeric|min:0|max:20',
            'metodologia' => 'required|numeric|min:0|max:20',
            'desarrollo' => 'required|numeric|min:0|max:20',
            'conclusiones' => 'required|numeric|min:0|max:20',
            'presentacion' => 'required|numeric|min:0|max:20',
            'comentarios' => 'nullable|string',
        ]);

        try {
            // Calcular nuevo promedio
            $promedio = round(
                ($request->introduccion +
                    $request->metodologia +
                    $request->desarrollo +
                    $request->conclusiones +
                    $request->presentacion) / 5,
                2
            );

            $evaluation->update([
                'introduccion' => $request->introduccion,
                'metodologia' => $request->metodologia,
                'desarrollo' => $request->desarrollo,
                'conclusiones' => $request->conclusiones,
                'presentacion' => $request->presentacion,
                'promedio' => $promedio,
                'comentarios' => $request->comentarios,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Evaluación actualizada exitosamente',
                'data' => $evaluation->load('article.student'),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar evaluación',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function myEvaluations(Request $request)
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $query = $juror->evaluations()->with('article.student');

        // Búsqueda
        if ($request->has('search')) {
            $search = $request->search;
            $query->whereHas('article', function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhereHas('student', function ($sq) use ($search) {
                        $sq->where('first_name', 'like', "%{$search}%")
                            ->orWhere('last_name', 'like', "%{$search}%");
                    });
            });
        }

        $evaluations = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $evaluations,
        ]);
    }

    public function deleteEvaluation($id)
    {
        $user = Auth::user();
        $juror = $user->juror;

        if (!$juror) {
            return response()->json([
                'success' => false,
                'message' => 'Jurado no encontrado',
            ], 404);
        }

        $evaluation = Evaluation::find($id);

        if (!$evaluation) {
            return response()->json([
                'success' => false,
                'message' => 'Evaluación no encontrada',
            ], 404);
        }

        // Verificar que sea la evaluación de este jurado
        if ($evaluation->juror_id !== $juror->id) {
            return response()->json([
                'success' => false,
                'message' => 'No tienes permiso para eliminar esta evaluación',
            ], 403);
        }

        try {
            $evaluation->delete();

            return response()->json([
                'success' => true,
                'message' => 'Evaluación eliminada exitosamente',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar evaluación',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

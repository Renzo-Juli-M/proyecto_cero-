<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Evaluation;
use App\Models\Juror;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class JurorController extends Controller
{
    // ========== MÉTODOS PARA EL DASHBOARD DEL JURADO ==========

    // Dashboard del jurado
    public function dashboard(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Usuario no autenticado',
                ], 401);
            }

            $juror = Juror::where('user_id', $user->id)->first();

            if (!$juror) {
                return response()->json([
                    'success' => false,
                    'message' => 'Jurado no encontrado',
                ], 404);
            }

            // Artículos asignados
            $assignedArticles = $juror->articles()->with('student')->get();

            // Evaluaciones realizadas
            $evaluations = Evaluation::where('juror_id', $juror->id)
                ->with('article.student')
                ->get();

            // Estadísticas
            $totalAssigned = $assignedArticles->count();
            $totalEvaluated = $evaluations->count();
            $pendingEvaluations = $totalAssigned - $totalEvaluated;

            $data = [
                'juror' => [
                    'id' => $juror->id,
                    'full_name' => $juror->fullName(),
                    'dni' => $juror->dni,
                    'specialty' => $juror->specialty,
                    'email' => $juror->user->email ?? 'N/A',
                ],
                'statistics' => [
                    'total_assigned' => $totalAssigned,
                    'total_evaluated' => $totalEvaluated,
                    'pending_evaluations' => $pendingEvaluations,
                    'average_score' => $evaluations->isNotEmpty()
                        ? round($evaluations->avg('promedio'), 2)
                        : 0,
                ],
                'recent_articles' => $assignedArticles->take(5)->map(function ($article) use ($evaluations) {
                    $evaluation = $evaluations->firstWhere('article_id', $article->id);

                    return [
                        'id' => $article->id,
                        'title' => $article->title,
                        'type' => $article->type,
                        'student_name' => $article->student ? $article->student->fullName() : 'N/A',
                        'is_evaluated' => $evaluation !== null,
                        'score' => $evaluation ? $evaluation->promedio : null,
                    ];
                }),
            ];

            return response()->json([
                'success' => true,
                'data' => $data,
            ]);

        } catch (\Exception $e) {
            Log::error('Error en dashboard de jurado: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error al cargar dashboard',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Listar artículos asignados
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
        ->with('student')
        ->get()
        ->map(function ($article) use ($juror) {
            // Verificar si ya evaluó este artículo
            $evaluation = Evaluation::where('article_id', $article->id)
                ->where('juror_id', $juror->id)
                ->first();

            $result = [
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
                'is_evaluated' => $evaluation !== null,
                'my_evaluation' => null,
            ];

            // Si tiene evaluación, agregar los datos completos
            if ($evaluation) {
                $result['my_evaluation'] = [
                    'id' => $evaluation->id,
                    'introduccion' => (float) $evaluation->introduccion,
                    'metodologia' => (float) $evaluation->metodologia,
                    'desarrollo' => (float) $evaluation->desarrollo,
                    'conclusiones' => (float) $evaluation->conclusiones,
                    'presentacion' => (float) $evaluation->presentacion,
                    'promedio' => (float) $evaluation->promedio,
                    'comentarios' => $evaluation->comentarios,
                    'created_at' => $evaluation->created_at->format('Y-m-d H:i:s'),
                ];
            }

            return $result;
        });

    return response()->json([
        'success' => true,
        'data' => $articles,
    ]);
}
/////
    // Ver detalle de un artículo
    public function articleDetail(Request $request, $id)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Usuario no autenticado',
                ], 401);
            }

            $juror = Juror::where('user_id', $user->id)->first();

            if (!$juror) {
                return response()->json([
                    'success' => false,
                    'message' => 'Jurado no encontrado',
                ], 404);
            }

            $article = Article::with(['student', 'jurors', 'evaluations.juror'])
                ->findOrFail($id);

            // Verificar que el jurado esté asignado
            if (!$article->jurors->contains($juror->id)) {
                return response()->json([
                    'success' => false,
                    'message' => 'No tienes permiso para ver este artículo',
                ], 403);
            }

            $myEvaluation = $article->evaluations->firstWhere('juror_id', $juror->id);

            $data = [
                'id' => $article->id,
                'title' => $article->title,
                'description' => $article->description,
                'type' => $article->type,
                'presentation_date' => $article->presentation_date,
                'presentation_time' => $article->presentation_time,
                'shift' => $article->shift,
                'student' => [
                    'full_name' => $article->student ? $article->student->fullName() : 'N/A',
                    'student_code' => $article->student ? $article->student->student_code : 'N/A',
                    'email' => $article->student && $article->student->user
                        ? $article->student->user->email
                        : 'N/A',
                ],
                'my_evaluation' => $myEvaluation ? [
                    'introduccion' => $myEvaluation->introduccion,
                    'metodologia' => $myEvaluation->metodologia,
                    'desarrollo' => $myEvaluation->desarrollo,
                    'conclusiones' => $myEvaluation->conclusiones,
                    'presentacion' => $myEvaluation->presentacion,
                    'promedio' => $myEvaluation->promedio,
                    'comentarios' => $myEvaluation->comentarios,
                    'evaluated_at' => $myEvaluation->created_at->format('Y-m-d H:i:s'),
                ] : null,
                'other_jurors' => $article->jurors->filter(function ($j) use ($juror) {
                    return $j->id !== $juror->id;
                })->map(function ($j) {
                    return [
                        'full_name' => $j->fullName(),
                        'specialty' => $j->specialty,
                    ];
                })->values(),
            ];

            return response()->json([
                'success' => true,
                'data' => $data,
            ]);

        } catch (\Exception $e) {
            Log::error('Error en articleDetail: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error al cargar detalle del artículo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Evaluar artículo
    public function evaluateArticle(Request $request, $id)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Usuario no autenticado',
                ], 401);
            }

            $juror = Juror::where('user_id', $user->id)->first();

            if (!$juror) {
                return response()->json([
                    'success' => false,
                    'message' => 'Jurado no encontrado',
                ], 404);
            }

            $article = Article::findOrFail($id);

            // Verificar que esté asignado
            if (!$article->jurors->contains($juror->id)) {
                return response()->json([
                    'success' => false,
                    'message' => 'No tienes permiso para evaluar este artículo',
                ], 403);
            }

            // Verificar si ya evaluó
            $existingEvaluation = Evaluation::where('article_id', $id)
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
                'comentarios' => 'nullable|string',
            ]);

            DB::beginTransaction();

            $promedio = (
                $request->introduccion +
                $request->metodologia +
                $request->desarrollo +
                $request->conclusiones +
                $request->presentacion
            ) / 5;

            $evaluation = Evaluation::create([
                'article_id' => $id,
                'juror_id' => $juror->id,
                'introduccion' => $request->introduccion,
                'metodologia' => $request->metodologia,
                'desarrollo' => $request->desarrollo,
                'conclusiones' => $request->conclusiones,
                'presentacion' => $request->presentacion,
                'promedio' => round($promedio, 2),
                'comentarios' => $request->comentarios,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Evaluación registrada exitosamente',
                'data' => $evaluation,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error en evaluateArticle: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error al registrar evaluación',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Ver mis evaluaciones
    public function myEvaluations(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Usuario no autenticado',
                ], 401);
            }

            $juror = Juror::where('user_id', $user->id)->first();

            if (!$juror) {
                return response()->json([
                    'success' => false,
                    'message' => 'Jurado no encontrado',
                ], 404);
            }

            $evaluations = Evaluation::where('juror_id', $juror->id)
                ->with('article.student')
                ->orderBy('created_at', 'desc')
                ->get();

            $evaluationsData = $evaluations->map(function ($eval) {
                return [
                    'id' => $eval->id,
                    'article' => [
                        'id' => $eval->article->id,
                        'title' => $eval->article->title,
                        'type' => $eval->article->type,
                        'student_name' => $eval->article->student
                            ? $eval->article->student->fullName()
                            : 'N/A',
                    ],
                    'scores' => [
                        'introduccion' => $eval->introduccion,
                        'metodologia' => $eval->metodologia,
                        'desarrollo' => $eval->desarrollo,
                        'conclusiones' => $eval->conclusiones,
                        'presentacion' => $eval->presentacion,
                        'promedio' => $eval->promedio,
                    ],
                    'comentarios' => $eval->comentarios,
                    'evaluated_at' => $eval->created_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'total_evaluations' => $evaluationsData->count(),
                    'evaluations' => $evaluationsData,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Error en myEvaluations: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error al cargar evaluaciones',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Estadísticas del jurado
    public function statistics(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Usuario no autenticado',
                ], 401);
            }

            $juror = Juror::where('user_id', $user->id)->first();

            if (!$juror) {
                return response()->json([
                    'success' => false,
                    'message' => 'Jurado no encontrado',
                ], 404);
            }

            $evaluations = Evaluation::where('juror_id', $juror->id)->get();
            $assignedArticles = $juror->articles()->count();

            $data = [
                'total_assigned' => $assignedArticles,
                'total_evaluated' => $evaluations->count(),
                'pending_evaluations' => $assignedArticles - $evaluations->count(),
                'average_scores' => [
                    'introduccion' => round($evaluations->avg('introduccion'), 2) ?? 0,
                    'metodologia' => round($evaluations->avg('metodologia'), 2) ?? 0,
                    'desarrollo' => round($evaluations->avg('desarrollo'), 2) ?? 0,
                    'conclusiones' => round($evaluations->avg('conclusiones'), 2) ?? 0,
                    'presentacion' => round($evaluations->avg('presentacion'), 2) ?? 0,
                    'general' => round($evaluations->avg('promedio'), 2) ?? 0,
                ],
                'evaluation_distribution' => [
                    'excellent' => $evaluations->filter(fn($e) => $e->promedio >= 18)->count(),
                    'good' => $evaluations->filter(fn($e) => $e->promedio >= 14 && $e->promedio < 18)->count(),
                    'regular' => $evaluations->filter(fn($e) => $e->promedio >= 11 && $e->promedio < 14)->count(),
                    'deficient' => $evaluations->filter(fn($e) => $e->promedio < 11)->count(),
                ],
            ];

            return response()->json([
                'success' => true,
                'data' => $data,
            ]);

        } catch (\Exception $e) {
            Log::error('Error en statistics: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error al cargar estadísticas',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // ========== MÉTODOS CRUD PARA ADMIN ==========

    public function index(Request $request)
    {
        $query = Juror::with('user');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('dni', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%");
            });
        }

        $jurors = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $jurors,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'dni' => 'required|string|size:8|unique:jurors,dni',
            'username' => 'required|string|unique:jurors,username',
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'specialty' => 'nullable|string|max:255',
        ]);

        try {
            DB::beginTransaction();

            $user = User::create([
                'email' => $request->email,
                'password' => Hash::make($request->dni),
                'role' => 'juror',
            ]);

            $juror = Juror::create([
                'user_id' => $user->id,
                'dni' => $request->dni,
                'username' => $request->username,
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'specialty' => $request->specialty,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Jurado creado exitosamente',
                'data' => $juror->load('user'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al crear jurado',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function show($id)
    {
        $juror = Juror::with(['user', 'articles', 'evaluations'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $juror,
        ]);
    }

    public function update(Request $request, $id)
    {
        $juror = Juror::findOrFail($id);

        $request->validate([
            'dni' => 'required|string|size:8|unique:jurors,dni,' . $id,
            'username' => 'required|string|unique:jurors,username,' . $id,
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $juror->user_id,
            'specialty' => 'nullable|string|max:255',
        ]);

        try {
            DB::beginTransaction();

            $juror->user->update([
                'email' => $request->email,
            ]);

            $juror->update([
                'dni' => $request->dni,
                'username' => $request->username,
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'specialty' => $request->specialty,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Jurado actualizado exitosamente',
                'data' => $juror->load('user'),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar jurado',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $juror = Juror::findOrFail($id);
            $user = $juror->user;

            DB::beginTransaction();

            $juror->delete();
            $user->delete();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Jurado eliminado exitosamente',
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar jurado',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

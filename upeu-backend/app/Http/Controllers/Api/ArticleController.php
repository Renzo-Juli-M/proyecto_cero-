<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Juror;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ArticleController extends Controller
{
    /**
     * Listar artículos con filtros y búsqueda
     */
    public function index(Request $request)
    {
        $query = Article::with(['student', 'jurors', 'evaluations']);

        // Filtro por tipo
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Filtro por turno
        if ($request->has('shift')) {
            $query->where('shift', $request->shift);
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

        $articles = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $articles,
        ]);
    }

    /**
     * Crear un nuevo artículo
     */
    public function store(Request $request)
    {
        $request->validate([
            'student_id' => 'required|exists:students,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:revision_sistematica,empirico,teorico,estudio_caso',
            'presentation_date' => 'nullable|date',
            'presentation_time' => 'nullable|date_format:H:i',
            'shift' => 'nullable|in:mañana,tarde',
        ]);

        try {
            // Verificar que el estudiante sea ponente
            $student = \App\Models\Student::findOrFail($request->student_id);
            if ($student->type !== 'ponente') {
                return response()->json([
                    'success' => false,
                    'message' => 'Solo los estudiantes ponentes pueden tener artículos',
                ], 422);
            }

            // Verificar que no tenga ya un artículo
            $existingArticle = Article::where('student_id', $request->student_id)->first();
            if ($existingArticle) {
                return response()->json([
                    'success' => false,
                    'message' => 'Este estudiante ya tiene un artículo asignado',
                ], 422);
            }

            $article = Article::create($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Artículo creado exitosamente',
                'data' => $article->load('student'),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al crear artículo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mostrar un artículo específico
     */
    public function show($id)
    {
        try {
            $article = Article::with([
                'student',
                'jurors',
                'evaluations.juror',
                'attendances.student'
            ])->findOrFail($id);

            // Calcular promedio de evaluaciones
            $article->average_score = $article->averageScore();
            $article->total_attendances = $article->totalAttendances();

            return response()->json([
                'success' => true,
                'data' => $article,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Artículo no encontrado',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Actualizar un artículo
     */
    public function update(Request $request, $id)
    {
        $article = Article::findOrFail($id);

        $request->validate([
            'student_id' => 'required|exists:students,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:revision_sistematica,empirico,teorico,estudio_caso',
            'presentation_date' => 'nullable|date',
            'presentation_time' => 'nullable|date_format:H:i',
            'shift' => 'nullable|in:mañana,tarde',
        ]);

        try {
            $article->update($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Artículo actualizado exitosamente',
                'data' => $article->load('student'),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar artículo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Eliminar un artículo
     */
    public function destroy($id)
    {
        try {
            $article = Article::findOrFail($id);

            // Eliminar relaciones primero
            $article->jurors()->detach();
            $article->evaluations()->delete();
            $article->attendances()->delete();

            $article->delete();

            return response()->json([
                'success' => true,
                'message' => 'Artículo eliminado exitosamente',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar artículo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Asignar jurados a un artículo
     */
    public function assignJurors(Request $request, $id)
    {
        $request->validate([
            'juror_ids' => 'required|array|min:2',
            'juror_ids.*' => 'exists:jurors,id',
        ]);

        try {
            $article = Article::findOrFail($id);

            // Verificar que los jurados existan
            $jurors = Juror::whereIn('id', $request->juror_ids)->get();

            if ($jurors->count() < 2) {
                return response()->json([
                    'success' => false,
                    'message' => 'Se requieren al menos 2 jurados',
                ], 422);
            }

            // Sincronizar jurados (reemplaza los anteriores)
            $article->jurors()->sync($request->juror_ids);

            return response()->json([
                'success' => true,
                'message' => 'Jurados asignados exitosamente',
                'data' => $article->load('jurors'),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al asignar jurados',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * 🔧 Obtener jurados disponibles para asignar (SIN PAGINACIÓN)
     */
    public function availableJurors()
    {
        try {
            // 🔧 Obtener todos los jurados sin especificar columnas
            // Esto evita errores si algunas columnas no existen
            $jurors = Juror::orderBy('last_name', 'asc')
                ->orderBy('first_name', 'asc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $jurors,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener jurados disponibles',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtener estadísticas de un artículo
     */
    public function statistics($id)
    {
        try {
            $article = Article::with(['evaluations', 'attendances'])->findOrFail($id);

            $evaluations = $article->evaluations;
            $totalEvaluations = $evaluations->count();

            $data = [
                'total_evaluations' => $totalEvaluations,
                'average_score' => $totalEvaluations > 0
                    ? round($evaluations->avg('promedio'), 2)
                    : 0,
                'total_attendances' => $article->attendances->count(),
                'criteria_averages' => [
                    'introduccion' => $totalEvaluations > 0
                        ? round($evaluations->avg('introduccion'), 2)
                        : 0,
                    'metodologia' => $totalEvaluations > 0
                        ? round($evaluations->avg('metodologia'), 2)
                        : 0,
                    'desarrollo' => $totalEvaluations > 0
                        ? round($evaluations->avg('desarrollo'), 2)
                        : 0,
                    'conclusiones' => $totalEvaluations > 0
                        ? round($evaluations->avg('conclusiones'), 2)
                        : 0,
                    'presentacion' => $totalEvaluations > 0
                        ? round($evaluations->avg('presentacion'), 2)
                        : 0,
                ],
            ];

            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener estadísticas',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Attendance;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Pusher\Pusher;


class StudentController extends Controller
{
    // ========== MÉTODOS PARA ADMIN ==========

    public function index(Request $request)
    {
        $query = Student::with('user');

        // Filtros
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('dni', 'like', "%{$search}%")
                    ->orWhere('student_code', 'like', "%{$search}%")
                    ->orWhere('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%");
            });
        }

        $students = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $students,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'dni' => 'required|string|size:8|unique:students,dni',
            'student_code' => 'required|string|unique:students,student_code',
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'type' => 'required|in:ponente,oyente',
            'email' => 'required|email|unique:users,email',
        ]);

        try {
            DB::beginTransaction();

            // Crear usuario
            $user = User::create([
                'email' => $request->email,
                'password' => Hash::make($request->dni),
                'role' => 'student',
            ]);

            // Crear estudiante
            $student = Student::create([
                'user_id' => $user->id,
                'dni' => $request->dni,
                'student_code' => $request->student_code,
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'type' => $request->type,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Estudiante creado exitosamente',
                'data' => $student->load('user'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al crear estudiante',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function show($id)
    {
        $student = Student::with(['user', 'articles', 'attendances'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $student,
        ]);
    }

    public function update(Request $request, $id)
    {
        $student = Student::findOrFail($id);

        $request->validate([
            'dni' => 'required|string|size:8|unique:students,dni,' . $id,
            'student_code' => 'required|string|unique:students,student_code,' . $id,
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'type' => 'required|in:ponente,oyente',
            'email' => 'required|email|unique:users,email,' . $student->user_id,
        ]);

        try {
            DB::beginTransaction();

            $student->user->update([
                'email' => $request->email,
            ]);

            $student->update([
                'dni' => $request->dni,
                'student_code' => $request->student_code,
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'type' => $request->type,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Estudiante actualizado exitosamente',
                'data' => $student->load('user'),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar estudiante',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $student = Student::findOrFail($id);
            $user = $student->user;

            DB::beginTransaction();

            $student->delete();
            $user->delete();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Estudiante eliminado exitosamente',
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar estudiante',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // ========== MÉTODOS PARA ESTUDIANTES ==========

    public function dashboard(Request $request)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Estudiante no encontrado',
            ], 404);
        }

        $data = [
            'student' => [
                'id' => $student->id,
                'full_name' => $student->fullName(),
                'dni' => $student->dni,
                'student_code' => $student->student_code,
                'type' => $student->type,
                'email' => $student->user->email,
            ],
        ];

        if ($student->type === 'ponente') {
            $article = Article::where('student_id', $student->id)
                ->with(['evaluations.juror', 'jurors'])
                ->first();

            $data['ponente_data'] = [
                'has_article' => $article !== null,
                'article' => $article ? [
                    'id' => $article->id,
                    'title' => $article->title,
                    'description' => $article->description,
                    'type' => $article->type,
                    'presentation_date' => $article->presentation_date,
                    'presentation_time' => $article->presentation_time,
                    'shift' => $article->shift,
                    'total_evaluations' => $article->evaluations->count(),
                    'average_score' => round($article->averageScore(), 2),
                    'jurors_count' => $article->jurors->count(),
                ] : null,
            ];
        } else {
            $totalAttendances = Attendance::where('student_id', $student->id)->count();
            $recentAttendances = Attendance::where('student_id', $student->id)
                ->with('article.student')
                ->orderBy('created_at', 'desc')
                ->limit(5)
                ->get();

            $data['oyente_data'] = [
                'total_attendances' => $totalAttendances,
                'recent_attendances' => $recentAttendances->map(function ($attendance) {
                    return [
                        'id' => $attendance->id,
                        'article_title' => $attendance->article->title,
                        'ponente' => $attendance->article->student->fullName(),
                        'attended_at' => $attendance->created_at->format('Y-m-d H:i:s'),
                    ];
                }),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function myArticle(Request $request)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Estudiante no encontrado',
            ], 404);
        }

        if ($student->type !== 'ponente') {
            return response()->json([
                'success' => false,
                'message' => 'Solo los ponentes pueden ver su artículo',
            ], 403);
        }

        $article = Article::where('student_id', $student->id)
            ->with(['evaluations.juror', 'jurors', 'attendances'])
            ->first();

        if (!$article) {
            return response()->json([
                'success' => false,
                'message' => 'No tienes un artículo asignado',
            ], 404);
        }

        $evaluations = $article->evaluations->map(function ($eval) {
            return [
                'juror' => $eval->juror->fullName(),
                'juror_specialty' => $eval->juror->specialty,
                'introduccion' => $eval->introduccion,
                'metodologia' => $eval->metodologia,
                'desarrollo' => $eval->desarrollo,
                'conclusiones' => $eval->conclusiones,
                'presentacion' => $eval->presentacion,
                'promedio' => $eval->promedio,
                'comentarios' => $eval->comentarios,
                'evaluated_at' => $eval->created_at->format('Y-m-d H:i:s'),
            ];
        });

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
                'jurors' => $article->jurors->map(function ($juror) {
                    return [
                        'id' => $juror->id,
                        'full_name' => $juror->fullName(),
                        'specialty' => $juror->specialty,
                    ];
                }),
                'evaluations' => $evaluations,
                'total_evaluations' => $evaluations->count(),
                'average_score' => round($article->averageScore(), 2),
                'total_attendances' => $article->attendances->count(),
                'criteria_averages' => [
                    'introduccion' => round($article->evaluations->avg('introduccion'), 2) ?? 0,
                    'metodologia' => round($article->evaluations->avg('metodologia'), 2) ?? 0,
                    'desarrollo' => round($article->evaluations->avg('desarrollo'), 2) ?? 0,
                    'conclusiones' => round($article->evaluations->avg('conclusiones'), 2) ?? 0,
                    'presentacion' => round($article->evaluations->avg('presentacion'), 2) ?? 0,
                ],
            ],
        ]);
    }

    /**
 * Verificar si el ponente tiene un QR activo
 * GET /api/student/qr-status
 */
public function checkQRStatus(Request $request)
{
    $user = $request->user();
    $student = Student::where('user_id', $user->id)->first();

    if (!$student || $student->type !== 'ponente') {
        return response()->json([
            'success' => false,
            'message' => 'Solo los ponentes pueden verificar el estado del QR',
        ], 403);
    }

    $article = Article::where('student_id', $student->id)->first();

    if (!$article) {
        return response()->json([
            'success' => false,
            'message' => 'No tienes un artículo asignado',
        ], 404);
    }

    // Buscar QR activo (no expirado)
    $activeQR = DB::table('article_qr_codes')
        ->where('article_id', $article->id)
        ->where('expires_at', '>', now())
        ->orderBy('created_at', 'desc')
        ->first();

    if ($activeQR) {
        return response()->json([
            'success' => true,
            'data' => [
                'has_active_qr' => true,
                'qr_token' => $activeQR->qr_token,
                'article_id' => $article->id,
                'article_title' => $article->title,
                'expires_at' => $activeQR->expires_at,
                'remaining_minutes' => now()->diffInMinutes($activeQR->expires_at, false),
            ],
        ]);
    }

    return response()->json([
        'success' => true,
        'data' => [
            'has_active_qr' => false,
            'article_id' => $article->id,
            'article_title' => $article->title,
        ],
    ]);
}

    public function availableArticles(Request $request)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Estudiante no encontrado',
            ], 404);
        }

        if ($student->type !== 'oyente') {
            return response()->json([
                'success' => false,
                'message' => 'Solo los oyentes pueden ver artículos disponibles',
            ], 403);
        }

        $attendedArticleIds = Attendance::where('student_id', $student->id)
            ->pluck('article_id')
            ->toArray();

        $articles = Article::with('student')
            ->get()
            ->map(function ($article) use ($attendedArticleIds) {
                return [
                    'id' => $article->id,
                    'title' => $article->title,
                    'type' => $article->type,
                    'presentation_date' => $article->presentation_date,
                    'presentation_time' => $article->presentation_time,
                    'shift' => $article->shift,
                    'ponente' => [
                        'full_name' => $article->student->fullName(),
                        'student_code' => $article->student->student_code,
                    ],
                    'has_attended' => in_array($article->id, $attendedArticleIds),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $articles,
        ]);
    }

    public function registerAttendance(Request $request, $articleId)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Estudiante no encontrado',
            ], 404);
        }

        if ($student->type !== 'oyente') {
            return response()->json([
                'success' => false,
                'message' => 'Solo los oyentes pueden registrar asistencia',
            ], 403);
        }

        $article = Article::findOrFail($articleId);

        $existingAttendance = Attendance::where('student_id', $student->id)
            ->where('article_id', $articleId)
            ->first();

        if ($existingAttendance) {
            return response()->json([
                'success' => false,
                'message' => 'Ya has registrado tu asistencia a este artículo',
            ], 422);
        }

        try {
            DB::beginTransaction();

            $attendance = Attendance::create([
                'article_id' => $articleId,
                'student_id' => $student->id,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Asistencia registrada exitosamente',
                'data' => [
                    'id' => $attendance->id,
                    'article_title' => $article->title,
                    'attended_at' => $attendance->created_at->format('Y-m-d H:i:s'),
                ],
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar asistencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function myAttendances(Request $request)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Estudiante no encontrado',
            ], 404);
        }

        if ($student->type !== 'oyente') {
            return response()->json([
                'success' => false,
                'message' => 'Solo los oyentes tienen historial de asistencias',
            ], 403);
        }

        $attendances = Attendance::where('student_id', $student->id)
            ->with('article.student')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($attendance) {
                return [
                    'id' => $attendance->id,
                    'article' => [
                        'id' => $attendance->article->id,
                        'title' => $attendance->article->title,
                        'type' => $attendance->article->type,
                        'presentation_date' => $attendance->article->presentation_date,
                        'presentation_time' => $attendance->article->presentation_time,
                    ],
                    'ponente' => [
                        'full_name' => $attendance->article->student->fullName(),
                        'student_code' => $attendance->article->student->student_code,
                    ],
                    'attended_at' => $attendance->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'total_attendances' => $attendances->count(),
                'attendances' => $attendances,
            ],
        ]);
    }


   // ========== MÉTODO MEJORADO: GENERAR QR CON JWT ==========

    /**
     * Generar QR con JWT firmado para asistencia
     * Solo para ponentes
     */
    public function generateQR(Request $request)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student || $student->type !== 'ponente') {
            return response()->json([
                'success' => false,
                'message' => 'Solo los ponentes pueden generar QR',
            ], 403);
        }

        $article = Article::where('student_id', $student->id)->first();

        if (!$article) {
            return response()->json([
                'success' => false,
                'message' => 'No tienes un artículo asignado',
            ], 404);
        }

        // Verificar si ya hay un QR activo (menos de 30 minutos)
        $existingQR = DB::table('article_qr_codes')
            ->where('article_id', $article->id)
            ->where('expires_at', '>', now())
            ->first();

        if ($existingQR) {
            // Decodificar el JWT existente para obtener info
            try {
                $decoded = JWT::decode(
                    $existingQR->qr_token,
                    new Key(config('app.key'), 'HS256')
                );

                return response()->json([
                    'success' => true,
                    'data' => [
                        'qr_token' => $existingQR->qr_token,
                        'article_id' => $article->id,
                        'article_title' => $article->title,
                        'expires_at' => $existingQR->expires_at,
                        'remaining_minutes' => now()->diffInMinutes($existingQR->expires_at, false),
                    ],
                    'message' => 'Ya tienes un QR activo',
                ]);
            } catch (\Exception $e) {
                // Si hay error al decodificar, eliminar el QR corrupto
                DB::table('article_qr_codes')->where('id', $existingQR->id)->delete();
            }
        }

        try {
            // Crear payload JWT
            $expiresAt = now()->addMinutes(30);
            $payload = [
                'iss' => config('app.url'), // Emisor
                'sub' => 'attendance_qr', // Asunto
                'article_id' => $article->id,
                'student_id' => $student->id,
                'article_title' => $article->title,
                'iat' => now()->timestamp, // Emitido en
                'exp' => $expiresAt->timestamp, // Expira en
                'jti' => uniqid('qr_', true), // ID único del JWT
            ];

            // Firmar JWT con la clave de la aplicación
            $jwtToken = JWT::encode($payload, config('app.key'), 'HS256');

            // Guardar en la base de datos
            DB::table('article_qr_codes')->insert([
                'article_id' => $article->id,
                'qr_token' => $jwtToken,
                'expires_at' => $expiresAt,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // 🔔 Evento Pusher: QR Generado
            $this->notifyQRGenerated($article->id, $article->title);

            return response()->json([
                'success' => true,
                'data' => [
                    'qr_token' => $jwtToken,
                    'article_id' => $article->id,
                    'article_title' => $article->title,
                    'expires_at' => $expiresAt->format('Y-m-d H:i:s'),
                    'remaining_minutes' => 30,
                ],
                'message' => 'QR generado exitosamente',
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al generar QR',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // ========== MÉTODO MEJORADO: ESCANEAR QR CON VALIDACIÓN JWT ==========

    /**
     * Escanear QR y validar JWT antes de registrar asistencia
     * Solo para oyentes
     */
    public function scanQR(Request $request)
    {
        $request->validate([
            'qr_token' => 'required|string',
        ]);

        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student || $student->type !== 'oyente') {
            return response()->json([
                'success' => false,
                'message' => 'Solo los oyentes pueden escanear QR',
            ], 403);
        }

        try {
            // 1. DECODIFICAR Y VALIDAR JWT
            $decoded = JWT::decode(
                $request->qr_token,
                new Key(config('app.key'), 'HS256')
            );

            // 2. VERIFICAR QUE EL JWT NO HA EXPIRADO
            if ($decoded->exp < now()->timestamp) {
                return response()->json([
                    'success' => false,
                    'message' => 'El QR ha expirado',
                ], 422);
            }

            // 3. VERIFICAR QUE EL QR EXISTE EN LA BD
            $qrRecord = DB::table('article_qr_codes')
                ->where('qr_token', $request->qr_token)
                ->where('article_id', $decoded->article_id)
                ->where('expires_at', '>', now())
                ->first();

            if (!$qrRecord) {
                return response()->json([
                    'success' => false,
                    'message' => 'QR inválido o expirado',
                ], 404);
            }

            // 4. OBTENER EL ARTÍCULO
            $article = Article::with('student')->find($decoded->article_id);

            if (!$article) {
                return response()->json([
                    'success' => false,
                    'message' => 'Artículo no encontrado',
                ], 404);
            }

            // 5. VERIFICAR QUE NO HA ASISTIDO PREVIAMENTE
            $existingAttendance = Attendance::where('student_id', $student->id)
                ->where('article_id', $article->id)
                ->first();

            if ($existingAttendance) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ya has registrado tu asistencia a este artículo',
                ], 422);
            }

            // 6. REGISTRAR ASISTENCIA
            DB::beginTransaction();

            $attendance = Attendance::create([
                'article_id' => $article->id,
                'student_id' => $student->id,
            ]);

            DB::commit();

            // 7. 🔔 NOTIFICAR EN TIEMPO REAL CON PUSHER
            $this->notifyAttendanceRegistered(
                $article->id,
                $student->fullName(),
                $student->student_code
            );

            return response()->json([
                'success' => true,
                'message' => '✅ Asistencia registrada exitosamente',
                'data' => [
                    'attendance_id' => $attendance->id,
                    'article' => [
                        'id' => $article->id,
                        'title' => $article->title,
                        'type' => $article->type,
                    ],
                    'ponente' => [
                        'full_name' => $article->student->fullName(),
                    ],
                    'attended_at' => $attendance->created_at->format('Y-m-d H:i:s'),
                ],
            ], 201);

        } catch (\Firebase\JWT\ExpiredException $e) {
            return response()->json([
                'success' => false,
                'message' => 'El QR ha expirado',
            ], 422);

        } catch (\Firebase\JWT\SignatureInvalidException $e) {
            return response()->json([
                'success' => false,
                'message' => 'QR inválido o manipulado',
            ], 422);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar asistencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // ========== PUSHER: NOTIFICACIONES EN TIEMPO REAL ==========

    /**
     * Notificar que se generó un QR
     */
private function notifyQRGenerated($articleId, $articleTitle)
{
    try {
        // Verificar si Pusher está configurado
        if (config('broadcasting.default') !== 'pusher') {
            \Log::info('QR generado para artículo: ' . $articleTitle);
            return;
        }

        $pusher = new Pusher(
            config('broadcasting.connections.pusher.key'),
            config('broadcasting.connections.pusher.secret'),
            config('broadcasting.connections.pusher.app_id'),
            [
                'cluster' => config('broadcasting.connections.pusher.options.cluster'),
                'useTLS' => true,
            ]
        );

        $pusher->trigger(
            'article.' . $articleId,
            'qr.generated',
            [
                'message' => 'QR de asistencia generado',
                'article_title' => $articleTitle,
                'timestamp' => now()->toIso8601String(),
            ]
        );
    } catch (\Exception $e) {
        \Log::error('Error al enviar notificación Pusher: ' . $e->getMessage());
    }
}

    /**
     * Notificar que alguien registró asistencia
     */
    private function notifyAttendanceRegistered($articleId, $studentName, $studentCode)
    {
        try {
            $pusher = new Pusher(
                config('broadcasting.connections.pusher.key'),
                config('broadcasting.connections.pusher.secret'),
                config('broadcasting.connections.pusher.app_id'),
                [
                    'cluster' => config('broadcasting.connections.pusher.options.cluster'),
                    'useTLS' => true,
                ]
            );

            // Contar asistentes actuales
            $totalAttendees = Attendance::where('article_id', $articleId)->count();

            $pusher->trigger(
                'article.' . $articleId,
                'attendance.registered',
                [
                    'message' => 'Nueva asistencia registrada',
                    'student_name' => $studentName,
                    'student_code' => $studentCode,
                    'total_attendees' => $totalAttendees,
                    'timestamp' => now()->toIso8601String(),
                ]
            );
        } catch (\Exception $e) {
            \Log::error('Error al enviar notificación Pusher: ' . $e->getMessage());
        }
    }

    /**
     * Ver asistentes en tiempo real (para el ponente)
     */
    public function myAttendees(Request $request)
    {
        $user = $request->user();
        $student = Student::where('user_id', $user->id)->first();

        if (!$student || $student->type !== 'ponente') {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $article = Article::where('student_id', $student->id)->first();

        if (!$article) {
            return response()->json([
                'success' => false,
                'message' => 'No tienes un artículo asignado',
            ], 404);
        }

        $attendances = Attendance::where('article_id', $article->id)
            ->with('student')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($attendance) {
                return [
                    'id' => $attendance->id,
                    'student' => [
                        'full_name' => $attendance->student->fullName(),
                        'student_code' => $attendance->student->student_code,
                        'dni' => $attendance->student->dni,
                    ],
                    'attended_at' => $attendance->created_at->format('Y-m-d H:i:s'),
                    'attended_at_human' => $attendance->created_at->diffForHumans(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'total_attendees' => $attendances->count(),
                'attendees' => $attendances,
                'pusher_channel' => 'article.' . $article->id,
            ],
        ]);
    }
}

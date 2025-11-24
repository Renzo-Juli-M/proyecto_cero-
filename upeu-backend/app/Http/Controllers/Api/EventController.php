<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Period;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class EventController extends Controller
{
    /**
     * Listar todos los eventos
     */
    public function index(Request $request)
    {
        try {
            $query = Event::with(['period', 'students']);

            // Filtro por periodo
            if ($request->has('period_id')) {
                $query->where('period_id', $request->period_id);
            }

            // Filtro por estado
            if ($request->has('is_active')) {
                $query->where('is_active', $request->is_active);
            }

            // Ordenar
            $query->orderBy('start_date', 'desc');

            $events = $query->get()->map(function ($event) {
                return [
                    'id' => $event->id,
                    'name' => $event->name,
                    'description' => $event->description,
                    'start_date' => $event->start_date->format('Y-m-d'),
                    'end_date' => $event->end_date->format('Y-m-d'),
                    'location' => $event->location,
                    'is_active' => $event->is_active,
                    'is_current' => $event->isCurrent(),
                    'period' => [
                        'id' => $event->period->id,
                        'name' => $event->period->name,
                    ],
                    'duration_days' => $event->getDurationInDays(),
                    'students_count' => $event->students->count(),
                    'ponentes_count' => $event->getPonentesCount(),
                    'oyentes_count' => $event->getOyentesCount(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $events,
            ]);
        } catch (\Exception $e) {
            Log::error('Error al listar eventos', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener eventos',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Crear un nuevo evento
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'period_id' => 'required|exists:periods,id',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'location' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ], [
            'period_id.required' => 'El periodo es obligatorio',
            'period_id.exists' => 'El periodo seleccionado no existe',
            'name.required' => 'El nombre del evento es obligatorio',
            'start_date.required' => 'La fecha de inicio es obligatoria',
            'end_date.required' => 'La fecha de fin es obligatoria',
            'end_date.after' => 'La fecha de fin debe ser posterior a la fecha de inicio',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Verificar que las fechas estén dentro del periodo
            $period = Period::findOrFail($request->period_id);

            if ($request->start_date < $period->start_date || $request->end_date > $period->end_date) {
                return response()->json([
                    'success' => false,
                    'message' => 'Las fechas del evento deben estar dentro del periodo seleccionado',
                ], 422);
            }

            DB::beginTransaction();

            $event = Event::create([
                'period_id' => $request->period_id,
                'name' => $request->name,
                'description' => $request->description,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'location' => $request->location,
                'is_active' => $request->is_active ?? true,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Evento creado exitosamente',
                'data' => $event->load('period'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error al crear evento', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al crear evento',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mostrar un evento específico
     */
    public function show($id)
    {
        try {
            $event = Event::with(['period', 'students'])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $event->id,
                    'name' => $event->name,
                    'description' => $event->description,
                    'start_date' => $event->start_date->format('Y-m-d'),
                    'end_date' => $event->end_date->format('Y-m-d'),
                    'location' => $event->location,
                    'is_active' => $event->is_active,
                    'is_current' => $event->isCurrent(),
                    'period' => [
                        'id' => $event->period->id,
                        'name' => $event->period->name,
                        'start_date' => $event->period->start_date->format('Y-m-d'),
                        'end_date' => $event->period->end_date->format('Y-m-d'),
                    ],
                    'duration_days' => $event->getDurationInDays(),
                    'students_count' => $event->students->count(),
                    'ponentes_count' => $event->getPonentesCount(),
                    'oyentes_count' => $event->getOyentesCount(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Evento no encontrado',
            ], 404);
        }
    }

    /**
     * Actualizar un evento
     */
    public function update(Request $request, $id)
    {
        $event = Event::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'period_id' => 'required|exists:periods,id',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'location' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Verificar que las fechas estén dentro del periodo
            $period = Period::findOrFail($request->period_id);

            if ($request->start_date < $period->start_date || $request->end_date > $period->end_date) {
                return response()->json([
                    'success' => false,
                    'message' => 'Las fechas del evento deben estar dentro del periodo seleccionado',
                ], 422);
            }

            DB::beginTransaction();

            $event->update([
                'period_id' => $request->period_id,
                'name' => $request->name,
                'description' => $request->description,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'location' => $request->location,
                'is_active' => $request->is_active ?? $event->is_active,
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Evento actualizado exitosamente',
                'data' => $event->fresh()->load('period'),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error al actualizar evento', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar evento',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Eliminar un evento
     */
    public function destroy($id)
    {
        try {
            $event = Event::findOrFail($id);

            // Verificar si tiene estudiantes
            if ($event->students()->count() > 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se puede eliminar el evento porque tiene estudiantes asociados',
                ], 422);
            }

            DB::beginTransaction();
            $event->delete();
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Evento eliminado exitosamente',
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error al eliminar evento', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar evento',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtener eventos por periodo
     */
    public function getByPeriod($periodId)
    {
        try {
            $events = Event::where('period_id', $periodId)
                ->orderBy('start_date', 'asc')
                ->get()
                ->map(function ($event) {
                    return [
                        'id' => $event->id,
                        'name' => $event->name,
                        'start_date' => $event->start_date->format('Y-m-d'),
                        'end_date' => $event->end_date->format('Y-m-d'),
                        'location' => $event->location,
                        'is_active' => $event->is_active,
                        'students_count' => $event->getStudentsCount(),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $events,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener eventos',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

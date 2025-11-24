<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Period;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class PeriodController extends Controller
{
    /**
     * Listar todos los periodos
     */
    public function index(Request $request)
    {
        try {
            $query = Period::with(['events', 'students']);

            // Filtros
            if ($request->has('is_active')) {
                $query->where('is_active', $request->is_active);
            }

            if ($request->has('year')) {
                $query->whereYear('start_date', $request->year);
            }

            // Ordenar
            $query->orderBy('start_date', 'desc');

            $periods = $query->get()->map(function ($period) {
                return [
                    'id' => $period->id,
                    'name' => $period->name,
                    'start_date' => $period->start_date->format('Y-m-d'),
                    'end_date' => $period->end_date->format('Y-m-d'),
                    'is_active' => $period->is_active,
                    'is_current' => $period->isCurrent(),
                    'description' => $period->description,
                    'duration_days' => $period->getDurationInDays(),
                    'events_count' => $period->events->count(),
                    'students_count' => $period->students->count(),
                    'created_at' => $period->created_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $periods,
            ]);
        } catch (\Exception $e) {
            Log::error('Error al listar periodos', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener periodos',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Crear un nuevo periodo
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:20|unique:periods,name',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ], [
            'name.required' => 'El nombre del periodo es obligatorio',
            'name.unique' => 'Ya existe un periodo con ese nombre',
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
            DB::beginTransaction();

            $period = Period::create([
                'name' => $request->name,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'description' => $request->description,
                'is_active' => $request->is_active ?? false,
            ]);

            // Si se marca como activo, desactivar los demás
            if ($period->is_active) {
                Period::where('id', '!=', $period->id)->update(['is_active' => false]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Periodo creado exitosamente',
                'data' => $period,
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error al crear periodo', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al crear periodo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mostrar un periodo específico
     */
    public function show($id)
    {
        try {
            $period = Period::with(['events', 'students'])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $period->id,
                    'name' => $period->name,
                    'start_date' => $period->start_date->format('Y-m-d'),
                    'end_date' => $period->end_date->format('Y-m-d'),
                    'is_active' => $period->is_active,
                    'is_current' => $period->isCurrent(),
                    'description' => $period->description,
                    'duration_days' => $period->getDurationInDays(),
                    'events' => $period->events->map(function ($event) {
                        return [
                            'id' => $event->id,
                            'name' => $event->name,
                            'start_date' => $event->start_date->format('Y-m-d'),
                            'end_date' => $event->end_date->format('Y-m-d'),
                            'is_active' => $event->is_active,
                        ];
                    }),
                    'students_count' => $period->students->count(),
                    'ponentes_count' => $period->students->where('type', 'ponente')->count(),
                    'oyentes_count' => $period->students->where('type', 'oyente')->count(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Periodo no encontrado',
            ], 404);
        }
    }

    /**
     * Actualizar un periodo
     */
    public function update(Request $request, $id)
    {
        $period = Period::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:20|unique:periods,name,' . $id,
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'description' => 'nullable|string',
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
            DB::beginTransaction();

            $period->update([
                'name' => $request->name,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'description' => $request->description,
                'is_active' => $request->is_active ?? $period->is_active,
            ]);

            // Si se activa, desactivar los demás
            if ($request->is_active && !$period->is_active) {
                Period::where('id', '!=', $period->id)->update(['is_active' => false]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Periodo actualizado exitosamente',
                'data' => $period->fresh(),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error al actualizar periodo', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar periodo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Eliminar un periodo
     */
    public function destroy($id)
    {
        try {
            $period = Period::findOrFail($id);

            // Verificar si tiene estudiantes
            if ($period->students()->count() > 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se puede eliminar el periodo porque tiene estudiantes asociados',
                ], 422);
            }

            DB::beginTransaction();
            $period->delete();
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Periodo eliminado exitosamente',
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error al eliminar periodo', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar periodo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Activar un periodo
     */
    public function activate($id)
    {
        try {
            $period = Period::findOrFail($id);

            DB::beginTransaction();
            $period->activate();
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Periodo activado exitosamente',
                'data' => $period->fresh(),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al activar periodo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtener el periodo activo
     */
    public function getActive()
    {
        try {
            $period = Period::active()->with(['events'])->first();

            if (!$period) {
                return response()->json([
                    'success' => false,
                    'message' => 'No hay periodo activo',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $period,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener periodo activo',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

<?php

namespace App\Imports;

use App\Models\Student;
use App\Models\User;
use App\Models\Period;
use App\Models\Event;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;

class StudentsImport implements ToCollection, WithHeadingRow, WithBatchInserts, WithChunkReading
{
    protected $errors = [];
    protected $imported = 0;
    protected $skipped = 0;
    protected $warnings = [];
    protected $periodId;
    protected $eventId;

    /**
     * Constructor para recibir periodo y evento seleccionados
     */
    public function __construct($periodId = null, $eventId = null)
    {
        $this->periodId = $periodId;
        $this->eventId = $eventId;
    }

    /**
     * Procesar la colección de filas del Excel
     */
    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            $rowNumber = $index + 2; // +2 porque Excel empieza en 1 y hay header

            try {
                // Normalizar keys (convertir a lowercase y quitar espacios)
                $normalizedRow = $this->normalizeRow($row);

                // Validar estructura básica
                if (empty($normalizedRow)) {
                    $this->skipped++;
                    continue;
                }

                // Validar datos
                $validator = $this->validateRow($normalizedRow, $rowNumber);

                if ($validator->fails()) {
                    $this->errors[] = [
                        'row' => $rowNumber,
                        'data' => $this->getSafeRowData($normalizedRow),
                        'errors' => $validator->errors()->all(),
                    ];
                    continue;
                }

                // Verificar duplicados antes de insertar
                $duplicateCheck = $this->checkDuplicates($normalizedRow, $rowNumber);

                if ($duplicateCheck !== true) {
                    $this->errors[] = $duplicateCheck;
                    continue;
                }

                // Crear estudiante con transacción
                $this->createStudent($normalizedRow, $rowNumber);

            } catch (\Exception $e) {
                Log::error('Error importando estudiante', [
                    'row' => $rowNumber,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);

                $this->errors[] = [
                    'row' => $rowNumber,
                    'data' => $this->getSafeRowData($normalizedRow ?? []),
                    'errors' => ['Error inesperado: ' . $e->getMessage()],
                ];
            }
        }
    }

    /**
     * Normalizar las keys del row
     */
    protected function normalizeRow($row): array
    {
        $normalizedRow = [];

        foreach ($row as $key => $value) {
            // Convertir a lowercase y quitar espacios
            $normalizedKey = strtolower(trim($key));

            // Mapear nombres de columnas alternativos
            $keyMap = [
                'codigo' => 'codigo',
                'código' => 'codigo',
                'escuela profesional' => 'escuela_profesional',
                'escuela' => 'escuela_profesional',
                'programa estudio' => 'programa_estudio',
                'programa' => 'programa_estudio',
                'usuario' => 'username',
                'foto' => 'foto_url',
            ];

            $finalKey = $keyMap[$normalizedKey] ?? $normalizedKey;

            // Limpiar el valor
            $normalizedValue = is_string($value) ? trim($value) : $value;

            $normalizedRow[$finalKey] = $normalizedValue;
        }

        return $normalizedRow;
    }

    /**
     * Validar los datos del row
     */
    protected function validateRow(array $row, int $rowNumber)
    {
        $rules = [
            'dni' => [
                'required',
                'string',
                'regex:/^[0-9]{8}$/', // Exactamente 8 dígitos
            ],
            'codigo' => [
                'required',
                'string',
                'max:20',
            ],
            'nombres' => [
                'required',
                'string',
                'max:100',
            ],
            'apellidos' => [
                'required',
                'string',
                'max:100',
            ],
            'tipo' => [
                'required',
                'string',
                'in:ponente,oyente,Ponente,Oyente,PONENTE,OYENTE',
            ],
            'email' => [
                'required',
                'email',
                'max:255',
            ],
            // NUEVOS CAMPOS REQUERIDOS
            'sede' => [
                'required',
                'string',
                'max:100',
            ],
            'escuela_profesional' => [
                'required',
                'string',
                'max:150',
            ],
            'programa_estudio' => [
                'required',
                'string',
                'max:150',
            ],
            'ciclo' => [
                'required',
                'string',
                'max:20',
            ],
            'grupo' => [
                'required',
                'string',
                'max:20',
            ],
            'username' => [
                'required',
                'string',
                'max:50',
                'regex:/^[a-zA-Z0-9._-]+$/', // Solo alfanuméricos, puntos, guiones y guiones bajos
            ],
            // CAMPO OPCIONAL
            'foto_url' => [
                'nullable',
                'string',
                'max:500',
                'url', // Validar que sea una URL válida
            ],
        ];

        $messages = [
            'dni.required' => 'El DNI es obligatorio',
            'dni.regex' => 'El DNI debe tener exactamente 8 dígitos numéricos',
            'codigo.required' => 'El código de estudiante es obligatorio',
            'nombres.required' => 'Los nombres son obligatorios',
            'apellidos.required' => 'Los apellidos son obligatorios',
            'tipo.required' => 'El tipo de estudiante es obligatorio',
            'tipo.in' => 'El tipo debe ser "ponente" u "oyente"',
            'email.required' => 'El email es obligatorio',
            'email.email' => 'El email debe ser válido',
            'sede.required' => 'La sede es obligatoria',
            'escuela_profesional.required' => 'La escuela profesional es obligatoria',
            'programa_estudio.required' => 'El programa de estudio es obligatorio',
            'ciclo.required' => 'El ciclo es obligatorio',
            'grupo.required' => 'El grupo es obligatorio',
            'username.required' => 'El usuario es obligatorio',
            'username.regex' => 'El usuario solo puede contener letras, números, puntos, guiones y guiones bajos',
            'foto_url.url' => 'La foto debe ser una URL válida',
        ];

        return Validator::make($row, $rules, $messages);
    }

    /**
     * Verificar duplicados
     */
    protected function checkDuplicates(array $row, int $rowNumber)
    {
        // Verificar DNI
        $existingStudent = Student::where('dni', $row['dni'])->first();
        if ($existingStudent) {
            return [
                'row' => $rowNumber,
                'data' => $this->getSafeRowData($row),
                'errors' => ["El estudiante con DNI {$row['dni']} ya existe en la base de datos"],
            ];
        }

        // Verificar código de estudiante
        $existingCode = Student::where('student_code', $row['codigo'])->first();
        if ($existingCode) {
            return [
                'row' => $rowNumber,
                'data' => $this->getSafeRowData($row),
                'errors' => ["El código de estudiante {$row['codigo']} ya está en uso"],
            ];
        }

        // Verificar email
        $existingEmail = User::where('email', strtolower($row['email']))->first();
        if ($existingEmail) {
            return [
                'row' => $rowNumber,
                'data' => $this->getSafeRowData($row),
                'errors' => ["El email {$row['email']} ya está registrado"],
            ];
        }

        // Verificar username en users
        $existingUsername = User::where('username', strtolower($row['username']))->first();
        if ($existingUsername) {
            return [
                'row' => $rowNumber,
                'data' => $this->getSafeRowData($row),
                'errors' => ["El username {$row['username']} ya está en uso"],
            ];
        }

        // Verificar username en students (por si acaso)
        $existingStudentUsername = Student::where('username', strtolower($row['username']))->first();
        if ($existingStudentUsername) {
            return [
                'row' => $rowNumber,
                'data' => $this->getSafeRowData($row),
                'errors' => ["El username {$row['username']} ya está en uso por otro estudiante"],
            ];
        }

        return true;
    }

    /**
     * Crear estudiante con transacción
     */
    protected function createStudent(array $row, int $rowNumber): void
    {
        DB::beginTransaction();

        try {
            // Crear usuario
            $user = User::create([
                'email' => strtolower($row['email']),
                'username' => strtolower($row['username']),
                'password' => Hash::make($row['dni']), // Password por defecto es el DNI
                'role' => 'student',
            ]);

            // Preparar datos del estudiante
            $studentData = [
                'user_id' => $user->id,
                'dni' => $row['dni'],
                'student_code' => $row['codigo'],
                'first_name' => ucwords(strtolower($row['nombres'])),
                'last_name' => ucwords(strtolower($row['apellidos'])),
                'type' => strtolower($row['tipo']),
                'sede' => $row['sede'],
                'escuela_profesional' => $row['escuela_profesional'],
                'programa_estudio' => $row['programa_estudio'],
                'ciclo' => $row['ciclo'],
                'grupo' => $row['grupo'],
                'username' => strtolower($row['username']),
                'foto_url' => $row['foto_url'] ?? null,
            ];

            // Agregar periodo y evento si fueron seleccionados
            if ($this->periodId) {
                $studentData['period_id'] = $this->periodId;
            }
            if ($this->eventId) {
                $studentData['event_id'] = $this->eventId;
            }

            // Crear estudiante
            Student::create($studentData);

            DB::commit();
            $this->imported++;

            Log::info('Estudiante importado exitosamente', [
                'row' => $rowNumber,
                'dni' => $row['dni'],
                'email' => $row['email'],
                'username' => $row['username'],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('Error al crear estudiante', [
                'row' => $rowNumber,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    /**
     * Obtener datos seguros del row para mostrar en errores
     */
    protected function getSafeRowData(array $row): array
    {
        return [
            'dni' => $row['dni'] ?? 'N/A',
            'codigo' => $row['codigo'] ?? 'N/A',
            'nombres' => $row['nombres'] ?? 'N/A',
            'apellidos' => $row['apellidos'] ?? 'N/A',
            'tipo' => $row['tipo'] ?? 'N/A',
            'email' => $row['email'] ?? 'N/A',
            'sede' => $row['sede'] ?? 'N/A',
            'escuela_profesional' => $row['escuela_profesional'] ?? 'N/A',
            'programa_estudio' => $row['programa_estudio'] ?? 'N/A',
            'ciclo' => $row['ciclo'] ?? 'N/A',
            'grupo' => $row['grupo'] ?? 'N/A',
            'username' => $row['username'] ?? 'N/A',
            'foto_url' => $row['foto_url'] ?? 'N/A',
        ];
    }

    /**
     * Obtener errores
     */
    public function getErrors(): array
    {
        return $this->errors;
    }

    /**
     * Obtener cantidad de registros importados
     */
    public function getImportedCount(): int
    {
        return $this->imported;
    }

    /**
     * Obtener cantidad de registros omitidos
     */
    public function getSkippedCount(): int
    {
        return $this->skipped;
    }

    /**
     * Obtener advertencias
     */
    public function getWarnings(): array
    {
        return $this->warnings;
    }

    /**
     * Obtener resumen de la importación
     */
    public function getSummary(): array
    {
        return [
            'imported' => $this->imported,
            'errors' => count($this->errors),
            'skipped' => $this->skipped,
            'total_processed' => $this->imported + count($this->errors) + $this->skipped,
            'period_id' => $this->periodId,
            'event_id' => $this->eventId,
        ];
    }

    /**
     * Tamaño del batch para inserciones
     */
    public function batchSize(): int
    {
        return 100;
    }

    /**
     * Tamaño del chunk para lectura
     */
    public function chunkSize(): int
    {
        return 100;
    }
}

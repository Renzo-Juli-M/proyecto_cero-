<?php

namespace App\Imports;

use App\Models\Juror;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class JurorsImport implements ToCollection, WithHeadingRow
{
    protected $errors = [];
    protected $imported = 0;

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            try {
                // Validar datos
                $validator = Validator::make($row->toArray(), [
                    'dni' => 'required|string|size:8',
                    'usuario' => 'required|string',
                    'nombres' => 'required|string',
                    'apellidos' => 'required|string',
                    'email' => 'required|email',
                    'especialidad' => 'nullable|string',
                ]);

                if ($validator->fails()) {
                    $this->errors[] = [
                        'row' => $index + 2,
                        'errors' => $validator->errors()->all(),
                    ];
                    continue;
                }

                // Verificar si ya existe
                $existingJuror = Juror::where('dni', $row['dni'])->first();
                if ($existingJuror) {
                    $this->errors[] = [
                        'row' => $index + 2,
                        'errors' => ["El jurado con DNI {$row['dni']} ya existe"],
                    ];
                    continue;
                }

                // Crear usuario
                $user = User::create([
                    'email' => $row['email'],
                    'password' => Hash::make($row['dni']), // Password por defecto es el DNI
                    'role' => 'juror',
                ]);

                // Crear jurado
                Juror::create([
                    'user_id' => $user->id,
                    'dni' => $row['dni'],
                    'username' => $row['usuario'],
                    'first_name' => $row['nombres'],
                    'last_name' => $row['apellidos'],
                    'specialty' => $row['especialidad'] ?? null,
                ]);

                $this->imported++;
            } catch (\Exception $e) {
                $this->errors[] = [
                    'row' => $index + 2,
                    'errors' => [$e->getMessage()],
                ];
            }
        }
    }

    public function getErrors()
    {
        return $this->errors;
    }

    public function getImportedCount()
    {
        return $this->imported;
    }
}

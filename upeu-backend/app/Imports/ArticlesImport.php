<?php

namespace App\Imports;

use App\Models\Article;
use App\Models\Student;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class ArticlesImport implements ToCollection, WithHeadingRow
{
    protected $errors = [];
    protected $imported = 0;

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            try {
                // Normalizar keys
                $normalizedRow = [];
                foreach ($row as $key => $value) {
                    $normalizedKey = strtolower(trim(str_replace(' ', '_', $key)));
                    $normalizedRow[$normalizedKey] = $value;
                }

                // Mapeo flexible de columnas
                $dni_ponente = $this->getField($normalizedRow, ['dni_ponente', 'dni', 'codigo', 'código', 'dni_alumno', 'codigo_alumno', 'student_dni']);
                $titulo = $this->getField($normalizedRow, ['titulo', 'título', 'title', 'nombre_articulo', 'articulo']);
                $descripcion = $this->getField($normalizedRow, ['descripcion', 'descripción', 'description', 'resumen']);
                $tipo = $this->getField($normalizedRow, ['tipo', 'type', 'tipo_articulo']);
                $fecha = $this->getField($normalizedRow, ['fecha_presentacion', 'fecha_presentación', 'fecha', 'presentation_date']);
                $hora = $this->getField($normalizedRow, ['hora_presentacion', 'hora_presentación', 'hora', 'presentation_time']);
                $turno = $this->getField($normalizedRow, ['turno', 'shift']);

                // Asegurar DNI de 8 dígitos
                if (!empty($dni_ponente)) {
                    $dni_ponente = str_pad(trim($dni_ponente), 8, '0', STR_PAD_LEFT);
                }

                // Normalizar tipo de artículo
                $tipo = $this->normalizeArticleType($tipo);

                // Normalizar turno
                if (!empty($turno)) {
                    $turno = strtolower(trim($turno));
                    if (!in_array($turno, ['mañana', 'tarde'])) {
                        $turno = null;
                    }
                }

                // Validar datos
                $validator = Validator::make([
                    'dni_ponente' => $dni_ponente,
                    'titulo' => $titulo,
                    'tipo' => $tipo,
                ], [
                    'dni_ponente' => 'required|string|size:8',
                    'titulo' => 'required|string',
                    'tipo' => 'required|in:revision_sistematica,empirico,teorico,estudio_caso',
                ], [
                    'dni_ponente.required' => 'El DNI del ponente es requerido',
                    'dni_ponente.size' => 'El DNI debe tener 8 dígitos',
                    'titulo.required' => 'El título es requerido',
                    'tipo.required' => 'El tipo de artículo es requerido',
                    'tipo.in' => 'El tipo debe ser: revision_sistematica, empirico, teorico, estudio_caso',
                ]);

                if ($validator->fails()) {
                    $this->errors[] = [
                        'row' => $index + 2,
                        'errors' => $validator->errors()->all(),
                    ];
                    continue;
                }

                // Buscar estudiante ponente
                $student = Student::where('dni', $dni_ponente)
                    ->where('type', 'ponente')
                    ->first();

                if (!$student) {
                    $this->errors[] = [
                        'row' => $index + 2,
                        'errors' => ["No se encontró un ponente con DNI/código $dni_ponente"],
                    ];
                    continue;
                }

                // Verificar si el ponente ya tiene un artículo
                $existingArticle = Article::where('student_id', $student->id)->first();
                if ($existingArticle) {
                    $this->errors[] = [
                        'row' => $index + 2,
                        'errors' => ["El ponente {$student->fullName()} ya tiene un artículo asignado"],
                    ];
                    continue;
                }

                // Crear artículo
                Article::create([
                    'student_id' => $student->id,
                    'title' => $titulo,
                    'description' => $descripcion,
                    'type' => $tipo,
                    'presentation_date' => $fecha,
                    'presentation_time' => $hora,
                    'shift' => $turno,
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

    /**
     * Buscar campo en el array normalizado
     */
    private function getField($row, $possibleKeys)
    {
        foreach ($possibleKeys as $key) {
            $normalizedKey = strtolower(trim(str_replace(' ', '_', $key)));
            if (isset($row[$normalizedKey]) && !empty($row[$normalizedKey])) {
                return trim($row[$normalizedKey]);
            }
        }
        return null;
    }

    /**
     * Normalizar tipo de artículo
     */
    private function normalizeArticleType($tipo)
    {
        if (empty($tipo)) {
            return null;
        }

        $tipo = strtolower(trim($tipo));

        $typeMap = [
            'revision_sistematica' => 'revision_sistematica',
            'revision sistematica' => 'revision_sistematica',
            'revision' => 'revision_sistematica',
            'revisión' => 'revision_sistematica',
            'sistematica' => 'revision_sistematica',
            'sistemática' => 'revision_sistematica',
            'empirico' => 'empirico',
            'empírico' => 'empirico',
            'experimental' => 'empirico',
            'teorico' => 'teorico',
            'teórico' => 'teorico',
            'teoria' => 'teorico',
            'teoría' => 'teorico',
            'estudio_caso' => 'estudio_caso',
            'estudio de caso' => 'estudio_caso',
            'caso' => 'estudio_caso',
            'estudio' => 'estudio_caso',
        ];

        return $typeMap[$tipo] ?? $tipo;
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

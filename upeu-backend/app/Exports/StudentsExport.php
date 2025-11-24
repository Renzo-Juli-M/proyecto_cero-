<?php

namespace App\Exports;

use App\Models\Student;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class StudentsExport implements FromCollection, WithHeadings, WithMapping, WithStyles
{
    public function collection()
    {
        return Student::with('user')->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'DNI',
            'Código',
            'Nombres',
            'Apellidos',
            'Tipo',
            'Email',
            'Fecha de Registro',
        ];
    }

    public function map($student): array
    {
        return [
            $student->id,
            $student->dni,
            $student->student_code,
            $student->first_name,
            $student->last_name,
            ucfirst($student->type),
            $student->user->email,
            $student->created_at->format('Y-m-d H:i:s'),
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}

<?php

namespace App\Exports;

use App\Models\Juror;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class JurorsExport implements FromCollection, WithHeadings, WithMapping, WithStyles
{
    public function collection()
    {
        return Juror::with(['user', 'articles'])->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'DNI',
            'Usuario',
            'Nombres',
            'Apellidos',
            'Especialidad',
            'Email',
            'Artículos Asignados',
            'Evaluaciones Realizadas',
        ];
    }

    public function map($juror): array
    {
        return [
            $juror->id,
            $juror->dni,
            $juror->username,
            $juror->first_name,
            $juror->last_name,
            $juror->specialty ?? 'N/A',
            $juror->user->email,
            $juror->articles()->count(),
            $juror->evaluations()->count(),
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}

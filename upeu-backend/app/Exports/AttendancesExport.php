<?php

namespace App\Exports;

use App\Models\Attendance;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class AttendancesExport implements FromCollection, WithHeadings, WithMapping, WithStyles
{
    public function collection()
    {
        return Attendance::with(['article.student', 'student'])->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'Artículo',
            'Ponente',
            'Oyente',
            'DNI Oyente',
            'Fecha/Hora Escaneo',
        ];
    }

    public function map($attendance): array
    {
        return [
            $attendance->id,
            $attendance->article->title,
            $attendance->article->student->fullName(),
            $attendance->student->fullName(),
            $attendance->student->dni,
            $attendance->scanned_at->format('Y-m-d H:i:s'),
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}

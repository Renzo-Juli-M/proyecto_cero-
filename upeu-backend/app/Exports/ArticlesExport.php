<?php

namespace App\Exports;

use App\Models\Article;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ArticlesExport implements FromCollection, WithHeadings, WithMapping, WithStyles
{
    public function collection()
    {
        return Article::with(['student', 'jurors', 'evaluations'])->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'Título',
            'Ponente',
            'DNI Ponente',
            'Tipo',
            'Fecha Presentación',
            'Hora',
            'Turno',
            'Jurados Asignados',
            'Evaluaciones',
            'Promedio',
            'Asistencias',
        ];
    }

    public function map($article): array
    {
        return [
            $article->id,
            $article->title,
            $article->student->fullName(),
            $article->student->dni,
            ucfirst(str_replace('_', ' ', $article->type)),
            $article->presentation_date?->format('Y-m-d') ?? 'N/A',
            $article->presentation_time ?? 'N/A',
            $article->shift ?? 'N/A',
            $article->jurors()->count(),
            $article->evaluations()->count(),
            round($article->averageScore(), 2) ?? 'N/A',
            $article->totalAttendances(),
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}

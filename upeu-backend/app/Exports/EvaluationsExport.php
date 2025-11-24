<?php

namespace App\Exports;

use App\Models\Evaluation;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class EvaluationsExport implements FromCollection, WithHeadings, WithMapping, WithStyles
{
    public function collection()
    {
        return Evaluation::with(['article.student', 'juror'])->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'Artículo',
            'Ponente',
            'Jurado',
            'Introducción',
            'Metodología',
            'Desarrollo',
            'Conclusiones',
            'Presentación',
            'Promedio',
            'Comentarios',
            'Fecha Evaluación',
        ];
    }

    public function map($evaluation): array
    {
        return [
            $evaluation->id,
            $evaluation->article->title,
            $evaluation->article->student->fullName(),
            $evaluation->juror->fullName(),
            $evaluation->introduccion,
            $evaluation->metodologia,
            $evaluation->desarrollo,
            $evaluation->conclusiones,
            $evaluation->presentacion,
            $evaluation->promedio,
            $evaluation->comentarios ?? 'Sin comentarios',
            $evaluation->created_at->format('Y-m-d H:i:s'),
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}

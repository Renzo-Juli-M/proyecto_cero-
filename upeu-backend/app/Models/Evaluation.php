<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Evaluation extends Model
{
    use HasFactory;

    protected $fillable = [
        'article_id',
        'juror_id',
        'introduccion',
        'metodologia',
        'desarrollo',
        'conclusiones',
        'presentacion',
        'promedio',
        'comentarios',
    ];

    protected $casts = [
        'introduccion' => 'decimal:2',
        'metodologia' => 'decimal:2',
        'desarrollo' => 'decimal:2',
        'conclusiones' => 'decimal:2',
        'presentacion' => 'decimal:2',
        'promedio' => 'decimal:2',
    ];

    // Relaciones
    public function article()
    {
        return $this->belongsTo(Article::class);
    }

    public function juror()
    {
        return $this->belongsTo(Juror::class);
    }

    // Calcular promedio automáticamente
    public function calculateAverage()
    {
        $this->promedio = (
            $this->introduccion +
            $this->metodologia +
            $this->desarrollo +
            $this->conclusiones +
            $this->presentacion
        ) / 5;

        return $this->promedio;
    }
}

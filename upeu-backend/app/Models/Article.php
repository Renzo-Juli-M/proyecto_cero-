<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;

class Article extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'title',
        'description',
        'type',
        'presentation_date',
        'presentation_time',
        'shift',
    ];

    protected $casts = [
        'presentation_date' => 'date',
        'presentation_time' => 'datetime',
    ];

    // Relaciones
    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function jurors()
    {
        return $this->belongsToMany(Juror::class, 'article_juror')
                    ->withTimestamps();
    }

    public function evaluations()
    {
        return $this->hasMany(Evaluation::class);
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    public function qrCodes()
    {
        return $this->hasMany(ArticleQRCode::class);
    }

    // Scopes
    public function scopeByType(Builder $query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeByShift(Builder $query, $shift)
    {
        return $query->where('shift', $shift);
    }

    public function scopeWithFullyAssignedJurors(Builder $query)
    {
        return $query->has('jurors', '>=', 2);
    }

    public function scopeEvaluated(Builder $query)
    {
        return $query->has('evaluations');
    }

    public function scopePendingEvaluation(Builder $query)
    {
        return $query->doesntHave('evaluations');
    }

    public function scopeByPonente(Builder $query, $studentId)
    {
        return $query->where('student_id', $studentId);
    }

    public function scopeUpcoming(Builder $query)
    {
        return $query->where('presentation_date', '>=', now()->toDateString())
                    ->orderBy('presentation_date')
                    ->orderBy('presentation_time');
    }

    public function scopeSearch(Builder $query, $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('title', 'like', "%{$search}%")
              ->orWhere('description', 'like', "%{$search}%")
              ->orWhereHas('student', function ($sq) use ($search) {
                  $sq->where('first_name', 'like', "%{$search}%")
                     ->orWhere('last_name', 'like', "%{$search}%");
              });
        });
    }

    // Métodos auxiliares
    public function averageScore()
    {
        return $this->evaluations()->avg('promedio');
    }

    public function totalAttendances()
    {
        return $this->attendances()->count();
    }

    public function hasJurorAssigned($jurorId)
    {
        return $this->jurors()->where('juror_id', $jurorId)->exists();
    }

    public function isFullyEvaluated()
    {
        $jurorCount = $this->jurors()->count();
        $evaluationCount = $this->evaluations()->count();
        
        return $jurorCount > 0 && $jurorCount === $evaluationCount;
    }
}

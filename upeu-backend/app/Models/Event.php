<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'period_id',
        'name',
        'description',
        'start_date',
        'end_date',
        'location',
        'is_active',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
    ];

    // Relaciones
    public function period()
    {
        return $this->belongsTo(Period::class);
    }

    public function students()
    {
        return $this->hasMany(Student::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByPeriod($query, $periodId)
    {
        return $query->where('period_id', $periodId);
    }

    public function scopeCurrent($query)
    {
        $today = now()->toDateString();
        return $query->where('start_date', '<=', $today)
                    ->where('end_date', '>=', $today);
    }

    // Métodos auxiliares
    public function isActive()
    {
        return $this->is_active;
    }

    public function isCurrent()
    {
        $today = now();
        return $this->start_date <= $today && $this->end_date >= $today;
    }

    public function getDurationInDays()
    {
        return $this->start_date->diffInDays($this->end_date);
    }

    public function getStudentsCount()
    {
        return $this->students()->count();
    }

    public function getPonentesCount()
    {
        return $this->students()->where('type', 'ponente')->count();
    }

    public function getOyentesCount()
    {
        return $this->students()->where('type', 'oyente')->count();
    }
}

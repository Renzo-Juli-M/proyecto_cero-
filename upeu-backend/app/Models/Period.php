<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Period extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'start_date',
        'end_date',
        'is_active',
        'description',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
    ];

    // Relaciones
    public function events()
    {
        return $this->hasMany(Event::class);
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

    public function activate()
    {
        // Desactivar todos los demás periodos
        static::where('id', '!=', $this->id)->update(['is_active' => false]);

        // Activar este periodo
        $this->update(['is_active' => true]);
    }

    public function getDurationInDays()
    {
        return $this->start_date->diffInDays($this->end_date);
    }

    public function getActiveEventsCount()
    {
        return $this->events()->where('is_active', true)->count();
    }

    public function getStudentsCount()
    {
        return $this->students()->count();
    }
}

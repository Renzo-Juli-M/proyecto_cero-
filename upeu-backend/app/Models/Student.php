<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'period_id',
        'event_id',
        'dni',
        'student_code',
        'first_name',
        'last_name',
        'type',
        'sede',
        'escuela_profesional',
        'programa_estudio',
        'ciclo',
        'grupo',
        'username',
        'foto_url',
    ];

    // Relaciones
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function period()
    {
        return $this->belongsTo(Period::class);
    }

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function articles()
    {
        return $this->hasMany(Article::class);
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    // Scopes
    public function scopeByPeriod($query, $periodId)
    {
        return $query->where('period_id', $periodId);
    }

    public function scopeByEvent($query, $eventId)
    {
        return $query->where('event_id', $eventId);
    }

    public function scopePonentes($query)
    {
        return $query->where('type', 'ponente');
    }

    public function scopeOyentes($query)
    {
        return $query->where('type', 'oyente');
    }

    public function scopeBySede($query, $sede)
    {
        return $query->where('sede', $sede);
    }

    public function scopeByEscuela($query, $escuela)
    {
        return $query->where('escuela_profesional', $escuela);
    }

    public function scopeByCiclo($query, $ciclo)
    {
        return $query->where('ciclo', $ciclo);
    }

    public function scopeByGrupo($query, $grupo)
    {
        return $query->where('grupo', $grupo);
    }

    // Métodos auxiliares
    public function isPonente()
    {
        return $this->type === 'ponente';
    }

    public function isOyente()
    {
        return $this->type === 'oyente';
    }

    public function fullName()
    {
        return $this->first_name . ' ' . $this->last_name;
    }

    public function hasPhoto()
    {
        return !empty($this->foto_url);
    }

    public function getAcademicInfo()
    {
        return [
            'sede' => $this->sede,
            'escuela' => $this->escuela_profesional,
            'programa' => $this->programa_estudio,
            'ciclo' => $this->ciclo,
            'grupo' => $this->grupo,
        ];
    }
}

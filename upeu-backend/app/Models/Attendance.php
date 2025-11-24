<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'article_id',
        'student_id',
        'scanned_at',
        'qr_token',
    ];

    protected $casts = [
        'scanned_at' => 'datetime',
    ];

    // Relaciones
    public function article()
    {
        return $this->belongsTo(Article::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class);
    }
}

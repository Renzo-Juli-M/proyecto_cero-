<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Juror extends Model
{
    use HasFactory;
    protected $fillable = [
        'user_id',
        'dni',
        'username',
        'first_name',
        'last_name',
        'specialty',
    ];
    // Relaciones
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function articles()
    {
        return $this->belongsToMany(Article::class, 'article_juror')
                    ->withTimestamps();
    }
    public function evaluations()
    {
        return $this->hasMany(Evaluation::class);
    }
    // Métodos auxiliares
    public function fullName()
    {
        return $this->first_name . ' ' . $this->last_name;
    }
}

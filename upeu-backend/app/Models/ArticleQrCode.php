<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArticleQrCode extends Model
{
    protected $fillable = [
        'article_id',
        'qr_code',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Relación con Article
     */
    public function article(): BelongsTo
    {
        return $this->belongsTo(Article::class);
    }

    /**
     * Verificar si el QR está activo y no ha expirado
     */
    public function isValid(): bool
    {
        return $this->is_active && $this->expires_at > now();
    }

    /**
     * Scope para QR codes válidos
     */
    public function scopeValid($query)
    {
        return $query->where('is_active', true)
                    ->where('expires_at', '>', now());
    }

    /**
     * Scope para QR codes de un artículo específico
     */
    public function scopeForArticle($query, int $articleId)
    {
        return $query->where('article_id', $articleId);
    }
}

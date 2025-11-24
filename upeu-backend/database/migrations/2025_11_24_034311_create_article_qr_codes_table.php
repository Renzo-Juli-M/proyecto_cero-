<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('article_qr_codes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('article_id')->constrained()->onDelete('cascade');

            // JWT Token firmado (usa string para permitir índice)
            $table->text('qr_token');

            $table->timestamp('expires_at');
            $table->timestamps();

            // Índices
            $table->index('article_id');
            $table->index('expires_at');

            // Clave única válida
            $table->unique(['article_id', 'qr_token']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('article_qr_codes');
    }
};

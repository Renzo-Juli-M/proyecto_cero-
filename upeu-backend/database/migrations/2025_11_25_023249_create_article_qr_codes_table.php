<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('article_qr_codes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('article_id')->constrained('articles')->onDelete('cascade');
            $table->text('qr_token'); // Token JWT del QR (puede ser largo)
            $table->timestamp('expires_at'); // Fecha de expiración
            $table->timestamps();

            // Índices para optimizar búsquedas
            $table->index('article_id');
            $table->index(['article_id', 'expires_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('article_qr_codes');
    }
};

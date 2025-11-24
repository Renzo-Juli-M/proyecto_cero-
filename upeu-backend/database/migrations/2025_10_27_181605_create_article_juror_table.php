<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('article_juror', function (Blueprint $table) {
            $table->id();
            $table->foreignId('article_id')->constrained()->onDelete('cascade');
            $table->foreignId('juror_id')->constrained()->onDelete('cascade');
            $table->timestamps();

            // Un jurado no puede estar asignado dos veces al mismo artículo
            $table->unique(['article_id', 'juror_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('article_juror');
    }
};

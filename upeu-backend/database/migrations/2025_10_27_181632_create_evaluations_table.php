<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('article_id')->constrained()->onDelete('cascade');
            $table->foreignId('juror_id')->constrained()->onDelete('cascade');
            $table->decimal('introduccion', 5, 2)->default(0);
            $table->decimal('metodologia', 5, 2)->default(0);
            $table->decimal('desarrollo', 5, 2)->default(0);
            $table->decimal('conclusiones', 5, 2)->default(0);
            $table->decimal('presentacion', 5, 2)->default(0);
            $table->decimal('promedio', 5, 2)->default(0);
            $table->text('comentarios')->nullable();
            $table->timestamps();

            // Un jurado solo puede evaluar un artículo una vez
            $table->unique(['article_id', 'juror_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('evaluations');
    }
};

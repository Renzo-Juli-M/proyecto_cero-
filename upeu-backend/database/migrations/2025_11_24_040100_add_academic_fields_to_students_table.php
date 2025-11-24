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
        Schema::table('students', function (Blueprint $table) {
            // Foreign keys para periodo y evento
            $table->foreignId('period_id')->nullable()->after('user_id')
                ->constrained('periods')->onDelete('set null');

            $table->foreignId('event_id')->nullable()->after('period_id')
                ->constrained('events')->onDelete('set null');

            // Información académica
            $table->string('sede', 100)->nullable()->after('type');
            $table->string('escuela_profesional', 150)->nullable()->after('sede');
            $table->string('programa_estudio', 150)->nullable()->after('escuela_profesional');
            $table->string('ciclo', 20)->nullable()->after('programa_estudio');
            $table->string('grupo', 20)->nullable()->after('ciclo');

            // Username y foto
            $table->string('username', 50)->nullable()->unique()->after('grupo');
            $table->string('foto_url', 500)->nullable()->after('username');

            // Índices para búsquedas y filtros frecuentes
            $table->index('period_id');
            $table->index('event_id');
            $table->index('sede');
            $table->index('escuela_profesional');
            $table->index('ciclo');
            $table->index('grupo');
            $table->index('username');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            // Eliminar índices primero
            $table->dropIndex(['period_id']);
            $table->dropIndex(['event_id']);
            $table->dropIndex(['sede']);
            $table->dropIndex(['escuela_profesional']);
            $table->dropIndex(['ciclo']);
            $table->dropIndex(['grupo']);
            $table->dropIndex(['username']);

            // Eliminar foreign keys
            $table->dropForeign(['period_id']);
            $table->dropForeign(['event_id']);

            // Eliminar columnas
            $table->dropColumn([
                'period_id',
                'event_id',
                'sede',
                'escuela_profesional',
                'programa_estudio',
                'ciclo',
                'grupo',
                'username',
                'foto_url',
            ]);
        });
    }
};

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
        // Agregar username a users
        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 50)->unique()->nullable()->after('email');
        });

        // Agregar campos a students
        Schema::table('students', function (Blueprint $table) {
            // Relaciones
            $table->unsignedBigInteger('period_id')->nullable()->after('user_id');
            $table->unsignedBigInteger('event_id')->nullable()->after('period_id');

            // Información académica
            $table->string('sede', 100)->nullable()->after('type');
            $table->string('escuela_profesional', 150)->nullable()->after('sede');
            $table->string('programa_estudio', 150)->nullable()->after('escuela_profesional');
            $table->string('ciclo', 20)->nullable()->after('programa_estudio');
            $table->string('grupo', 20)->nullable()->after('ciclo');

            // Usuario y foto
            $table->string('username', 50)->nullable()->after('grupo');
            $table->string('foto_url', 500)->nullable()->after('username');

            // Foreign keys
            $table->foreign('period_id')->references('id')->on('periods')->onDelete('set null');
            $table->foreign('event_id')->references('id')->on('events')->onDelete('set null');

            // Índices
            $table->index('period_id');
            $table->index('event_id');
            $table->index('sede');
            $table->index('escuela_profesional');
            $table->index('ciclo');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            // Eliminar foreign keys primero
            $table->dropForeign(['period_id']);
            $table->dropForeign(['event_id']);

            // Eliminar índices
            $table->dropIndex(['period_id']);
            $table->dropIndex(['event_id']);
            $table->dropIndex(['sede']);
            $table->dropIndex(['escuela_profesional']);
            $table->dropIndex(['ciclo']);

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
                'foto_url'
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('username');
        });
    }
};

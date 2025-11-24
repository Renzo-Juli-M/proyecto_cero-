<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Student;
use Illuminate\Support\Facades\Hash;

class StudentSeeder extends Seeder
{
    public function run(): void
    {
        // Estudiante Ponente
        $userPonente = User::create([
            'email' => 'ponente@upeu.edu.pe',
            'password' => Hash::make('password'),
            'role' => 'student',
        ]);

        Student::create([
            'user_id' => $userPonente->id,
            'dni' => '12345678',
            'student_code' => '2021001',
            'first_name' => 'Juan',
            'last_name' => 'Pérez',
            'type' => 'ponente',
        ]);

        // Estudiante Oyente
        $userOyente = User::create([
            'email' => 'oyente@upeu.edu.pe',
            'password' => Hash::make('password'),
            'role' => 'student',
        ]);

        Student::create([
            'user_id' => $userOyente->id,
            'dni' => '87654321',
            'student_code' => '2021002',
            'first_name' => 'María',
            'last_name' => 'García',
            'type' => 'oyente',
        ]);

        $this->command->info('✅ Estudiantes creados');
        $this->command->info('   Ponente: DNI 12345678 / Código 2021001');
        $this->command->info('   Oyente: DNI 87654321 / Código 2021002');
    }
}

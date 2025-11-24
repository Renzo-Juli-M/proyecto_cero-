<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Juror;
use Illuminate\Support\Facades\Hash;

class JurorSeeder extends Seeder
{
    public function run(): void
    {
        $userJuror1 = User::create([
            'email' => 'juror1@upeu.edu.pe',
            'password' => Hash::make('password'),
            'role' => 'juror',
        ]);

        Juror::create([
            'user_id' => $userJuror1->id,
            'dni' => '11111111',
            'username' => 'juror1',
            'first_name' => 'Carlos',
            'last_name' => 'Rodríguez',
            'specialty' => 'Ingeniería de Software',
        ]);

        $userJuror2 = User::create([
            'email' => 'juror2@upeu.edu.pe',
            'password' => Hash::make('password'),
            'role' => 'juror',
        ]);

        Juror::create([
            'user_id' => $userJuror2->id,
            'dni' => '22222222',
            'username' => 'juror2',
            'first_name' => 'Ana',
            'last_name' => 'Martínez',
            'specialty' => 'Inteligencia Artificial',
        ]);

        $this->command->info('✅ Jurados creados');
        $this->command->info('   Jurado 1: usuario juror1 / DNI 11111111');
        $this->command->info('   Jurado 2: usuario juror2 / DNI 22222222');
    }
}
